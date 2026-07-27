part of 'image_converter_bloc.dart';

sealed class ImageConverterEvent extends Equatable {
  const ImageConverterEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Screen opened: read whether this build can convert at all.
final class ImageConverterStarted extends ImageConverterEvent {
  const ImageConverterStarted();
}

final class SourceImagesPickRequested extends ImageConverterEvent {
  const SourceImagesPickRequested();
}

final class SourceImageRemoved extends ImageConverterEvent {
  const SourceImageRemoved(this.index);

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}

final class SourceImagesCleared extends ImageConverterEvent {
  const SourceImagesCleared();
}

final class TargetFormatSelected extends ImageConverterEvent {
  const TargetFormatSelected(this.format);

  final ImageFormat format;

  @override
  List<Object?> get props => <Object?>[format];
}

final class QualityPresetChanged extends ImageConverterEvent {
  const QualityPresetChanged(this.quality);

  final ImageQuality quality;

  @override
  List<Object?> get props => <Object?>[quality];
}

final class AdvancedPanelToggled extends ImageConverterEvent {
  const AdvancedPanelToggled();
}

final class DimensionLimitChanged extends ImageConverterEvent {
  const DimensionLimitChanged(this.limit);

  final ImageDimensionLimit limit;

  @override
  List<Object?> get props => <Object?>[limit];
}

final class ImageQualityChanged extends ImageConverterEvent {
  const ImageQualityChanged(this.quality);

  /// Normalised 0–100 value straight off the slider; clamped by the bloc.
  final int quality;

  @override
  List<Object?> get props => <Object?>[quality];
}

final class BackgroundChanged extends ImageConverterEvent {
  const BackgroundChanged(this.background);

  final ImageBackground background;

  @override
  List<Object?> get props => <Object?>[background];
}

final class KeepMetadataToggled extends ImageConverterEvent {
  const KeepMetadataToggled(this.keepMetadata);

  final bool keepMetadata;

  @override
  List<Object?> get props => <Object?>[keepMetadata];
}

/// Back to the quality preset alone, dropping every advanced override.
final class AdvancedSettingsReset extends ImageConverterEvent {
  const AdvancedSettingsReset();
}

final class ConversionRequested extends ImageConverterEvent {
  const ConversionRequested();
}

final class ConversionCancelled extends ImageConverterEvent {
  const ConversionCancelled();
}

/// Save the one result produced from the photo at [index].
final class ConvertedImageSaveRequested extends ImageConverterEvent {
  const ConvertedImageSaveRequested(this.index);

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}

final class AllConvertedImagesSaveRequested extends ImageConverterEvent {
  const AllConvertedImagesSaveRequested();
}
