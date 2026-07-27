import 'package:archonex/project_files/features/converter_shared/data/ffmpeg/ffmpeg_filters.dart';
import 'package:archonex/project_files/features/image_converter/data/ffmpeg/ffmpeg_image_codecs.dart';
import 'package:archonex/project_files/features/image_converter/data/ffmpeg/ffmpeg_image_target_spec.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_conversion_settings.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_format.dart';

/// Builds the FFmpeg argument list for one photo.
///
/// Arguments are returned as a list rather than a command string: paths on
/// Windows and macOS routinely contain spaces, and a list sidesteps quoting.
///
/// Nothing here knows about individual formats. Which encoder to reach for
/// comes from [FfmpegImageTargetSpec], and how to say "quality 80" to it comes
/// from [FfmpegImageCodec] — this file only assembles the pieces.
class FfmpegImageCommandBuilder {
  const FfmpegImageCommandBuilder._();

  /// Exactly one frame comes out, whatever went in.
  ///
  /// Sources are not always single frames — an animated GIF or a HEIC burst
  /// holds several — and without this FFmpeg writes a numbered sequence into
  /// a path that expects one file.
  static const List<String> singleFrameArguments = <String>['-frames:v', '1'];

  /// Drops EXIF, including the GPS tag.
  static const List<String> stripMetadataArguments = <String>[
    '-map_metadata',
    '-1',
  ];

  /// Label the flattening graph writes its result to.
  static const String _flattenedLabel = 'out';

  static List<String> build({
    required String inputPath,
    required String outputPath,
    required ImageFormat source,
    required ImageFormat target,
    required ImageConversionSettings settings,
  }) {
    final FfmpegImageTargetSpec? spec = FfmpegImageTargetSpec.of(target);

    if (spec == null) {
      throw ArgumentError.value(
        target,
        'target',
        'no encoder ships for this format',
      );
    }

    final bool flattens = target.needsBackgroundFrom(source);
    final List<String> chain = _filterChain(spec, settings);

    return <String>[
      // Never ask before overwriting: the output lives in a temp directory the
      // app just made, and a prompt would hang a headless session forever.
      '-y',
      '-i',
      inputPath,
      if (flattens) ..._backgroundInput(settings),
      if (flattens)
        ..._flattenArguments(chain)
      else
        ..._plainArguments(chain),
      ...singleFrameArguments,
      if (!settings.keepMetadata) ...stripMetadataArguments,
      ..._encoderArguments(spec, settings),
      ...spec.containerArguments,
      outputPath,
    ];
  }

  /// The filters that apply to the picture itself, in the order they run.
  static List<String> _filterChain(
    FfmpegImageTargetSpec spec,
    ImageConversionSettings settings,
  ) {
    final List<String> chain = <String>[];

    final String? scale = _scaleFilter(settings);
    if (scale != null) {
      chain.add(scale);
    }

    if (spec.usesPalette) {
      chain.add(FfmpegFilters.paletteGraph);
    } else if (spec.codec?.needsEvenDimensions ?? false) {
      chain.add(FfmpegFilters.evenDimensions);
    }

    return chain;
  }

  /// Caps the longer side without ever enlarging a picture.
  ///
  /// A batch of photos mixes portrait and landscape, so capping the height
  /// alone would shrink them by different amounts. The box is the source size
  /// clipped to the cap, and `decrease` fits the picture inside it while
  /// keeping the aspect ratio — which for a source already under the cap means
  /// leaving it exactly as it is.
  ///
  /// The commas inside `min()` are escaped or the filter parser reads them as
  /// the start of the next filter.
  static String? _scaleFilter(ImageConversionSettings settings) {
    final int? maxSide = settings.effectiveMaxSide;

    if (maxSide == null) {
      return null;
    }

    return 'scale=min(iw\\,$maxSide):min(ih\\,$maxSide)'
        ':force_original_aspect_ratio=decrease'
        ':${FfmpegFilters.scaleFlags}';
  }

  static List<String> _plainArguments(List<String> chain) => <String>[
        '-map',
        '0:v:0',
        if (chain.isNotEmpty) ...<String>['-vf', chain.join(',')],
      ];

  /// A solid colour source, sized later by `scale2ref`.
  ///
  /// It is infinite, which is what `-frames:v 1` and `shortest` below take care
  /// of; a fixed tiny size keeps it cheap to generate.
  static List<String> _backgroundInput(ImageConversionSettings settings) =>
      <String>[
        '-f',
        'lavfi',
        '-i',
        'color=c=${settings.background.ffmpegColor}:s=2x2',
      ];

  /// Composites the picture over a solid background before anything else sees
  /// it.
  ///
  /// Left alone, FFmpeg drops the alpha channel by compositing over black,
  /// which turns a transparent logo or screenshot into a dark rectangle — the
  /// single most surprising thing a PNG to JPG conversion can do. `scale2ref`
  /// stretches the colour source to the picture's size, so no dimension has to
  /// be known up front.
  static List<String> _flattenArguments(List<String> chain) {
    final String scaled = chain.isEmpty ? 'null' : chain.join(',');

    return <String>[
      '-filter_complex',
      '[0:v]$scaled[img];'
          '[1:v][img]scale2ref[bg][fg];'
          '[bg][fg]overlay=shortest=1:format=auto[$_flattenedLabel]',
      '-map',
      '[$_flattenedLabel]',
    ];
  }

  static List<String> _encoderArguments(
    FfmpegImageTargetSpec spec,
    ImageConversionSettings settings,
  ) {
    final FfmpegImageCodec? codec = spec.codec;

    if (codec == null) {
      // GIF: the filter graph is the encoder.
      return const <String>[];
    }

    final String? pixelFormat = codec.pixelFormat;

    return <String>[
      '-c:v',
      codec.name,
      ...codec.qualityArguments(settings.effectiveQuality),
      ...codec.extraArguments,
      if (pixelFormat != null) ...<String>['-pix_fmt', pixelFormat],
    ];
  }
}
