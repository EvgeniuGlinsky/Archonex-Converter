import 'package:flutter/foundation.dart';

import 'package:archonex/project_files/features/media_converter/domain/models/audio_bitrate_option.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/conversion_quality.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/frame_rate_option.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/media_format.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/video_resolution.dart';

/// Everything the converter screen can be asked to do, in one bundle.
///
/// The screen has eleven distinct actions; threading them through the body as
/// eleven separate parameters would make every widget signature unreadable and
/// every call site a wall of arguments. Grouping them keeps the widgets free of
/// any dependency on their parent — they still only receive functions.
@immutable
class MediaConverterCallbacks {
  const MediaConverterCallbacks({
    required this.onPickPressed,
    required this.onRemovePressed,
    required this.onTargetSelected,
    required this.onQualityChanged,
    required this.onAdvancedToggled,
    required this.onResolutionChanged,
    required this.onFrameRateChanged,
    required this.onVideoQualityChanged,
    required this.onAudioBitrateChanged,
    required this.onKeepAudioChanged,
    required this.onAdvancedReset,
    required this.onCancelPressed,
    required this.onDownloadPressed,
  });

  final VoidCallback onPickPressed;
  final VoidCallback onRemovePressed;
  final ValueChanged<MediaFormat> onTargetSelected;
  final ValueChanged<ConversionQuality> onQualityChanged;
  final VoidCallback onAdvancedToggled;
  final ValueChanged<VideoResolution> onResolutionChanged;
  final ValueChanged<FrameRateOption> onFrameRateChanged;
  final ValueChanged<int> onVideoQualityChanged;
  final ValueChanged<AudioBitrateOption> onAudioBitrateChanged;
  final ValueChanged<bool> onKeepAudioChanged;
  final VoidCallback onAdvancedReset;
  final VoidCallback onCancelPressed;
  final VoidCallback onDownloadPressed;
}
