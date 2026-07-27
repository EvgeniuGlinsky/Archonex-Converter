part of 'media_converter_bloc.dart';

sealed class MediaConverterEvent extends Equatable {
  const MediaConverterEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Screen opened: read whether this build can convert at all.
final class MediaConverterStarted extends MediaConverterEvent {
  const MediaConverterStarted();
}

final class SourceFilePickRequested extends MediaConverterEvent {
  const SourceFilePickRequested();
}

final class SourceFileCleared extends MediaConverterEvent {
  const SourceFileCleared();
}

final class TargetFormatSelected extends MediaConverterEvent {
  const TargetFormatSelected(this.format);

  final MediaFormat format;

  @override
  List<Object?> get props => <Object?>[format];
}

final class QualityPresetChanged extends MediaConverterEvent {
  const QualityPresetChanged(this.quality);

  final ConversionQuality quality;

  @override
  List<Object?> get props => <Object?>[quality];
}

final class AdvancedPanelToggled extends MediaConverterEvent {
  const AdvancedPanelToggled();
}

final class ResolutionChanged extends MediaConverterEvent {
  const ResolutionChanged(this.resolution);

  final VideoResolution resolution;

  @override
  List<Object?> get props => <Object?>[resolution];
}

final class FrameRateChanged extends MediaConverterEvent {
  const FrameRateChanged(this.frameRate);

  final FrameRateOption frameRate;

  @override
  List<Object?> get props => <Object?>[frameRate];
}

final class VideoQualityChanged extends MediaConverterEvent {
  const VideoQualityChanged(this.videoQuality);

  /// Normalised 0–100 value straight off the slider; clamped by the bloc.
  final int videoQuality;

  @override
  List<Object?> get props => <Object?>[videoQuality];
}

final class AudioBitrateChanged extends MediaConverterEvent {
  const AudioBitrateChanged(this.audioBitrate);

  final AudioBitrateOption audioBitrate;

  @override
  List<Object?> get props => <Object?>[audioBitrate];
}

final class KeepAudioToggled extends MediaConverterEvent {
  const KeepAudioToggled(this.keepAudio);

  final bool keepAudio;

  @override
  List<Object?> get props => <Object?>[keepAudio];
}

/// Back to the quality preset alone, dropping every advanced override.
final class AdvancedSettingsReset extends MediaConverterEvent {
  const AdvancedSettingsReset();
}

final class ConversionRequested extends MediaConverterEvent {
  const ConversionRequested();
}

final class ConversionCancelled extends MediaConverterEvent {
  const ConversionCancelled();
}

final class ConvertedFileSaveRequested extends MediaConverterEvent {
  const ConvertedFileSaveRequested();
}
