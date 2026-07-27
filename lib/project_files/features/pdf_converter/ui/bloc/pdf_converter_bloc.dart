import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/convert_pdf_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/discard_converted_pdfs_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/get_pdf_converter_availability_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/pick_pdf_sources_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/save_all_converted_pdfs_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/use_cases/save_converted_pdf_use_case.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_job.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_conversion_update.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_format.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_page_size.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/models/pdf_target.dart';

part 'pdf_converter_event.dart';
part 'pdf_converter_state.dart';

/// Drives the PDF converter screen.
///
/// One error channel rather than the image converter's two. That converter can
/// lose one photo out of thirty and still hand back a useful batch, so a
/// failure belongs on the row it came from. Neither direction here works that
/// way: a merged PDF missing a page is not a document anyone asked for, and a
/// half rasterised PDF is not a set of pages. Anything that goes wrong ends the
/// whole run, and `state.failure` says so once, at the top.
///
/// Results live in temporary files, so anything the bloc drops goes through
/// [DiscardConvertedPdfsUseCase] first. As in the other converters, everything
/// that changes *what would be produced* throws the current results away.
class PdfConverterBloc extends Bloc<PdfConverterEvent, PdfConverterState> {
  PdfConverterBloc({
    required GetPdfConverterAvailabilityUseCase getConverterAvailability,
    required PickPdfSourcesUseCase pickSources,
    required ConvertPdfUseCase convertPdf,
    required SaveConvertedPdfUseCase saveConvertedPdf,
    required SaveAllConvertedPdfsUseCase saveAllConvertedPdfs,
    required DiscardConvertedPdfsUseCase discardConvertedPdfs,
  })  : _getConverterAvailability = getConverterAvailability,
        _pickSources = pickSources,
        _convertPdf = convertPdf,
        _saveConvertedPdf = saveConvertedPdf,
        _saveAllConvertedPdfs = saveAllConvertedPdfs,
        _discardConvertedPdfs = discardConvertedPdfs,
        super(const PdfConverterState()) {
    on<PdfConverterStarted>(_onStarted, transformer: restartable());
    // droppable: the OS shows one dialog, so extra taps must not queue up.
    on<PdfSourcesPickRequested>(_onPickRequested, transformer: droppable());
    // sequential: each of these awaits a real file delete, and the last tap has
    // to be the one that wins.
    on<PdfSourceRemoved>(_onSourceRemoved, transformer: sequential());
    on<PdfSourcesCleared>(_onSourcesCleared, transformer: sequential());
    on<PdfTargetSelected>(_onTargetSelected, transformer: sequential());
    on<PdfPageSizeChanged>(_onPageSizeChanged, transformer: sequential());
    on<PdfMarginChanged>(_onMarginChanged, transformer: sequential());
    on<PdfRasterDpiChanged>(_onRasterDpiChanged, transformer: sequential());
    on<PdfQualityChanged>(_onQualityChanged, transformer: sequential());
    on<PdfAdvancedSettingsReset>(_onAdvancedReset, transformer: sequential());
    on<PdfAdvancedPanelToggled>(_onAdvancedToggled, transformer: sequential());
    // droppable: one run at a time; taps during it are ignored.
    on<PdfConversionRequested>(_onConversionRequested, transformer: droppable());
    on<PdfConversionCancelled>(_onConversionCancelled, transformer: sequential());
    on<ConvertedPdfSaveRequested>(_onSaveRequested, transformer: droppable());
    on<AllConvertedPdfsSaveRequested>(
      _onSaveAllRequested,
      transformer: droppable(),
    );
  }

  final GetPdfConverterAvailabilityUseCase _getConverterAvailability;
  final PickPdfSourcesUseCase _pickSources;
  final ConvertPdfUseCase _convertPdf;
  final SaveConvertedPdfUseCase _saveConvertedPdf;
  final SaveAllConvertedPdfsUseCase _saveAllConvertedPdfs;
  final DiscardConvertedPdfsUseCase _discardConvertedPdfs;

  PdfConversionJob? _activeJob;

  @override
  Future<void> close() {
    _activeJob?.cancel();
    _activeJob = null;

    _discardConvertedPdfs(state.results);

    return super.close();
  }

  Future<void> _onStarted(
    PdfConverterStarted event,
    Emitter<PdfConverterState> emit,
  ) async {
    await _dropResults();

    emit(PdfConverterState(isSupported: _getConverterAvailability()));
  }

  Future<void> _onPickRequested(
    PdfSourcesPickRequested event,
    Emitter<PdfConverterState> emit,
  ) async {
    await _dropResults();

    emit(
      state.copyWith(
        status: PdfConverterStatus.picking,
        results: const <ConvertedFile>[],
        clearFailure: true,
        clearSavedLocation: true,
      ),
    );

    try {
      final PickedPdfSources picked = await _pickSources(
        alreadySelected: state.sources.length,
        existingKind: state.sourceKind,
      );

      emit(_withPicked(picked));
    } on ConversionFailure catch (failure) {
      emit(
        state.copyWith(
          status: _statusForSelection(state.sources),
          failure: failure,
        ),
      );
    }
  }

  /// Appends the accepted files, keeping the chosen target when the new
  /// selection can still reach it and dropping it — with the settings tuned for
  /// it — when it cannot.
  PdfConverterState _withPicked(PickedPdfSources picked) {
    final List<SourceFile> sources = <SourceFile>[
      ...state.sources,
      for (final SourceFile file in picked.accepted)
        if (!_alreadyHolds(file)) file,
    ];

    final PdfConverterState next = state.copyWith(
      status: _statusForSelection(sources),
      sources: sources,
      failure: picked.rejection,
    );

    final PdfTarget? target = state.target;
    final bool keepsTarget =
        target != null && next.availableTargets.contains(target);

    return next.copyWith(
      clearTarget: !keepsTarget,
      settings: keepsTarget ? state.settings : const PdfConversionSettings(),
    );
  }

  /// The same file picked twice is one entry: converting it again would produce
  /// a duplicate page the user has no way to tell apart.
  bool _alreadyHolds(SourceFile file) => state.sources.any(
        (held) => held.path == null
            ? held.name == file.name
            : held.path == file.path,
      );

  Future<void> _onSourceRemoved(
    PdfSourceRemoved event,
    Emitter<PdfConverterState> emit,
  ) async {
    if (!state.canEditSettings || event.index >= state.sources.length) {
      return;
    }

    await _dropResults();

    final List<SourceFile> sources = List<SourceFile>.of(state.sources)
      ..removeAt(event.index);

    final PdfConverterState next = state.copyWith(
      status: _statusForSelection(sources),
      sources: sources,
      results: const <ConvertedFile>[],
      clearFailure: true,
      clearSavedLocation: true,
    );

    final PdfTarget? target = state.target;

    emit(
      next.copyWith(
        clearTarget: target != null && !next.availableTargets.contains(target),
      ),
    );
  }

  Future<void> _onSourcesCleared(
    PdfSourcesCleared event,
    Emitter<PdfConverterState> emit,
  ) async {
    await _dropResults();

    emit(
      PdfConverterState(
        isSupported: state.isSupported,
        isAdvancedExpanded: state.isAdvancedExpanded,
      ),
    );
  }

  Future<void> _onTargetSelected(
    PdfTargetSelected event,
    Emitter<PdfConverterState> emit,
  ) async {
    if (!state.canEditSettings ||
        !state.availableTargets.contains(event.target) ||
        event.target == state.target) {
      return;
    }

    await _dropResults();

    emit(
      _asReady(
        state.copyWith(
          target: event.target,
          settings: state.settings.prunedFor(event.target),
          results: const <ConvertedFile>[],
        ),
      ),
    );
  }

  Future<void> _onPageSizeChanged(
    PdfPageSizeChanged event,
    Emitter<PdfConverterState> emit,
  ) =>
      _applySettings(emit, state.settings.copyWith(pageSize: event.pageSize));

  Future<void> _onMarginChanged(
    PdfMarginChanged event,
    Emitter<PdfConverterState> emit,
  ) =>
      _applySettings(
        emit,
        state.settings.copyWith(marginPoints: event.marginPoints),
      );

  Future<void> _onRasterDpiChanged(
    PdfRasterDpiChanged event,
    Emitter<PdfConverterState> emit,
  ) =>
      _applySettings(emit, state.settings.copyWith(rasterDpi: event.dpi));

  Future<void> _onQualityChanged(
    PdfQualityChanged event,
    Emitter<PdfConverterState> emit,
  ) =>
      _applySettings(emit, state.settings.copyWith(quality: event.quality));

  Future<void> _onAdvancedReset(
    PdfAdvancedSettingsReset event,
    Emitter<PdfConverterState> emit,
  ) =>
      _applySettings(emit, const PdfConversionSettings());

  /// Stores [settings] and throws away results that no longer match them.
  ///
  /// The equality check is what stops a slider drag from firing one temporary
  /// file delete per pixel.
  Future<void> _applySettings(
    Emitter<PdfConverterState> emit,
    PdfConversionSettings settings,
  ) async {
    if (!state.canEditSettings) {
      return;
    }

    final PdfTarget? target = state.target;
    final PdfConversionSettings next =
        target == null ? settings : settings.prunedFor(target);

    if (next == state.settings) {
      return;
    }

    await _dropResults();

    emit(
      _asReady(
        state.copyWith(settings: next, results: const <ConvertedFile>[]),
      ),
    );
  }

  void _onAdvancedToggled(
    PdfAdvancedPanelToggled event,
    Emitter<PdfConverterState> emit,
  ) {
    emit(state.copyWith(isAdvancedExpanded: !state.isAdvancedExpanded));
  }

  Future<void> _onConversionRequested(
    PdfConversionRequested event,
    Emitter<PdfConverterState> emit,
  ) async {
    final PdfTarget? target = state.target;
    if (state.sources.isEmpty || target == null) {
      return;
    }

    await _dropResults();

    final PdfConversionJob job;

    try {
      job = _convertPdf(
        sources: state.sources,
        target: target,
        settings: state.settings,
      );
    } on ConversionFailure catch (failure) {
      emit(_withFailure(failure));

      return;
    }

    _activeJob = job;

    emit(
      state.copyWith(
        status: PdfConverterStatus.converting,
        results: const <ConvertedFile>[],
        pagesDone: 0,
        pagesTotal: 0,
        clearFailure: true,
        clearSavedLocation: true,
      ),
    );

    await emit.forEach<PdfConversionUpdate>(
      job.updates,
      onData: _withUpdate,
      onError: (error, _) => _withFailure(
        error is ConversionFailure ? error : const ConversionEngineFailure(),
      ),
    );

    _activeJob = null;

    // The stream closing is what says the run is done. A cancellation ends it
    // with an error instead, and that already parked the screen back on ready.
    if (state.isConverting) {
      emit(state.copyWith(status: PdfConverterStatus.converted));
    }
  }

  PdfConverterState _withUpdate(PdfConversionUpdate update) => switch (update) {
        PdfProgressed(:final int done, :final int total) =>
          state.copyWith(pagesDone: done, pagesTotal: total),
        PdfFileProduced(:final ConvertedFile file) => state.copyWith(
            results: <ConvertedFile>[...state.results, file],
          ),
      };

  Future<void> _onConversionCancelled(
    PdfConversionCancelled event,
    Emitter<PdfConverterState> emit,
  ) async {
    await _activeJob?.cancel();
  }

  Future<void> _onSaveRequested(
    ConvertedPdfSaveRequested event,
    Emitter<PdfConverterState> emit,
  ) async {
    if (event.index >= state.results.length) {
      return;
    }

    final ConvertedFile result = state.results[event.index];

    await _save(emit, () => _saveConvertedPdf(result));
  }

  Future<void> _onSaveAllRequested(
    AllConvertedPdfsSaveRequested event,
    Emitter<PdfConverterState> emit,
  ) async {
    if (state.results.isEmpty) {
      return;
    }

    await _save(emit, () => _saveAllConvertedPdfs(state.results));
  }

  /// The shared half of both save paths: park the screen, run [save], and read
  /// the outcome back into the state.
  Future<void> _save(
    Emitter<PdfConverterState> emit,
    Future<SaveResult> Function() save,
  ) async {
    emit(
      state.copyWith(
        status: PdfConverterStatus.saving,
        clearFailure: true,
        clearSavedLocation: true,
      ),
    );

    try {
      final SaveResult result = await save();

      emit(
        switch (result.outcome) {
          SaveOutcome.cancelled =>
            state.copyWith(status: PdfConverterStatus.converted),
          SaveOutcome.downloadStarted => state.copyWith(
              status: PdfConverterStatus.saved,
              savedCount: result.savedCount,
            ),
          SaveOutcome.savedToLocation => state.copyWith(
              status: PdfConverterStatus.saved,
              savedLocation: result.location,
              savedCount: result.savedCount,
            ),
        },
      );
    } on ConversionFailure catch (failure) {
      emit(
        state.copyWith(
          status: PdfConverterStatus.converted,
          failure: failure,
        ),
      );
    }
  }

  /// Parks a settings change back on the "files chosen, nothing produced yet"
  /// step, whatever the screen was showing before.
  PdfConverterState _asReady(PdfConverterState next) => next.copyWith(
        status: _statusForSelection(next.sources),
        pagesDone: 0,
        pagesTotal: 0,
        clearFailure: true,
        clearSavedLocation: true,
      );

  PdfConverterStatus _statusForSelection(List<SourceFile> sources) =>
      sources.isEmpty ? PdfConverterStatus.idle : PdfConverterStatus.ready;

  PdfConverterState _withFailure(ConversionFailure failure) => state.copyWith(
        status: _statusForSelection(state.sources),
        results: const <ConvertedFile>[],
        pagesDone: 0,
        pagesTotal: 0,
        failure: failure,
      );

  Future<void> _dropResults() async {
    if (state.results.isEmpty) {
      return;
    }

    await _discardConvertedPdfs(state.results);
  }
}
