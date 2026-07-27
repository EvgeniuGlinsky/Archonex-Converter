import 'package:archonex/project_files/features/image_converter/data/ffmpeg/ffmpeg_image_codecs.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_format.dart';

/// How one target format is produced: which encoder, and which muxer quirks
/// have to be humoured.
///
/// Keeping this as data rather than as branches in the command builder is what
/// stops the builder from growing a limb per format.
class FfmpegImageTargetSpec {
  const FfmpegImageTargetSpec({
    this.codec,
    this.usesPalette = false,
    this.containerArguments = const <String>[],
  });

  /// Encoder for the picture, or `null` for GIF, which is driven entirely by
  /// its filter graph.
  final FfmpegImageCodec? codec;

  /// GIF: the palette is generated from the picture and applied in one graph.
  final bool usesPalette;

  /// Muxer level flags that are neither codec nor filter.
  final List<String> containerArguments;

  /// The spec for [format], or `null` where the bundled FFmpeg has no encoder
  /// for it — those formats can be read but never written, which
  /// `ImageFormat.canEncode` already says out loud.
  static FfmpegImageTargetSpec? of(ImageFormat format) => switch (format) {
        ImageFormat.jpg => const FfmpegImageTargetSpec(
            codec: FfmpegImageCodec.mjpeg,
            containerArguments: _singleImage,
          ),
        ImageFormat.png => const FfmpegImageTargetSpec(
            codec: FfmpegImageCodec.png,
            containerArguments: _singleImage,
          ),
        ImageFormat.tiff => const FfmpegImageTargetSpec(
            codec: FfmpegImageCodec.tiff,
            containerArguments: _singleImage,
          ),
        ImageFormat.bmp => const FfmpegImageTargetSpec(
            codec: FfmpegImageCodec.bmp,
            containerArguments: _singleImage,
          ),
        ImageFormat.tga => const FfmpegImageTargetSpec(
            codec: FfmpegImageCodec.targa,
            containerArguments: _singleImage,
          ),
        // The WebP and GIF muxers are not the image2 one, so they do not know
        // `-update` and would reject it as an unknown option.
        ImageFormat.webp =>
          const FfmpegImageTargetSpec(codec: FfmpegImageCodec.webp),
        ImageFormat.gif => const FfmpegImageTargetSpec(usesPalette: true),
        // Read only: no encoder ships for these.
        ImageFormat.ico || ImageFormat.heic || ImageFormat.avif => null,
      };

  /// Tells the image2 muxer that one file is being overwritten rather than a
  /// numbered sequence being written. Without it FFmpeg expects a `%d` in the
  /// name and warns on every run.
  static const List<String> _singleImage = <String>['-update', '1'];
}
