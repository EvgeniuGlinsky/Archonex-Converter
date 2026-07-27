import 'package:archonex/project_files/features/language_selection/domain/models/app_language.dart';

/// Contract for reading and storing the app language.
abstract interface class LanguageRepo {
  List<AppLanguage> getAvailableLanguages();

  AppLanguage getSelectedLanguage();

  void selectLanguage(AppLanguage language);
}
