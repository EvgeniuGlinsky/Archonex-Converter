import 'package:equatable/equatable.dart';

import 'package:archonex/project_files/features/image_converter/domain/models/image_background.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_dimension_limit.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex/project_files/features/image_converter/domain/models/image_quality.dart';

/// Everything the user can say about *how* photos should be converted.
///
/// One set of settings covers the whole batch: thirty photos going to WebP are
/// one decision, not thirty. A preset is always present; the advanced fields
/// sit on top of it and each one defaults to deferring back to the preset,
/// which is what lets the panel be opened, inspected and closed again without
/// changing the result.
class ImageConversionSettings extends Equatable {
  const ImageConversionSettings({
    this.quality = ImageQuality.balanced,
    this.dimensionLimit = ImageDimensionLimit.auto,
    this.imageQuality,
    this.background = ImageBackground.white,
    this.keepMetadata = false,
  });

  final ImageQuality quality;
  final ImageDimensionLimit dimensionLimit;

  /// Normalised quality override, or `null` to follow [quality].
  final int? imageQuality;

  /// Colour put behind transparency on targets that cannot carry it.
  final ImageBackground background;

  /// `false` strips EXIF, which is the safer default: a photo posted with its
  /// GPS tag intact is a privacy leak the user did not ask for.
  final bool keepMetadata;

  /// `true` while every advanced field still defers to the preset.
  bool get isPresetOnly =>
      dimensionLimit == ImageDimensionLimit.auto &&
      imageQuality == null &&
      background == ImageBackground.white &&
      !keepMetadata;

  /// Normalised quality actually used.
  int get effectiveQuality => (imageQuality ?? quality.quality).clamp(
        ImageQuality.minQuality,
        ImageQuality.maxQuality,
      );

  /// Cap on the longer side, or `null` when the source size is kept.
  int? get effectiveMaxSide =>
      dimensionLimit.followsPreset ? quality.maxSide : dimensionLimit.pixels;

  /// Drops every advanced value [target] has no use for.
  ///
  /// Without this a quality set for a JPG would sit invisibly in state after a
  /// switch to PNG, and the advanced panel — which only renders the fields the
  /// target supports — would stop matching what is actually stored.
  ImageConversionSettings prunedFor(ImageFormat target) {
    return ImageConversionSettings(
      quality: quality,
      dimensionLimit: dimensionLimit,
      imageQuality: target.supportsQuality ? imageQuality : null,
      background: target.hasAlpha ? ImageBackground.white : background,
      keepMetadata: keepMetadata,
    );
  }

  /// Back to the preset alone, keeping the preset itself.
  ImageConversionSettings resetToPreset() =>
      ImageConversionSettings(quality: quality);

  ImageConversionSettings copyWith({
    ImageQuality? quality,
    ImageDimensionLimit? dimensionLimit,
    int? imageQuality,
    ImageBackground? background,
    bool? keepMetadata,
    bool clearImageQuality = false,
  }) {
    return ImageConversionSettings(
      quality: quality ?? this.quality,
      dimensionLimit: dimensionLimit ?? this.dimensionLimit,
      imageQuality:
          clearImageQuality ? null : imageQuality ?? this.imageQuality,
      background: background ?? this.background,
      keepMetadata: keepMetadata ?? this.keepMetadata,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        quality,
        dimensionLimit,
        imageQuality,
        background,
        keepMetadata,
      ];
}
