import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex/project_files/features/media_converter/data/use_cases/convert_media_use_case.dart';
import 'package:archonex/project_files/features/media_converter/data/use_cases/discard_converted_file_use_case.dart';
import 'package:archonex/project_files/features/media_converter/data/use_cases/get_converter_availability_use_case.dart';
import 'package:archonex/project_files/features/media_converter/data/use_cases/pick_source_file_use_case.dart';
import 'package:archonex/project_files/features/media_converter/data/use_cases/save_converted_file_use_case.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/audio_bitrate_option.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_job.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_quality.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_update.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/frame_rate_option.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/source_file.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/video_resolution.dart';

part 'media_converter_event.dart';
part 'media_converter_state.dart';

/// Drives the converter screen: picking, choosing a target, tuning quality,
/// converting, cancelling and saving.
///
/// Every failure lands in `state.failure`, which is the screen's only error
/// channel. Cancelling a system dialog is not a failure, it is a no-op.
///
/// Results live in temporary files, so any result the bloc drops is handed to
/// [DiscardConvertedFileUseCase] first — otherwise every conversion would leak
/// a directory. Anything that changes *what would be produced* drops the
/// current result too: leaving an MP4 on screen after the target moved to WEBM
/// would offer the user a download that no longer matches the settings above
/// it.
class MediaConverterBloc
    extends Bloc<MediaConverterEvent, MediaConverterState> {
  MediaConverterBloc({
    required GetConverterAvailabilityUseCase getConverterAvailability,
    required PickSourceFileUseCase pickSourceFile,
    required ConvertMediaUseCase convertMedia,
    required SaveConvertedFileUseCase saveConvertedFile,
    required DiscardConvertedFileUseCase discardConvertedFile,
  })  : _getConverterAvailability = getConverterAvailability,
        _pickSourceFile = pickSourceFile,
        _convertMedia = convertMedia,
        _saveConvertedFile = saveConvertedFile,
        _discardConvertedFile = discardConvertedFile,
        super(const MediaConverterState()) {
    on<MediaConverterStarted>(_onStarted, transformer: restartable());
    // droppable: the OS only shows one dialog, so extra taps must not queue up.
    on<SourceFilePickRequested>(_onPickRequested, transformer: droppable());
    on<SourceFileCleared>(_onSourceCleared, transformer: sequential());
    // sequential: every settings handler awaits a real file delete, and the
    // last tap has to be the one that wins.
    on<TargetFormatSelected>(_onTargetSelected, transformer: sequential());
    on<QualityPresetChanged>(_onQualityChanged, transformer: sequential());
    on<AdvancedPanelToggled>(_onAdvancedToggled, transformer: sequential());
    on<ResolutionChanged>(_onResolutionChanged, transformer: sequential());
    on<FrameRateChanged>(_onFrameRateChanged, transformer: sequential());
    on<VideoQualityChanged>(_onVideoQualityChanged, transformer: sequential());
    on<AudioBitrateChanged>(_onAudioBitrateChanged, transformer: sequential());
    on<KeepAudioToggled>(_onKeepAudioToggled, transformer: sequential());
    on<AdvancedSettingsReset>(_onAdvancedReset, transformer: sequential());
    // droppable: one conversion at a time; taps during a run are ignored.
    on<ConversionRequested>(_onConversionRequested, transformer: droppable());
    on<ConversionCancelled>(_onConversionCancelled, transformer: sequential());
    on<ConvertedFileSaveRequested>(_onSaveRequested, transformer: droppable());
  }

  final GetConverterAvailabilityUseCase _getConverterAvailability;
  final PickSourceFileUseCase _pickSourceFile;
  final ConvertMediaUseCase _convertMedia;
  final SaveConvertedFileUseCase _saveConvertedFile;
  final DiscardConvertedFileUseCase _discardConvertedFile;

  ConversionJob? _activeJob;

  @override
  Future<void> close() {
    _activeJob?.cancel();
    _activeJob = null;

    final ConvertedFile? result = state.result;
    if (result != null) {
      _discardConvertedFile(result);
    }

    return super.close();
  }

  Future<void> _onStarted(
    MediaConverterStarted event,
    Emitter<MediaConverterState> emit,
  ) async {
    await _dropResult();

    emit(MediaConverterState(isSupported: _getConverterAvailability()));
  }

  Future<void> _onPickRequested(
    SourceFilePickRequested event,
    Emitter<MediaConverterState> emit,
  ) async {
    await _dropResult();

    emit(
      state.copyWith(
        status: MediaConverterStatus.picking,
        clearFailure: true,
        clearResult: true,
        clearProgress: true,
        clearSavedLocation: true,
      ),
    );

    try {
      final SourceFile? file = await _pickSourceFile();

      if (file == null) {
        // Dialog closed without a choice — keep whatever was there before.
        emit(
          state.copyWith(
            status: state.source == null
                ? MediaConverterStatus.idle
                : MediaConverterStatus.ready,
          ),
        );

        return;
      }

      emit(_withSource(file));
    } on ConversionFailure catch (failure) {
      emit(_withFailure(failure, clearSource: true));
    }
  }

  /// A new file keeps the chosen target when that target is still reachable —
  /// re-picking MP4 after swapping one MOV for another would be busywork — and
  /// drops it otherwise, along with the settings that were tuned for it.
  MediaConverterState _withSource(SourceFile file) {
    final MediaFormat? target = state.target;
    final bool keepsTarget =
        target != null && (file.format?.targets.contains(target) ?? false);

    return state.copyWith(
      status: MediaConverterStatus.ready,
      source: file,
      clearTarget: !keepsTarget,
      settings: keepsTarget ? state.settings : const ConversionSettings(),
    );
  }

  Future<void> _onSourceCleared(
    SourceFileCleared event,
    Emitter<MediaConverterState> emit,
  ) async {
    await _dropResult();

    emit(
      MediaConverterState(
        isSupported: state.isSupported,
        isAdvancedExpanded: state.isAdvancedExpanded,
      ),
    );
  }

  Future<void> _onTargetSelected(
    TargetFormatSelected event,
    Emitter<MediaConverterState> emit,
  ) async {
    if (!state.canEditSettings ||
        !state.availableTargets.contains(event.format) ||
        event.format == state.target) {
      return;
    }

    await _dropResult();

    emit(
      _asReady(
        state.copyWith(
          target: event.format,
          settings: state.settings.prunedFor(event.format),
        ),
      ),
    );
  }

  Future<void> _onQualityChanged(
    QualityPresetChanged event,
    Emitter<MediaConverterState> emit,
  ) {
    // The preset is the baseline the advanced fields display, so moving it has
    // to move them: overrides left in place would make High and Compact look
    // identical.
    return _applySettings(
      emit,
      ConversionSettings(quality: event.quality),
      isForced: event.quality != state.settings.quality,
    );
  }

  Future<void> _onAdvancedReset(
    AdvancedSettingsReset event,
    Emitter<MediaConverterState> emit,
  ) =>
      _applySettings(emit, state.settings.resetToPreset());

  Future<void> _onResolutionChanged(
    ResolutionChanged event,
    Emitter<MediaConverterState> emit,
  ) =>
      _applySettings(
        emit,
        state.settings.copyWith(resolution: event.resolution),
      );

  Future<void> _onFrameRateChanged(
    FrameRateChanged event,
    Emitter<MediaConverterState> emit,
  ) =>
      _applySettings(emit, state.settings.copyWith(frameRate: event.frameRate));

  Future<void> _onVideoQualityChanged(
    VideoQualityChanged event,
    Emitter<MediaConverterState> emit,
  ) =>
      _applySettings(
        emit,
        state.settings.copyWith(
          videoQuality: event.videoQuality.clamp(
            ConversionQuality.minVideoQuality,
            ConversionQuality.maxVideoQuality,
          ),
        ),
      );

  Future<void> _onAudioBitrateChanged(
    AudioBitrateChanged event,
    Emitter<MediaConverterState> emit,
  ) =>
      _applySettings(
        emit,
        state.settings.copyWith(audioBitrate: event.audioBitrate),
      );

  Future<void> _onKeepAudioToggled(
    KeepAudioToggled event,
    Emitter<MediaConverterState> emit,
  ) =>
      _applySettings(emit, state.settings.copyWith(keepAudio: event.keepAudio));

  /// Stores [settings] and throws away a result that no longer matches them.
  ///
  /// [isForced] exists for the preset, which must still clear the overrides
  /// when the preset itself did not move. Everything else relies on the
  /// equality check, which is what stops a slider drag from firing one temp
  /// file delete per pixel.
  Future<void> _applySettings(
    Emitter<MediaConverterState> emit,
    ConversionSettings settings, {
    bool isForced = false,
  }) async {
    if (!state.canEditSettings) {
      return;
    }

    final MediaFormat? target = state.target;
    final ConversionSettings next =
        target == null ? settings : settings.prunedFor(target);

    if (!isForced && next == state.settings) {
      return;
    }

    await _dropResult();

    emit(_asReady(state.copyWith(settings: next)));
  }

  void _onAdvancedToggled(
    AdvancedPanelToggled event,
    Emitter<MediaConverterState> emit,
  ) {
    emit(state.copyWith(isAdvancedExpanded: !state.isAdvancedExpanded));
  }

  Future<void> _onConversionRequested(
    ConversionRequested event,
    Emitter<MediaConverterState> emit,
  ) async {
    final SourceFile? source = state.source;
    final MediaFormat? target = state.target;
    if (source == null || target == null) {
      return;
    }

    await _dropResult();

    final ConversionJob job;

    try {
      job = _convertMedia(
        source: source,
        target: target,
        settings: state.settings,
      );
    } on ConversionFailure catch (failure) {
      emit(_withFailure(failure));

      return;
    }

    _activeJob = job;

    emit(
      state.copyWith(
        status: MediaConverterStatus.converting,
        clearProgress: true,
        clearResult: true,
        clearFailure: true,
        clearSavedLocation: true,
      ),
    );

    await emit.forEach<ConversionUpdate>(
      job.updates,
      onData: (update) => switch (update) {
        ConversionProgress(:final double? value) => value == null
            ? state.copyWith(clearProgress: true)
            : state.copyWith(progress: value),
        ConversionCompleted(:final ConvertedFile file) => state.copyWith(
            status: MediaConverterStatus.converted,
            progress: 1,
            result: file,
          ),
      },
      onError: (error, _) => _withFailure(
        error is ConversionFailure ? error : const ConversionEngineFailure(),
      ),
    );

    _activeJob = null;
  }

  Future<void> _onConversionCancelled(
    ConversionCancelled event,
    Emitter<MediaConverterState> emit,
  ) async {
    await _activeJob?.cancel();
  }

  Future<void> _onSaveRequested(
    ConvertedFileSaveRequested event,
    Emitter<MediaConverterState> emit,
  ) async {
    final ConvertedFile? result = state.result;
    if (result == null) {
      return;
    }

    emit(
      state.copyWith(
        status: MediaConverterStatus.saving,
        clearFailure: true,
        clearSavedLocation: true,
      ),
    );

    try {
      final SaveResult saveResult = await _saveConvertedFile(result);

      emit(
        switch (saveResult.outcome) {
          SaveOutcome.cancelled =>
            state.copyWith(status: MediaConverterStatus.converted),
          SaveOutcome.downloadStarted =>
            state.copyWith(status: MediaConverterStatus.saved),
          SaveOutcome.savedToLocation => state.copyWith(
              status: MediaConverterStatus.saved,
              savedLocation: saveResult.location,
            ),
        },
      );
    } on ConversionFailure catch (failure) {
      emit(
        state.copyWith(
          status: MediaConverterStatus.converted,
          failure: failure,
        ),
      );
    }
  }

  /// Parks a settings change back on the "file chosen, nothing produced yet"
  /// step, whatever the screen was showing before.
  MediaConverterState _asReady(MediaConverterState next) => next.copyWith(
        status: MediaConverterStatus.ready,
        clearResult: true,
        clearProgress: true,
        clearFailure: true,
        clearSavedLocation: true,
      );

  /// Deletes the temporary file behind the current result, if any.
  Future<void> _dropResult() async {
    final ConvertedFile? result = state.result;
    if (result == null) {
      return;
    }

    await _discardConvertedFile(result);
  }

  /// Failures always park the screen in a state the user can act from again.
  MediaConverterState _withFailure(
    ConversionFailure failure, {
    bool clearSource = false,
  }) {
    final bool keepsSource = !clearSource && state.source != null;

    return state.copyWith(
      status:
          keepsSource ? MediaConverterStatus.ready : MediaConverterStatus.idle,
      failure: failure,
      clearProgress: true,
      clearSource: clearSource,
      clearTarget: clearSource,
      clearResult: true,
    );
  }
}
