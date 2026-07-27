import 'package:archonex/project_files/features/language_selection/domain/language_repo.dart';
import 'package:archonex/project_files/features/language_selection/domain/models/app_language.dart';

/// In-memory implementation. Swap the storage here when persistence lands —
/// nothing above this layer changes.
class LanguageRepoImpl implements LanguageRepo {
  AppLanguage _selectedLanguage = AppLanguage.english;

  @override
  List<AppLanguage> getAvailableLanguages() => AppLanguage.values;

  @override
  AppLanguage getSelectedLanguage() => _selectedLanguage;

  @override
  void selectLanguage(AppLanguage language) => _selectedLanguage = language;
}
