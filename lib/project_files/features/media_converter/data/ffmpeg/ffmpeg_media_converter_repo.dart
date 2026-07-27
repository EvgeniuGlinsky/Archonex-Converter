import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/log.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:flutter/services.dart';

import 'package:archonex/project_files/features/converter_shared/data/ffmpeg/ffmpeg_error_classifier.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex/project_files/features/media_converter/data/ffmpeg/ffmpeg_command_builder.dart';
import 'package:archonex/project_files/features/media_converter/data/ffmpeg/ffmpeg_duration_parser.dart';
import 'package:archonex/project_files/features/media_converter/domain/media_converter_repo.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_job.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_update.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';

/// Real conversion, backed by the FFmpeg binaries bundled with
/// `ffmpeg_kit_flutter_new`.
///
/// The plugin ships native libraries for Android, iOS, macOS and Windows only.
/// Linux gets no engine, which [isSupported] reports up front; should a call
/// slip through anyway, the resulting `MissingPluginException` is mapped to
/// [ConversionUnsupportedFailure] rather than a generic error.
class FfmpegMediaConverterRepo implements MediaConverterRepo {
  const FfmpegMediaConverterRepo();

  static const String _tempDirectoryPrefix = 'archonex_convert_';

  @override
  bool get isSupported => !Platform.isLinux;

  @override
  ConversionJob convert({
    required SourceFile source,
    required MediaFormat target,
    required ConversionSettings settings,
  }) {
    return _FfmpegConversionJob(
      source: source,
      target: target,
      settings: settings,
      tempDirectoryPrefix: _tempDirectoryPrefix,
    );
  }

  @override
  Future<void> discard(ConvertedFile file) async {
    // The output lives alone in a temp directory created per conversion, so
    // removing the parent takes the file and the directory in one go.
    final Directory directory = File(file.path).parent;

    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } on FileSystemException {
      // A leftover temp directory is not worth surfacing to the user; the OS
      // reclaims it eventually.
    }
  }
}

/// One FFmpeg session, exposed as a progress stream that can be cancelled.
class _FfmpegConversionJob implements ConversionJob {
  _FfmpegConversionJob({
    required SourceFile source,
    required MediaFormat target,
    required ConversionSettings settings,
    required String tempDirectoryPrefix,
  })  : _source = source,
        _target = target,
        _settings = settings,
        _tempDirectoryPrefix = tempDirectoryPrefix {
    _controller = StreamController<ConversionUpdate>(onListen: _start);
  }

  final SourceFile _source;
  final MediaFormat _target;
  final ConversionSettings _settings;
  final String _tempDirectoryPrefix;

  late final StreamController<ConversionUpdate> _controller;

  final FfmpegDurationParser _durationParser = FfmpegDurationParser();

  /// A stream FFmpeg cannot find here means the source has no sound to pull
  /// out, which is the one conversion the target grid cannot rule out up front.
  final FfmpegErrorClassifier _errorClassifier = FfmpegErrorClassifier(
    missingStreamFailure: const NoAudioTrackFailure(),
  );

  Directory? _tempDirectory;
  int? _sessionId;
  bool _isCancelling = false;

  @override
  Stream<ConversionUpdate> get updates => _controller.stream;

  @override
  Future<void> cancel() async {
    final int? sessionId = _sessionId;
    _isCancelling = true;

    if (sessionId == null) {
      // Cancelled before FFmpeg started: nothing native to stop.
      await _finishWith(const ConversionCancelledFailure());

      return;
    }

    await FFmpegKit.cancel(sessionId);
  }

  Future<void> _start() async {
    final String? inputPath = _source.path;
    if (inputPath == null) {
      // No local path means no engine can read it — only reachable on web.
      await _finishWith(const ConversionUnsupportedFailure());

      return;
    }

    try {
      final Directory directory =
          await Directory.systemTemp.createTemp(_tempDirectoryPrefix);
      _tempDirectory = directory;

      final String outputName = '${_source.baseName}.${_target.extension}';
      final String outputPath = '${directory.path}${Platform.pathSeparator}'
          '$outputName';

      final FFmpegSession session = await FFmpegKit.executeWithArgumentsAsync(
        FfmpegCommandBuilder.build(
          inputPath: inputPath,
          outputPath: outputPath,
          target: _target,
          settings: _settings,
        ),
        (session) => _onSessionComplete(session, outputPath, outputName),
        _onLog,
        _onStatistics,
      );

      _sessionId = session.getSessionId();

      // A cancel that landed while the session was starting up.
      if (_isCancelling) {
        await FFmpegKit.cancel(_sessionId);
      }
    } on MissingPluginException {
      await _finishWith(const ConversionUnsupportedFailure());
    } on Exception {
      await _finishWith(const ConversionEngineFailure());
    }
  }

  /// FFmpeg reports the input length in its own header, well before the first
  /// statistics tick, so progress can be a real fraction without a second
  /// FFprobe pass. Inputs that report no duration leave the parser empty and
  /// the bar stays indeterminate. The same fragments feed the classifier,
  /// which is what turns a bare exit code into an explainable failure.
  void _onLog(Log log) {
    final String message = log.getMessage();
    _durationParser.add(message);
    _errorClassifier.add(message);
  }

  void _onStatistics(Statistics statistics) {
    if (_controller.isClosed) {
      return;
    }

    final int? totalMs = _durationParser.durationMs;
    final double? value = totalMs == null
        ? null
        : (statistics.getTime() / totalMs).clamp(0.0, 1.0);

    _controller.add(ConversionProgress(value));
  }

  Future<void> _onSessionComplete(
    FFmpegSession session,
    String outputPath,
    String outputName,
  ) async {
    if (_controller.isClosed) {
      return;
    }

    final ReturnCode? returnCode = await session.getReturnCode();

    if (ReturnCode.isCancel(returnCode) || _isCancelling) {
      await _finishWith(const ConversionCancelledFailure());

      return;
    }

    if (!ReturnCode.isSuccess(returnCode)) {
      await _finishWith(
        _errorClassifier.classify() ?? const ConversionEngineFailure(),
      );

      return;
    }

    final File output = File(outputPath);
    if (!await output.exists()) {
      await _finishWith(const ConversionEngineFailure());

      return;
    }

    _controller
      ..add(
        ConversionCompleted(
          ConvertedFile(
            name: outputName,
            path: outputPath,
            sizeInBytes: await output.length(),
          ),
        ),
      )
      ..close();
  }

  /// Ends the stream with [failure] and takes the temp directory with it —
  /// nothing downstream can reach a half written output.
  Future<void> _finishWith(ConversionFailure failure) async {
    await _deleteTempDirectory();

    if (_controller.isClosed) {
      return;
    }

    _controller.addError(failure);
    await _controller.close();
  }

  Future<void> _deleteTempDirectory() async {
    final Directory? directory = _tempDirectory;
    _tempDirectory = null;

    if (directory == null) {
      return;
    }

    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } on FileSystemException {
      // Best effort — see FfmpegMediaConverterRepo.discard.
    }
  }
}
