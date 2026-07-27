import 'package:flutter/material.dart';

import 'package:archonex_converter/core/constants/app_spacing.dart';
import 'package:archonex_converter/project_files/features/language_selection/domain/models/app_language.dart';
import 'package:archonex_converter/project_files/features/language_selection/ui/widgets/language_tile.dart';

typedef LanguageSelectedCallback = void Function(AppLanguage language);

/// Scrollable list of selectable language tiles.
class LanguageList extends StatelessWidget {
  const LanguageList({
    required this.languages,
    required this.selectedLanguage,
    required this.onLanguageSelected,
    super.key,
  });

  final List<AppLanguage> languages;
  final AppLanguage selectedLanguage;
  final LanguageSelectedCallback onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: languages.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final AppLanguage language = languages[index];

        return LanguageTile(
          language: language,
          isSelected: language == selectedLanguage,
          onTap: () => onLanguageSelected(language),
        );
      },
    );
  }
}
