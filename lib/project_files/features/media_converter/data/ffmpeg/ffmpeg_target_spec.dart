import 'package:archonex_converter/project_files/features/media_converter/data/ffmpeg/ffmpeg_codecs.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/models/media_format.dart';

/// How one target format is produced: which encoders, and which container
/// quirks have to be humoured.
///
/// Keeping this as data rather than as branches in the command builder is what
/// stops the builder from growing a limb per format.
class FfmpegTargetSpec {
  const FfmpegTargetSpec({
    this.videoCodec,
    this.audioCodec,
    this.usesPalette = false,
    this.loopsForever = false,
    this.faststart = false,
    this.forcedFormat,
    this.containerArguments = const <String>[],
  });

  /// Encoder for the picture, or `null` for an audio only target and for GIF,
  /// which is driven entirely by its filter graph.
  final FfmpegVideoCodec? videoCodec;

  /// Encoder for the sound, or `null` for a target that carries none.
  final FfmpegAudioCodec? audioCodec;

  /// GIF: the palette is generated from the clip and applied in one graph.
  final bool usesPalette;

  /// Animations play forever rather than once.
  final bool loopsForever;

  /// Move the MP4 index to the front so the file starts playing before it has
  /// finished downloading.
  final bool faststart;

  /// Muxer to force with `-f`, overriding the one FFmpeg picks from the
  /// extension. Only `.m4v` needs it, and it needs it badly — see below.
  final String? forcedFormat;

  /// Muxer level flags that are neither codec nor filter, e.g. `-vtag`.
  final List<String> containerArguments;

  /// `true` when nothing but sound comes out, so the video track is dropped.
  bool get isAudioOnly => videoCodec == null && !usesPalette;

  /// The spec for [format], or `null` where the bundled FFmpeg has no encoder
  /// for it — those formats can be read but never written, which
  /// `MediaFormat.canEncode` already says out loud.
  static FfmpegTargetSpec? of(MediaFormat format) => switch (format) {
        MediaFormat.mp4 || MediaFormat.mov => _h264(faststart: true),

        // `.m4v` resolves to FFmpeg's *raw MPEG-4 video* muxer, which writes a
        // bare elementary stream and drops the audio without saying a word.
        // The real MP4 muxer has to be named explicitly.
        MediaFormat.m4v => _h264(faststart: true, forcedFormat: 'mp4'),

        MediaFormat.mkv || MediaFormat.ts || MediaFormat.flv => _h264(),
        MediaFormat.webm => const FfmpegTargetSpec(
            videoCodec: FfmpegVideoCodec.vp9,
            audioCodec: FfmpegAudioCodec.opus,
          ),
        // Legacy AVI players identify the stream by its FourCC rather than by
        // the codec id, and refuse anything they read as plain `FMP4`.
        MediaFormat.avi => const FfmpegTargetSpec(
            videoCodec: FfmpegVideoCodec.mpeg4,
            audioCodec: FfmpegAudioCodec.mp3,
            containerArguments: <String>['-vtag', 'xvid'],
          ),
        MediaFormat.ogv => const FfmpegTargetSpec(
            videoCodec: FfmpegVideoCodec.theora,
            audioCodec: FfmpegAudioCodec.vorbis,
          ),
        MediaFormat.gif => const FfmpegTargetSpec(
            usesPalette: true,
            loopsForever: true,
          ),
        // The filter graph has already set the frame rate; without passthrough
        // the muxer duplicates frames back up to the source rate.
        MediaFormat.webp => const FfmpegTargetSpec(
            videoCodec: FfmpegVideoCodec.webp,
            loopsForever: true,
            containerArguments: <String>['-fps_mode', 'passthrough'],
          ),
        MediaFormat.m4a => const FfmpegTargetSpec(
            audioCodec: FfmpegAudioCodec.aac,
            faststart: true,
          ),
        MediaFormat.aac => const FfmpegTargetSpec(
            audioCodec: FfmpegAudioCodec.aac,
          ),
        // ID3v2.3 is what Windows Explorer and older car stereos read; the
        // FFmpeg default of 2.4 shows up blank on both.
        MediaFormat.mp3 => const FfmpegTargetSpec(
            audioCodec: FfmpegAudioCodec.mp3,
            containerArguments: <String>['-id3v2_version', '3'],
          ),
        // A RIFF header stores the size in 32 bits, so a plain WAV silently
        // breaks past 4 GiB. `rf64 auto` switches to the extended header only
        // once the file actually grows that far, leaving ordinary WAVs
        // byte-identical to what any player expects.
        MediaFormat.wav => const FfmpegTargetSpec(
            audioCodec: FfmpegAudioCodec.pcm16,
            containerArguments: <String>['-rf64', 'auto'],
          ),
        MediaFormat.flac => const FfmpegTargetSpec(
            audioCodec: FfmpegAudioCodec.flac,
          ),
        MediaFormat.ogg => const FfmpegTargetSpec(
            audioCodec: FfmpegAudioCodec.vorbis,
          ),
        MediaFormat.opus => const FfmpegTargetSpec(
            audioCodec: FfmpegAudioCodec.opus,
          ),
        // Read only: no encoder ships for these.
        MediaFormat.wmv ||
        MediaFormat.mpg ||
        MediaFormat.threeGp ||
        MediaFormat.wma ||
        MediaFormat.aiff =>
          null,
      };

  static FfmpegTargetSpec _h264({
    bool faststart = false,
    String? forcedFormat,
  }) =>
      FfmpegTargetSpec(
        videoCodec: FfmpegVideoCodec.x264,
        audioCodec: FfmpegAudioCodec.aac,
        faststart: faststart,
        forcedFormat: forcedFormat,
      );
}
