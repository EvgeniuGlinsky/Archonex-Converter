import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex/project_files/features/language_selection/data/use_cases/get_available_languages_use_case.dart';
import 'package:archonex/project_files/features/language_selection/data/use_cases/get_selected_language_use_case.dart';
import 'package:archonex/project_files/features/language_selection/data/use_cases/select_language_use_case.dart';
import 'package:archonex/project_files/features/language_selection/domain/language_repo.dart';
import 'package:archonex/project_files/features/language_selection/ui/bloc/language_selection_bloc.dart';
import 'package:archonex/project_files/features/language_selection/ui/language_selection_view.dart';

/// Wires the language selection dependencies. No UI lives here.
class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final LanguageRepo repo = context.read<LanguageRepo>();

    return BlocProvider<LanguageSelectionBloc>(
      create: (_) => LanguageSelectionBloc(
        getAvailableLanguages: GetAvailableLanguagesUseCase(repo),
        getSelectedLanguage: GetSelectedLanguageUseCase(repo),
        selectLanguage: SelectLanguageUseCase(repo),
      )..add(const LanguageSelectionStarted()),
      child: const LanguageSelectionView(),
    );
  }
}
