import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/core/constants/app_file_limits.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/save_result.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/source_file.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/convert_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/discard_converted_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/get_image_converter_availability_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/pick_source_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/save_all_converted_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/save_converted_image_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_background.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_item.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_job.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_settings.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_conversion_update.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_dimension_limit.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_format.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/models/image_quality.dart';

part 'image_converter_event.dart';
part 'image_converter_state.dart';

/// Drives the image converter screen: adding photos, choosing a target, tuning
/// quality, converting the batch, cancelling and saving.
///
/// Two error channels, and they mean different things. `state.failure` is about
/// the batch — nothing could be picked, the engine would not start, the save
/// went wrong — and is shown once, at the top. A failure on an individual
/// [ImageConversionItem] is about that photo alone and is shown on its row, so
/// one unreadable file out of thirty marks itself and lets the rest through.
///
/// Results live in temporary files, so any result the bloc drops is handed to
/// [DiscardConvertedImagesUseCase] first — otherwise every run would leak a
/// directory. Anything that changes *what would be produced* drops the whole
/// batch of results: leaving JPGs on screen after the target moved to WEBP
/// would offer downloads that no longer match the settings above them.
class ImageConverterBloc
    extends Bloc<ImageConverterEvent, ImageConverterState> {
  ImageConverterBloc({
    required GetImageConverterAvailabilityUseCase getConverterAvailability,
    required PickSourceImagesUseCase pickSourceImages,
    required ConvertImagesUseCase convertImages,
    required SaveConvertedImageUseCase saveConvertedImage,
    required SaveAllConvertedImagesUseCase saveAllConvertedImages,
    required DiscardConvertedImagesUseCase discardConvertedImages,
  })  : _getConverterAvailability = getConverterAvailability,
        _pickSourceImages = pickSourceImages,
        _convertImages = convertImages,
        _saveConvertedImage = saveConvertedImage,
        _saveAllConvertedImages = saveAllConvertedImages,
        _discardConvertedImages = discardConvertedImages,
        super(const ImageConverterState()) {
    on<ImageConverterStarted>(_onStarted, transformer: restartable());
    // droppable: the OS only shows one dialog, so extra taps must not queue up.
    on<SourceImagesPickRequested>(_onPickRequested, transformer: droppable());
    // sequential: every handler below awaits a real file delete, and the last
    // tap has to be the one that wins.
    on<SourceImageRemoved>(_onImageRemoved, transformer: sequential());
    on<SourceImagesCleared>(_onImagesCleared, transformer: sequential());
    on<TargetFormatSelected>(_onTargetSelected, transformer: sequential());
    on<QualityPresetChanged>(_onQualityChanged, transformer: sequential());
    on<AdvancedPanelToggled>(_onAdvancedToggled, transformer: sequential());
    on<DimensionLimitChanged>(_onDimensionChanged, transformer: sequential());
    on<ImageQualityChanged>(_onImageQualityChanged, transformer: sequential());
    on<BackgroundChanged>(_onBackgroundChanged, transformer: sequential());
    on<KeepMetadataToggled>(_onKeepMetadataToggled, transformer: sequential());
    on<AdvancedSettingsReset>(_onAdvancedReset, transformer: sequential());
    // droppable: one batch at a time; taps during a run are ignored.
    on<ConversionRequested>(_onConversionRequested, transformer: droppable());
    on<ConversionCancelled>(_onConversionCancelled, transformer: sequential());
    on<ConvertedImageSaveRequested>(_onSaveRequested, transformer: droppable());
    on<AllConvertedImagesSaveRequested>(
      _onSaveAllRequested,
      transformer: droppable(),
    );
  }

  final GetImageConverterAvailabilityUseCase _getConverterAvailability;
  final PickSourceImagesUseCase _pickSourceImages;
  final ConvertImagesUseCase _convertImages;
  final SaveConvertedImageUseCase _saveConvertedImage;
  final SaveAllConvertedImagesUseCase _saveAllConvertedImages;
  final DiscardConvertedImagesUseCase _discardConvertedImages;

  ImageConversionJob? _activeJob;

  @override
  Future<void> close() {
    _activeJob?.cancel();
    _activeJob = null;

    _discardConvertedImages(state.results);

    return super.close();
  }

  Future<void> _onStarted(
    ImageConverterStarted event,
    Emitter<ImageConverterState> emit,
  ) async {
    await _dropResults();

    emit(ImageConverterState(isSupported: _getConverterAvailability()));
  }

  Future<void> _onPickRequested(
    SourceImagesPickRequested event,
    Emitter<ImageConverterState> emit,
  ) async {
    final List<ImageConversionItem> kept = await _resetItems();

    emit(
      state.copyWith(
        status: ImageConverterStatus.picking,
        items: kept,
        clearFailure: true,
        clearSavedLocation: true,
      ),
    );

    try {
      final PickedImages picked = await _pickSourceImages(
        alreadySelected: kept.length,
      );

      emit(_withPicked(picked));
    } on ConversionFailure catch (failure) {
      emit(
        state.copyWith(
          status: _statusForSelection(kept),
          failure: failure,
        ),
      );
    }
  }

  /// Appends the accepted photos, keeping the chosen target when it is still
  /// reachable — re-picking WEBP after adding one more PNG would be busywork —
  /// and dropping it otherwise, along with the settings tuned for it.
  ImageConverterState _withPicked(PickedImages picked) {
    final List<ImageConversionItem> items = <ImageConversionItem>[
      ...state.items,
      for (final SourceFile file in picked.accepted)
        if (!_alreadyHolds(file)) ImageConversionItem(source: file),
    ];

    final ImageConverterState next = state.copyWith(
      status: _statusForSelection(items),
      items: items,
      failure: picked.rejection,
    );

    final ImageFormat? target = state.target;
    final bool keepsTarget =
        target != null && next.availableTargets.contains(target);

    return next.copyWith(
      clearTarget: !keepsTarget,
      settings: keepsTarget ? state.settings : const ImageConversionSettings(),
    );
  }

  /// The same file picked twice is one photo, not two: converting it a second
  /// time would produce a duplicate the user has no way to tell apart.
  bool _alreadyHolds(SourceFile file) => state.items.any(
        (item) => item.source.path == null
            ? item.source.name == file.name
            : item.source.path == file.path,
      );

  Future<void> _onImageRemoved(
    SourceImageRemoved event,
    Emitter<ImageConverterState> emit,
  ) async {
    if (!state.canEditSettings || event.index >= state.items.length) {
      return;
    }

    final List<ImageConversionItem> items = await _resetItems();
    items.removeAt(event.index);

    final ImageConverterState next = state.copyWith(
      status: _statusForSelection(items),
      items: items,
      clearFailure: true,
      clearSavedLocation: true,
    );

    final ImageFormat? target = state.target;

    emit(
      next.copyWith(
        clearTarget: target != null && !next.availableTargets.contains(target),
      ),
    );
  }

  Future<void> _onImagesCleared(
    SourceImagesCleared event,
    Emitter<ImageConverterState> emit,
  ) async {
    await _dropResults();

    emit(
      ImageConverterState(
        isSupported: state.isSupported,
        isAdvancedExpanded: state.isAdvancedExpanded,
      ),
    );
  }

  Future<void> _onTargetSelected(
    TargetFormatSelected event,
    Emitter<ImageConverterState> emit,
  ) async {
    if (!state.canEditSettings ||
        !state.availableTargets.contains(event.format) ||
        event.format == state.target) {
      return;
    }

    final List<ImageConversionItem> items = await _resetItems();

    emit(
      _asReady(
        state.copyWith(
          items: items,
          target: event.format,
          settings: state.settings.prunedFor(event.format),
        ),
      ),
    );
  }

  Future<void> _onQualityChanged(
    QualityPresetChanged event,
    Emitter<ImageConverterState> emit,
  ) {
    // The preset is the baseline the advanced fields display, so moving it has
    // to move them: overrides left in place would make High and Compact look
    // identical.
    return _applySettings(
      emit,
      ImageConversionSettings(quality: event.quality),
      isForced: event.quality != state.settings.quality,
    );
  }

  Future<void> _onAdvancedReset(
    AdvancedSettingsReset event,
    Emitter<ImageConverterState> emit,
  ) =>
      _applySettings(emit, state.settings.resetToPreset());

  Future<void> _onDimensionChanged(
    DimensionLimitChanged event,
    Emitter<ImageConverterState> emit,
  ) =>
      _applySettings(
        emit,
        state.settings.copyWith(dimensionLimit: event.limit),
      );

  Future<void> _onImageQualityChanged(
    ImageQualityChanged event,
    Emitter<ImageConverterState> emit,
  ) =>
      _applySettings(
        emit,
        state.settings.copyWith(
          imageQuality: event.quality.clamp(
            ImageQuality.minQuality,
            ImageQuality.maxQuality,
          ),
        ),
      );

  Future<void> _onBackgroundChanged(
    BackgroundChanged event,
    Emitter<ImageConverterState> emit,
  ) =>
      _applySettings(
        emit,
        state.settings.copyWith(background: event.background),
      );

  Future<void> _onKeepMetadataToggled(
    KeepMetadataToggled event,
    Emitter<ImageConverterState> emit,
  ) =>
      _applySettings(
        emit,
        state.settings.copyWith(keepMetadata: event.keepMetadata),
      );

  /// Stores [settings] and throws away results that no longer match them.
  ///
  /// [isForced] exists for the preset, which must still clear the overrides
  /// when the preset itself did not move. Everything else relies on the
  /// equality check, which is what stops a slider drag from firing one temp
  /// file delete per pixel.
  Future<void> _applySettings(
    Emitter<ImageConverterState> emit,
    ImageConversionSettings settings, {
    bool isForced = false,
  }) async {
    if (!state.canEditSettings) {
      return;
    }

    final ImageFormat? target = state.target;
    final ImageConversionSettings next =
        target == null ? settings : settings.prunedFor(target);

    if (!isForced && next == state.settings) {
      return;
    }

    final List<ImageConversionItem> items = await _resetItems();

    emit(_asReady(state.copyWith(items: items, settings: next)));
  }

  void _onAdvancedToggled(
    AdvancedPanelToggled event,
    Emitter<ImageConverterState> emit,
  ) {
    emit(state.copyWith(isAdvancedExpanded: !state.isAdvancedExpanded));
  }

  Future<void> _onConversionRequested(
    ConversionRequested event,
    Emitter<ImageConverterState> emit,
  ) async {
    final ImageFormat? target = state.target;
    if (state.items.isEmpty || target == null) {
      return;
    }

    final List<ImageConversionItem> items = await _resetItems();

    final ImageConversionJob job;

    try {
      job = _convertImages(
        sources: items.map((item) => item.source).toList(growable: false),
        target: target,
        settings: state.settings,
      );
    } on ConversionFailure catch (failure) {
      emit(_withFailure(failure, items));

      return;
    }

    _activeJob = job;

    emit(
      state.copyWith(
        status: ImageConverterStatus.converting,
        items: items,
        clearFailure: true,
        clearSavedLocation: true,
      ),
    );

    await emit.forEach<ImageConversionUpdate>(
      job.updates,
      onData: _withUpdate,
      onError: (error, _) => _withFailure(
        error is ConversionFailure ? error : const ConversionEngineFailure(),
        state.items.map((item) => item.reset()).toList(growable: false),
      ),
    );

    _activeJob = null;

    // The stream closing is what says the queue is done. A cancellation ends it
    // with an error instead, and that already parked the screen back on ready.
    if (state.isConverting) {
      emit(state.copyWith(status: ImageConverterStatus.converted));
    }
  }

  ImageConverterState _withUpdate(ImageConversionUpdate update) {
    if (update.index >= state.items.length) {
      return state;
    }

    final ImageConversionItem item = state.items[update.index];

    final ImageConversionItem next = switch (update) {
      ImageItemStarted() => item.copyWith(status: ImageItemStatus.converting),
      ImageItemConverted(:final ConvertedFile file) => item.copyWith(
          status: ImageItemStatus.done,
          result: file,
          clearFailure: true,
        ),
      ImageItemFailed(:final ConversionFailure failure) => item.copyWith(
          status: ImageItemStatus.failed,
          failure: failure,
          clearResult: true,
        ),
    };

    final List<ImageConversionItem> items =
        List<ImageConversionItem>.of(state.items);
    items[update.index] = next;

    return state.copyWith(items: items);
  }

  Future<void> _onConversionCancelled(
    ConversionCancelled event,
    Emitter<ImageConverterState> emit,
  ) async {
    await _activeJob?.cancel();
  }

  Future<void> _onSaveRequested(
    ConvertedImageSaveRequested event,
    Emitter<ImageConverterState> emit,
  ) async {
    if (event.index >= state.items.length) {
      return;
    }

    final ConvertedFile? result = state.items[event.index].result;
    if (result == null) {
      return;
    }

    await _save(emit, () => _saveConvertedImage(result));
  }

  Future<void> _onSaveAllRequested(
    AllConvertedImagesSaveRequested event,
    Emitter<ImageConverterState> emit,
  ) async {
    final List<ConvertedFile> results = state.results;
    if (results.isEmpty) {
      return;
    }

    await _save(emit, () => _saveAllConvertedImages(results));
  }

  /// The shared half of both save paths: park the screen, run [save], and read
  /// the outcome back into the state.
  Future<void> _save(
    Emitter<ImageConverterState> emit,
    Future<SaveResult> Function() save,
  ) async {
    emit(
      state.copyWith(
        status: ImageConverterStatus.saving,
        clearFailure: true,
        clearSavedLocation: true,
      ),
    );

    try {
      final SaveResult result = await save();

      emit(
        switch (result.outcome) {
          SaveOutcome.cancelled =>
            state.copyWith(status: ImageConverterStatus.converted),
          SaveOutcome.downloadStarted => state.copyWith(
              status: ImageConverterStatus.saved,
              savedCount: result.savedCount,
            ),
          SaveOutcome.savedToLocation => state.copyWith(
              status: ImageConverterStatus.saved,
              savedLocation: result.location,
              savedCount: result.savedCount,
            ),
        },
      );
    } on ConversionFailure catch (failure) {
      emit(
        state.copyWith(
          status: ImageConverterStatus.converted,
          failure: failure,
        ),
      );
    }
  }

  /// Parks a settings change back on the "photos chosen, nothing produced yet"
  /// step, whatever the screen was showing before.
  ImageConverterState _asReady(ImageConverterState next) => next.copyWith(
        status: _statusForSelection(next.items),
        clearFailure: true,
        clearSavedLocation: true,
      );

  ImageConverterStatus _statusForSelection(List<ImageConversionItem> items) =>
      items.isEmpty ? ImageConverterStatus.idle : ImageConverterStatus.ready;

  /// Deletes the temporary files behind the current results and hands back the
  /// batch with every item back at the start.
  Future<List<ImageConversionItem>> _resetItems() async {
    await _dropResults();

    return state.items.map((item) => item.reset()).toList();
  }

  Future<void> _dropResults() async {
    final List<ConvertedFile> results = state.results;
    if (results.isEmpty) {
      return;
    }

    await _discardConvertedImages(results);
  }

  /// Failures always park the screen in a state the user can act from again.
  ImageConverterState _withFailure(
    ConversionFailure failure,
    List<ImageConversionItem> items,
  ) =>
      state.copyWith(
        status: _statusForSelection(items),
        items: items,
        failure: failure,
      );
}
