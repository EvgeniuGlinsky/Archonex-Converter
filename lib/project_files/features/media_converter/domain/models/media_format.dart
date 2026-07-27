/// What a format fundamentally carries, which is what decides the conversions
/// that make sense for it.
enum MediaFormatKind {
  /// A container with a video track and usually an audio track.
  video,

  /// A looping picture: no audio track exists, so none can be extracted.
  animation,

  /// Sound only.
  audio,
}

/// Every format the converter knows about.
///
/// One entry per extension, because the extension is what the picker hands
/// back and what the output file is named after. [canEncode] is what separates
/// a format FFmpeg can only read from one it can also write: a source-only
/// entry never shows up in the target list.
enum MediaFormat {
  // Video containers.
  mp4(extension: 'mp4', kind: MediaFormatKind.video),
  mkv(extension: 'mkv', kind: MediaFormatKind.video),
  mov(extension: 'mov', kind: MediaFormatKind.video),
  webm(extension: 'webm', kind: MediaFormatKind.video),
  avi(extension: 'avi', kind: MediaFormatKind.video),
  m4v(extension: 'm4v', kind: MediaFormatKind.video),
  flv(extension: 'flv', kind: MediaFormatKind.video),
  ts(extension: 'ts', kind: MediaFormatKind.video),
  ogv(extension: 'ogv', kind: MediaFormatKind.video),
  wmv(extension: 'wmv', kind: MediaFormatKind.video, canEncode: false),
  mpg(
    extension: 'mpg',
    kind: MediaFormatKind.video,
    canEncode: false,
    aliases: <String>['mpeg'],
  ),
  threeGp(extension: '3gp', kind: MediaFormatKind.video, canEncode: false),

  // Animated pictures.
  // GIF has no quality dial of its own: its size is decided by the frame rate,
  // the width and the palette, all of which the filter graph already sets.
  gif(
    extension: 'gif',
    kind: MediaFormatKind.animation,
    hasVideoQuality: false,
  ),
  webp(extension: 'webp', kind: MediaFormatKind.animation),

  // Audio.
  mp3(extension: 'mp3', kind: MediaFormatKind.audio),
  m4a(extension: 'm4a', kind: MediaFormatKind.audio),
  aac(extension: 'aac', kind: MediaFormatKind.audio),
  wav(extension: 'wav', kind: MediaFormatKind.audio, isLosslessAudio: true),
  flac(extension: 'flac', kind: MediaFormatKind.audio, isLosslessAudio: true),
  ogg(
    extension: 'ogg',
    kind: MediaFormatKind.audio,
    aliases: <String>['oga'],
  ),
  opus(extension: 'opus', kind: MediaFormatKind.audio),
  wma(extension: 'wma', kind: MediaFormatKind.audio, canEncode: false),
  aiff(
    extension: 'aiff',
    kind: MediaFormatKind.audio,
    canEncode: false,
    isLosslessAudio: true,
    aliases: <String>['aif'],
  );

  const MediaFormat({
    required this.extension,
    required this.kind,
    this.canEncode = true,
    this.hasVideoQuality = true,
    this.isLosslessAudio = false,
    this.aliases = const <String>[],
  });

  /// Lower case extension without the leading dot.
  final String extension;

  final MediaFormatKind kind;

  /// `false` for formats the bundled FFmpeg reads but has no encoder for.
  final bool canEncode;

  /// `false` where the encoder has no quality dial to offer, which is GIF.
  final bool hasVideoQuality;

  /// `true` where a bitrate would be ignored, which is WAV, FLAC and AIFF.
  final bool isLosslessAudio;

  /// Extra extensions that resolve to this same format when picking a file.
  final List<String> aliases;

  /// Upper case form shown on chips and inside copy, e.g. `MP4`.
  String get label => extension.toUpperCase();

  bool get isVideo => kind == MediaFormatKind.video;

  bool get isAnimation => kind == MediaFormatKind.animation;

  bool get isAudio => kind == MediaFormatKind.audio;

  /// Whether a track of sound can come out of this format.
  bool get hasAudioTrack => kind != MediaFormatKind.animation;

  /// Every extension that resolves to this format, canonical one first.
  List<String> get extensions => <String>[extension, ...aliases];

  // Which advanced controls make sense once this format is the target. The
  // panel renders exactly the ones that say `true`, so a knob the encoder would
  // ignore is never offered.

  bool get supportsResolution => !isAudio;

  bool get supportsFrameRate => !isAudio;

  bool get supportsVideoQuality => !isAudio && hasVideoQuality;

  bool get supportsAudioBitrate => hasAudioTrack && !isLosslessAudio;

  /// Only a video can be asked to go silent: an animation has no sound to drop
  /// and an audio target would be left with nothing at all.
  bool get supportsAudioToggle => isVideo;

  /// Extensions the file picker is opened with, aliases included.
  static List<String> get pickableExtensions => <String>[
        for (final MediaFormat format in MediaFormat.values)
          ...format.extensions,
      ];

  /// The format behind [extension], or `null` when it is not supported.
  static MediaFormat? fromExtension(String extension) {
    final String normalized = extension.toLowerCase();

    for (final MediaFormat format in MediaFormat.values) {
      if (format.extensions.contains(normalized)) {
        return format;
      }
    }

    return null;
  }

  /// Formats this one can be converted into.
  ///
  /// The rules are a consequence of what the source actually holds rather than
  /// a hand written matrix:
  ///
  /// * video — anything, including pulling the sound out on its own
  /// * animation — video and other animations; there is no audio to extract
  /// * audio — audio only, since no pictures can be invented
  ///
  /// The source format itself is left out: converting MP4 to MP4 is a re-encode
  /// the screen has no way to explain.
  List<MediaFormat> get targets {
    bool isAllowed(MediaFormat candidate) {
      if (!candidate.canEncode || candidate == this) {
        return false;
      }

      return switch (kind) {
        MediaFormatKind.video => true,
        MediaFormatKind.animation => !candidate.isAudio,
        MediaFormatKind.audio => candidate.isAudio,
      };
    }

    return MediaFormat.values.where(isAllowed).toList(growable: false);
  }

  /// [targets] restricted to one kind, in enum order. Empty groups are simply
  /// not rendered by the target picker.
  List<MediaFormat> targetsOfKind(MediaFormatKind target) =>
      targets.where((format) => format.kind == target).toList(growable: false);
}
