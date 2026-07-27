import 'package:archonex/project_files/features/converter_shared/data/ffmpeg/ffmpeg_filters.dart';
import 'package:archonex/project_files/features/media_converter/data/ffmpeg/ffmpeg_codecs.dart';
import 'package:archonex/project_files/features/media_converter/data/ffmpeg/ffmpeg_target_spec.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_settings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';

/// Builds the FFmpeg argument list for a conversion.
///
/// Arguments are returned as a list rather than a command string: paths on
/// Windows and macOS routinely contain spaces, and a list sidesteps quoting.
///
/// Nothing here knows about individual formats. Which encoders to reach for
/// comes from [FfmpegTargetSpec], and how to say "quality 60" to each of them
/// comes from [FfmpegVideoCodec] — this file only assembles the pieces.
class FfmpegCommandBuilder {
  const FfmpegCommandBuilder._();

  static const String evenDimensionsFilter = FfmpegFilters.evenDimensions;

  static const String paletteGraph = FfmpegFilters.paletteGraph;

  static const String _scaleFlags = FfmpegFilters.scaleFlags;

  static List<String> build({
    required String inputPath,
    required String outputPath,
    required MediaFormat target,
    required ConversionSettings settings,
  }) {
    final FfmpegTargetSpec? spec = FfmpegTargetSpec.of(target);

    if (spec == null) {
      throw ArgumentError.value(
        target,
        'target',
        'no encoder ships for this format',
      );
    }

    final String? filters = _filterGraph(target, spec, settings);

    return <String>[
      // Never ask before overwriting: the output lives in a temp directory the
      // app just made, and a prompt would hang a headless session forever.
      '-y',
      '-i',
      inputPath,
      ..._streamSelection(spec, settings),
      if (filters != null) ...<String>['-vf', filters],
      ..._videoArguments(spec, settings),
      ..._audioArguments(spec, settings),
      ..._containerArguments(spec),
      outputPath,
    ];
  }

  /// Which of the input's streams the output is built from.
  ///
  /// Left to itself FFmpeg also carries subtitles and data streams across, and
  /// an MKV subtitle track is the usual reason an MKV → MP4 run dies. Naming
  /// the streams also turns "this video has no sound" into FFmpeg's
  /// `matches no streams` message, which the error classifier can explain,
  /// rather than an empty output file.
  static List<String> _streamSelection(
    FfmpegTargetSpec spec,
    ConversionSettings settings,
  ) {
    if (spec.isAudioOnly) {
      return const <String>['-vn', '-map', '0:a:0'];
    }

    final bool keepsAudio = spec.audioCodec != null && settings.keepAudio;

    return <String>[
      '-map',
      '0:v:0',
      // The trailing `?` makes the audio track optional: a silent video is a
      // perfectly good input, it just has nothing to map.
      if (keepsAudio) ...<String>['-map', '0:a:0?'],
      '-sn',
      '-dn',
    ];
  }

  static String? _filterGraph(
    MediaFormat target,
    FfmpegTargetSpec spec,
    ConversionSettings settings,
  ) {
    if (spec.isAudioOnly) {
      return null;
    }

    final List<String> chain = <String>[];

    final int? fps = settings.effectiveFrameRate(target);
    if (fps != null) {
      chain.add('fps=$fps');
    }

    final String? scale = _scaleFilter(target, settings);
    if (scale != null) {
      chain.add(scale);
    }

    if (spec.usesPalette) {
      chain.add(paletteGraph);
    } else if (spec.videoCodec?.needsEvenDimensions ?? false) {
      chain.add(evenDimensionsFilter);
    }

    return chain.isEmpty ? null : chain.join(',');
  }

  /// Animations are sized by width, because that is the number a preset speaks
  /// in; everything else is capped by height, because that is what resolutions
  /// are named after.
  static String? _scaleFilter(MediaFormat target, ConversionSettings settings) {
    if (target.isAnimation) {
      final int? width = settings.effectiveAnimationWidth;
      if (width != null) {
        return 'scale=$width:-1:$_scaleFlags';
      }

      final int? height = settings.effectiveMaxHeight;

      return height == null ? null : 'scale=-1:$height:$_scaleFlags';
    }

    final int? height = settings.effectiveMaxHeight;
    if (height == null) {
      return null;
    }

    // `min` leaves a source shorter than the cap alone — upscaling would only
    // add bytes. The comma inside it is escaped or the filter parser reads it
    // as the start of the next filter.
    return 'scale=-2:min(ih\\,$height)';
  }

  static List<String> _videoArguments(
    FfmpegTargetSpec spec,
    ConversionSettings settings,
  ) {
    if (spec.isAudioOnly) {
      // The video track is already dropped by the stream selection.
      return const <String>[];
    }

    final FfmpegVideoCodec? codec = spec.videoCodec;
    if (codec == null) {
      // GIF: the filter graph is the encoder.
      return const <String>[];
    }

    final String? pixelFormat = codec.pixelFormat;

    return <String>[
      '-c:v',
      codec.name,
      codec.qualityFlag,
      '${codec.qualityArgument(settings.effectiveVideoQuality)}',
      ...codec.extraArguments,
      if (pixelFormat != null) ...<String>['-pix_fmt', pixelFormat],
    ];
  }

  static List<String> _audioArguments(
    FfmpegTargetSpec spec,
    ConversionSettings settings,
  ) {
    final FfmpegAudioCodec? codec = spec.audioCodec;

    // No audio in the container at all, or the user asked for silence. An
    // audio only target ignores that switch: silence is not a conversion.
    if (codec == null || (!spec.isAudioOnly && !settings.keepAudio)) {
      return const <String>['-an'];
    }

    return <String>[
      '-c:a',
      codec.name,
      if (codec.usesBitrate) ...<String>[
        '-b:a',
        '${settings.effectiveAudioBitrateKbps}k',
      ],
    ];
  }

  static List<String> _containerArguments(FfmpegTargetSpec spec) {
    final String? forcedFormat = spec.forcedFormat;

    return <String>[
      if (spec.loopsForever) ...<String>['-loop', '0'],
      if (spec.faststart) ...<String>['-movflags', '+faststart'],
      ...spec.containerArguments,
      if (forcedFormat != null) ...<String>['-f', forcedFormat],
    ];
  }
}
