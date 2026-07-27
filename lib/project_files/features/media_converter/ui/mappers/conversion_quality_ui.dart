import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_quality.dart';

/// Copy for the quality presets, kept out of the domain layer.
extension ConversionQualityUi on ConversionQuality {
  String get label => switch (this) {
        ConversionQuality.high => AppStrings.qualityHigh,
        ConversionQuality.balanced => AppStrings.qualityBalanced,
        ConversionQuality.compact => AppStrings.qualityCompact,
      };

  /// One line under the selector saying what the choice costs.
  String get hint => switch (this) {
        ConversionQuality.high => AppStrings.qualityHighHint,
        ConversionQuality.balanced => AppStrings.qualityBalancedHint,
        ConversionQuality.compact => AppStrings.qualityCompactHint,
      };
}
