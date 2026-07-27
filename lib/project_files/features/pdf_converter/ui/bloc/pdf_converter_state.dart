part of 'pdf_converter_bloc.dart';

enum PdfConverterStatus {
  idle,
  picking,
  ready,
  converting,
  converted,
  saving,
  saved,
}

final class PdfConverterState extends Equatable {
  const PdfConverterState({
    this.isSupported = true,
    this.status = PdfConverterStatus.idle,
    this.sources = const <SourceFile>[],
    this.target,
    this.settings = const PdfConversionSettings(),
    this.results = const <ConvertedFile>[],
    this.pagesDone = 0,
    this.pagesTotal = 0,
    this.isAdvancedExpanded = false,
    this.failure,
    this.savedLocation,
    this.savedCount = 0,
  });

  final bool isSupported;
  final PdfConverterStatus status;
  final List<SourceFile> sources;
  final PdfTarget? target;
  final PdfConversionSettings settings;
  final List<ConvertedFile> results;

  /// Pages dealt with out of pages expected. Both directions count in pages —
  /// see `PdfConversionUpdate` for why that is the one unit that fits.
  final int pagesDone;
  final int pagesTotal;

  final bool isAdvancedExpanded;
  final ConversionFailure? failure;
  final String? savedLocation;
  final int savedCount;

  /// What kind of run the current selection implies, or `null` when there is
  /// nothing selected. Derived rather than stored so it cannot drift from
  /// [sources].
  PdfSourceKind? get sourceKind => sources.isEmpty
      ? null
      : PdfFormat.sharedKind(
          sources
              .map((file) => PdfFormat.fromExtension(file.extension))
              .whereType<PdfFormat>(),
        );

  List<PdfTarget> get availableTargets => PdfTarget.targetsFor(sourceKind);

  int get totalSourceBytes =>
      sources.fold(0, (sum, file) => sum + file.sizeInBytes);

  bool get hasResults => results.isNotEmpty;

  double? get progress =>
      pagesTotal == 0 ? null : (pagesDone / pagesTotal).clamp(0.0, 1.0);

  bool get isConverting => status == PdfConverterStatus.converting;

  bool get isSaving => status == PdfConverterStatus.saving;

  bool get isBusy =>
      isConverting || isSaving || status == PdfConverterStatus.picking;

  bool get canPick =>
      isSupported && !isBusy && sources.length < AppFileLimits.maxBatchFiles;

  bool get canEditSettings =>
      isSupported && !isBusy && availableTargets.isNotEmpty;

  bool get canConvert =>
      isSupported && sources.isNotEmpty && target != null && !isBusy;

  /// Whether the advanced panel has anything to show for the current target.
  bool get hasAdvancedSettings {
    final PdfTarget? current = target;

    return current != null &&
        (settings.appliesPageSizeFor(current) ||
            settings.appliesRasterDpiFor(current));
  }

  PdfConverterState copyWith({
    bool? isSupported,
    PdfConverterStatus? status,
    List<SourceFile>? sources,
    PdfTarget? target,
    bool clearTarget = false,
    PdfConversionSettings? settings,
    List<ConvertedFile>? results,
    int? pagesDone,
    int? pagesTotal,
    bool? isAdvancedExpanded,
    ConversionFailure? failure,
    bool clearFailure = false,
    String? savedLocation,
    bool clearSavedLocation = false,
    int? savedCount,
  }) =>
      PdfConverterState(
        isSupported: isSupported ?? this.isSupported,
        status: status ?? this.status,
        sources: sources ?? this.sources,
        target: clearTarget ? null : target ?? this.target,
        settings: settings ?? this.settings,
        results: results ?? this.results,
        pagesDone: pagesDone ?? this.pagesDone,
        pagesTotal: pagesTotal ?? this.pagesTotal,
        isAdvancedExpanded: isAdvancedExpanded ?? this.isAdvancedExpanded,
        failure: clearFailure ? null : failure ?? this.failure,
        savedLocation:
            clearSavedLocation ? null : savedLocation ?? this.savedLocation,
        savedCount: savedCount ?? this.savedCount,
      );

  @override
  List<Object?> get props => <Object?>[
        isSupported,
        status,
        sources,
        target,
        settings,
        results,
        pagesDone,
        pagesTotal,
        isAdvancedExpanded,
        failure,
        savedLocation,
        savedCount,
      ];
}
