import 'package:equatable/equatable.dart';

import 'package:archonex/project_files/features/media_converter/domain/models/audio_bitrate_option.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_quality.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/frame_rate_option.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/video_resolution.dart';

/// Everything the user can say about *how* a file should be converted.
///
/// A preset is always present; the advanced fields sit on top of it and each
/// one defaults to deferring back to the preset. That is what lets the advanced
/// panel be opened, inspected and closed again without changing the result.
class ConversionSettings extends Equatable {
  const ConversionSettings({
    this.quality = ConversionQuality.balanced,
    this.resolution = VideoResolution.auto,
    this.frameRate = FrameRateOption.auto,
    this.audioBitrate = AudioBitrateOption.preset,
    this.videoQuality,
    this.keepAudio = true,
  });

  final ConversionQuality quality;
  final VideoResolution resolution;
  final FrameRateOption frameRate;
  final AudioBitrateOption audioBitrate;

  /// Normalised picture quality override, or `null` to follow [quality].
  final int? videoQuality;

  /// `false` drops the sound from a video target. Ignored by targets that
  /// carry no audio at all.
  final bool keepAudio;

  /// `true` while every advanced field still defers to the preset.
  bool get isPresetOnly =>
      resolution == VideoResolution.auto &&
      frameRate == FrameRateOption.auto &&
      audioBitrate == AudioBitrateOption.preset &&
      videoQuality == null &&
      keepAudio;

  /// Normalised picture quality actually used, between
  /// [ConversionQuality.minVideoQuality] and
  /// [ConversionQuality.maxVideoQuality].
  int get effectiveVideoQuality => (videoQuality ?? quality.videoQuality).clamp(
        ConversionQuality.minVideoQuality,
        ConversionQuality.maxVideoQuality,
      );

  int get effectiveAudioBitrateKbps =>
      audioBitrate.kbps ?? quality.audioBitrateKbps;

  /// Cap on the output height, or `null` when the source height is kept.
  int? get effectiveMaxHeight =>
      resolution.followsPreset ? quality.maxHeight : resolution.height;

  /// Cap on the output width, used by GIF and animated WebP where the preset
  /// speaks in widths. `null` once the user has chosen a height explicitly.
  int? get effectiveAnimationWidth =>
      resolution.followsPreset ? quality.animationWidth : null;

  /// Frames per second to force, or `null` to keep the source rate.
  ///
  /// Animations default to the preset rate: a GIF at the source rate is
  /// enormous, which is never what the user meant by picking GIF.
  int? effectiveFrameRate(MediaFormat target) {
    if (!frameRate.followsPreset) {
      return frameRate.fps;
    }

    return target.isAnimation ? quality.animationFps : null;
  }

  /// Drops every advanced value [target] has no use for.
  ///
  /// Without this a CRF set for an MP4 would sit invisibly in state after a
  /// switch to WAV, and the advanced panel — which only renders the fields the
  /// target supports — would stop matching what is actually stored.
  ConversionSettings prunedFor(MediaFormat target) {
    return ConversionSettings(
      quality: quality,
      resolution: target.supportsResolution ? resolution : VideoResolution.auto,
      frameRate: target.supportsFrameRate ? frameRate : FrameRateOption.auto,
      audioBitrate: target.supportsAudioBitrate
          ? audioBitrate
          : AudioBitrateOption.preset,
      videoQuality: target.supportsVideoQuality ? videoQuality : null,
      keepAudio: target.supportsAudioToggle ? keepAudio : true,
    );
  }

  /// Back to the preset alone, keeping the preset itself.
  ConversionSettings resetToPreset() => ConversionSettings(quality: quality);

  ConversionSettings copyWith({
    ConversionQuality? quality,
    VideoResolution? resolution,
    FrameRateOption? frameRate,
    AudioBitrateOption? audioBitrate,
    int? videoQuality,
    bool? keepAudio,
    bool clearVideoQuality = false,
  }) {
    return ConversionSettings(
      quality: quality ?? this.quality,
      resolution: resolution ?? this.resolution,
      frameRate: frameRate ?? this.frameRate,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      videoQuality:
          clearVideoQuality ? null : videoQuality ?? this.videoQuality,
      keepAudio: keepAudio ?? this.keepAudio,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        quality,
        resolution,
        frameRate,
        audioBitrate,
        videoQuality,
        keepAudio,
      ];
}
