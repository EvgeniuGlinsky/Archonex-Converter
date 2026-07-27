import 'package:flutter/foundation.dart';

import 'package:archonex_converter/project_files/features/language_selection/domain/language_repo.dart';
import 'package:archonex_converter/project_files/features/language_selection/domain/models/app_language.dart';

/// In-memory implementation. Swap the storage here when persistence lands —
/// nothing above this layer changes.
class LanguageRepoImpl implements LanguageRepo {
  final ValueNotifier<AppLanguage> _selectedLanguage =
      ValueNotifier<AppLanguage>(AppLanguage.english);

  @override
  List<AppLanguage> getAvailableLanguages() => AppLanguage.values;

  @override
  AppLanguage getSelectedLanguage() => _selectedLanguage.value;

  @override
  void selectLanguage(AppLanguage language) =>
      _selectedLanguage.value = language;

  @override
  ValueListenable<AppLanguage> get selectedLanguageListenable =>
      _selectedLanguage;
}
