part of 'media_converter_bloc.dart';

enum MediaConverterStatus {
  idle,
  picking,
  ready,
  converting,
  converted,
  saving,
  saved,
}

final class MediaConverterState extends Equatable {
  const MediaConverterState({
    this.status = MediaConverterStatus.idle,
    this.isSupported = true,
    this.source,
    this.target,
    this.settings = const ConversionSettings(),
    this.isAdvancedExpanded = false,
    this.result,
    this.progress,
    this.failure,
    this.savedLocation,
  });

  final MediaConverterStatus status;

  /// `false` where the build has no FFmpeg engine — Linux and web.
  final bool isSupported;

  final SourceFile? source;

  /// Format the result is written in, `null` until one is chosen.
  final MediaFormat? target;

  final ConversionSettings settings;

  /// Whether the advanced panel is open. Purely a viewport preference, which
  /// is why nothing else in the state reacts to it.
  final bool isAdvancedExpanded;

  final ConvertedFile? result;

  /// Fraction between `0` and `1` while converting, or `null` when the length
  /// of the input is unknown and progress can only be indeterminate.
  final double? progress;

  /// The single error channel of the screen. `null` means nothing is wrong.
  final ConversionFailure? failure;

  /// Where the last save landed, `null` when the platform does not report it.
  final String? savedLocation;

  /// Detected from the file name rather than stored, so it can never drift out
  /// of sync with [source].
  MediaFormat? get sourceFormat => source?.format;

  /// Formats reachable from the picked file. Empty until one is picked, which
  /// is also what keeps the target grid off the screen.
  List<MediaFormat> get availableTargets =>
      sourceFormat?.targets ?? const <MediaFormat>[];

  bool get isConverting => status == MediaConverterStatus.converting;

  bool get isSaving => status == MediaConverterStatus.saving;

  bool get isBusy =>
      isConverting || isSaving || status == MediaConverterStatus.picking;

  bool get canPick => isSupported && !isBusy;

  /// The grid, the presets and the advanced panel all go dead together.
  bool get canEditSettings =>
      isSupported && !isBusy && availableTargets.isNotEmpty;

  bool get canConvert =>
      isSupported && source != null && target != null && !isBusy;

  MediaConverterState copyWith({
    MediaConverterStatus? status,
    bool? isSupported,
    SourceFile? source,
    MediaFormat? target,
    ConversionSettings? settings,
    bool? isAdvancedExpanded,
    ConvertedFile? result,
    double? progress,
    ConversionFailure? failure,
    String? savedLocation,
    bool clearSource = false,
    bool clearTarget = false,
    bool clearResult = false,
    bool clearProgress = false,
    bool clearFailure = false,
    bool clearSavedLocation = false,
  }) {
    return MediaConverterState(
      status: status ?? this.status,
      isSupported: isSupported ?? this.isSupported,
      source: clearSource ? null : source ?? this.source,
      target: clearTarget ? null : target ?? this.target,
      settings: settings ?? this.settings,
      isAdvancedExpanded: isAdvancedExpanded ?? this.isAdvancedExpanded,
      result: clearResult ? null : result ?? this.result,
      progress: clearProgress ? null : progress ?? this.progress,
      failure: clearFailure ? null : failure ?? this.failure,
      savedLocation:
          clearSavedLocation ? null : savedLocation ?? this.savedLocation,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        isSupported,
        source,
        target,
        settings,
        isAdvancedExpanded,
        result,
        progress,
        failure,
        savedLocation,
      ];
}
