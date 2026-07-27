part of 'image_converter_bloc.dart';

enum ImageConverterStatus {
  idle,
  picking,
  ready,
  converting,
  converted,
  saving,
  saved,
}

final class ImageConverterState extends Equatable {
  const ImageConverterState({
    this.status = ImageConverterStatus.idle,
    this.isSupported = true,
    this.items = const <ImageConversionItem>[],
    this.target,
    this.settings = const ImageConversionSettings(),
    this.isAdvancedExpanded = false,
    this.failure,
    this.savedLocation,
    this.savedCount = 0,
  });

  final ImageConverterStatus status;

  /// `false` where the build has no FFmpeg engine — Linux and web.
  final bool isSupported;

  /// The batch, in the order the photos were added.
  final List<ImageConversionItem> items;

  /// Format every result is written in, `null` until one is chosen.
  final ImageFormat? target;

  /// One set of settings for the whole batch.
  final ImageConversionSettings settings;

  /// Whether the advanced panel is open. Purely a viewport preference, which
  /// is why nothing else in the state reacts to it.
  final bool isAdvancedExpanded;

  /// The batch level error channel. Per photo failures live on their item.
  final ConversionFailure? failure;

  /// Where the last save landed, `null` when the platform does not report it.
  final String? savedLocation;

  /// How many files the last save wrote.
  final int savedCount;

  List<SourceFile> get sources =>
      items.map((item) => item.source).toList(growable: false);

  int get totalCount => items.length;

  int get convertedCount =>
      items.where((item) => item.status == ImageItemStatus.done).length;

  int get failedCount =>
      items.where((item) => item.status == ImageItemStatus.failed).length;

  /// Photos that will not be touched again this run.
  int get finishedCount => convertedCount + failedCount;

  /// Everything produced so far, in batch order.
  List<ConvertedFile> get results => items
      .map((item) => item.result)
      .whereType<ConvertedFile>()
      .toList(growable: false);

  bool get hasResults => results.isNotEmpty;

  int get totalSourceBytes => items.fold(
        0,
        (sum, item) => sum + item.source.sizeInBytes,
      );

  int get totalResultBytes =>
      results.fold(0, (sum, file) => sum + file.sizeInBytes);

  /// Formats reachable from the batch. Empty until a photo is added, which is
  /// also what keeps the target grid off the screen.
  ///
  /// Detected from the file names rather than stored, so it can never drift
  /// out of sync with [items].
  List<ImageFormat> get availableTargets {
    if (items.isEmpty) {
      return const <ImageFormat>[];
    }

    final Iterable<ImageFormat> formats = items
        .map((item) => ImageFormat.fromExtension(item.source.extension))
        .whereType<ImageFormat>();

    return ImageFormat.targetsFor(formats);
  }

  /// Whether the backdrop question is worth asking.
  ///
  /// It only is when transparency is actually about to be lost: a target that
  /// carries alpha keeps it, and a batch of JPGs has none to begin with.
  bool get needsBackgroundChoice {
    final ImageFormat? format = target;

    if (format == null || format.hasAlpha) {
      return false;
    }

    return items.any(
      (item) =>
          ImageFormat.fromExtension(item.source.extension)?.hasAlpha ?? false,
    );
  }

  /// How far the batch has got, as a fraction of the photos in it.
  ///
  /// A photo carries no duration, so there is nothing to measure inside one
  /// conversion. Counting finished photos is exact rather than an estimate.
  double? get progress =>
      totalCount == 0 ? null : finishedCount / totalCount;

  bool get isConverting => status == ImageConverterStatus.converting;

  bool get isSaving => status == ImageConverterStatus.saving;

  bool get isBusy =>
      isConverting || isSaving || status == ImageConverterStatus.picking;

  bool get canPick =>
      isSupported && !isBusy && totalCount < AppFileLimits.maxBatchFiles;

  /// The grid, the presets and the advanced panel all go dead together.
  bool get canEditSettings =>
      isSupported && !isBusy && availableTargets.isNotEmpty;

  bool get canConvert =>
      isSupported && items.isNotEmpty && target != null && !isBusy;

  ImageConverterState copyWith({
    ImageConverterStatus? status,
    bool? isSupported,
    List<ImageConversionItem>? items,
    ImageFormat? target,
    ImageConversionSettings? settings,
    bool? isAdvancedExpanded,
    ConversionFailure? failure,
    String? savedLocation,
    int? savedCount,
    bool clearTarget = false,
    bool clearFailure = false,
    bool clearSavedLocation = false,
  }) {
    return ImageConverterState(
      status: status ?? this.status,
      isSupported: isSupported ?? this.isSupported,
      items: items ?? this.items,
      target: clearTarget ? null : target ?? this.target,
      settings: settings ?? this.settings,
      isAdvancedExpanded: isAdvancedExpanded ?? this.isAdvancedExpanded,
      failure: clearFailure ? null : failure ?? this.failure,
      savedLocation:
          clearSavedLocation ? null : savedLocation ?? this.savedLocation,
      savedCount: clearSavedLocation ? 0 : savedCount ?? this.savedCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        isSupported,
        items,
        target,
        settings,
        isAdvancedExpanded,
        failure,
        savedLocation,
        savedCount,
      ];
}
