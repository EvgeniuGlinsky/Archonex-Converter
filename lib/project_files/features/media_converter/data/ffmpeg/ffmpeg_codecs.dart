import 'package:archonex/project_files/features/converter_shared/data/ffmpeg/ffmpeg_quality_scale.dart';

/// The video encoders the bundled FFmpeg build can write with.
///
/// Every one of them expresses quality on its own scale, and two of them run
/// it backwards. [qualityArgument] is what hides that: callers pass the single
/// normalised value coming from `ConversionSettings` and get back the number
/// this particular encoder wants.
enum FfmpegVideoCodec {
  /// H.264. The default for anything MP4-shaped; widest playback support.
  x264(
    name: 'libx264',
    qualityFlag: '-crf',
    bestValue: 16,
    worstValue: 34,
    pixelFormat: _yuv420p,
    extraArguments: <String>['-preset', 'medium'],
  ),

  /// VP9 for WebM. `-b:v 0` is what puts libvpx into constant quality mode;
  /// without it `-crf` is treated as a ceiling and the result is huge.
  /// `-cpu-used 4` trades a little quality for an encode that finishes on a
  /// phone in this decade.
  vp9(
    name: 'libvpx-vp9',
    qualityFlag: '-crf',
    bestValue: 22,
    worstValue: 46,
    pixelFormat: _yuv420p,
    extraArguments: <String>[
      '-b:v',
      '0',
      '-row-mt',
      '1',
      '-deadline',
      'good',
      '-cpu-used',
      '4',
    ],
  ),

  /// MPEG-4 Part 2, which is what AVI players expect. Scale runs 1 (best) to
  /// 31 (worst); the useful part of it is the range below.
  mpeg4(
    name: 'mpeg4',
    qualityFlag: '-q:v',
    bestValue: 2,
    worstValue: 12,
    pixelFormat: _yuv420p,
  ),

  /// Theora for OGV. Its scale runs the other way: 10 is best.
  theora(
    name: 'libtheora',
    qualityFlag: '-q:v',
    bestValue: 10,
    worstValue: 2,
    pixelFormat: _yuv420p,
  ),

  /// Animated WebP. Also inverted, and it needs telling not to go lossless —
  /// lossless animation output is enormous.
  webp(
    name: 'libwebp',
    qualityFlag: '-q:v',
    bestValue: 95,
    worstValue: 30,
    extraArguments: <String>['-lossless', '0', '-preset', 'default'],
  );

  const FfmpegVideoCodec({
    required this.name,
    required this.qualityFlag,
    required this.bestValue,
    required this.worstValue,
    this.pixelFormat,
    this.extraArguments = const <String>[],
  });

  static const String _yuv420p = 'yuv420p';

  /// Encoder name as FFmpeg knows it.
  final String name;

  /// Flag the quality number is passed with, `-crf` or `-q:v`.
  final String qualityFlag;

  /// Codec value standing for the best picture this encoder should produce.
  final int bestValue;

  /// Codec value standing for the worst picture still worth producing.
  final int worstValue;

  /// Pixel format to force, or `null` to leave FFmpeg's choice alone.
  ///
  /// `yuv420p` is what makes the output playable outside FFmpeg itself; the
  /// encoders above otherwise happily emit 4:4:4 that phones refuse.
  final String? pixelFormat;

  final List<String> extraArguments;

  /// `true` where odd dimensions are rejected outright, which is every codec
  /// writing `yuv420p`.
  bool get needsEvenDimensions => pixelFormat == _yuv420p;

  /// Turns the normalised 0–100 quality into this encoder's own number.
  int qualityArgument(int normalized) => ffmpegQualityArgument(
        normalized: normalized,
        bestValue: bestValue,
        worstValue: worstValue,
      );
}

/// The audio encoders the bundled FFmpeg build can write with.
enum FfmpegAudioCodec {
  aac(name: 'aac'),
  mp3(name: 'libmp3lame'),
  opus(name: 'libopus'),
  vorbis(name: 'libvorbis'),

  /// Lossless: a bitrate would be ignored, so none is passed.
  flac(name: 'flac', usesBitrate: false),

  /// Uncompressed 16 bit PCM, which is what a WAV file is.
  pcm16(name: 'pcm_s16le', usesBitrate: false);

  const FfmpegAudioCodec({required this.name, this.usesBitrate = true});

  final String name;

  /// `false` for lossless and uncompressed codecs, where `-b:a` means nothing.
  final bool usesBitrate;
}
