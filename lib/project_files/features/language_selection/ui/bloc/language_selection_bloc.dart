import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex/project_files/features/language_selection/data/use_cases/get_available_languages_use_case.dart';
import 'package:archonex/project_files/features/language_selection/data/use_cases/get_selected_language_use_case.dart';
import 'package:archonex/project_files/features/language_selection/data/use_cases/select_language_use_case.dart';
import 'package:archonex/project_files/features/language_selection/domain/models/app_language.dart';

part 'language_selection_event.dart';
part 'language_selection_state.dart';

/// Owns the language choice until the user confirms it.
///
/// The pick is only handed to the repository on [LanguageSelectionSubmitted],
/// so backing out of the screen leaves the stored language untouched.
class LanguageSelectionBloc
    extends Bloc<LanguageSelectionEvent, LanguageSelectionState> {
  LanguageSelectionBloc({
    required GetAvailableLanguagesUseCase getAvailableLanguages,
    required GetSelectedLanguageUseCase getSelectedLanguage,
    required SelectLanguageUseCase selectLanguage,
  })  : _getAvailableLanguages = getAvailableLanguages,
        _getSelectedLanguage = getSelectedLanguage,
        _selectLanguage = selectLanguage,
        super(const LanguageSelectionState()) {
    on<LanguageSelectionStarted>(_onStarted, transformer: restartable());
    on<LanguageChanged>(_onLanguageChanged, transformer: sequential());
    on<LanguageSelectionSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetAvailableLanguagesUseCase _getAvailableLanguages;
  final GetSelectedLanguageUseCase _getSelectedLanguage;
  final SelectLanguageUseCase _selectLanguage;

  void _onStarted(
    LanguageSelectionStarted event,
    Emitter<LanguageSelectionState> emit,
  ) {
    emit(
      state.copyWith(
        status: LanguageSelectionStatus.ready,
        languages: _getAvailableLanguages(),
        selectedLanguage: _getSelectedLanguage(),
      ),
    );
  }

  void _onLanguageChanged(
    LanguageChanged event,
    Emitter<LanguageSelectionState> emit,
  ) {
    emit(state.copyWith(selectedLanguage: event.language));
  }

  void _onSubmitted(
    LanguageSelectionSubmitted event,
    Emitter<LanguageSelectionState> emit,
  ) {
    _selectLanguage(state.selectedLanguage);
    emit(state.copyWith(status: LanguageSelectionStatus.submitted));
  }
}
