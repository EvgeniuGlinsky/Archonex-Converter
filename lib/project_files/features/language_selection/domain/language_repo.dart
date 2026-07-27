import 'package:flutter/foundation.dart';

import 'package:archonex/project_files/features/language_selection/domain/models/app_language.dart';

/// Contract for reading and storing the app language.
abstract interface class LanguageRepo {
  List<AppLanguage> getAvailableLanguages();

  AppLanguage getSelectedLanguage();

  void selectLanguage(AppLanguage language);

  /// Notifies listeners whenever [selectLanguage] changes the selection, so
  /// the app root can rebuild with the new `Locale` without the bloc having
  /// to know that a locale exists at all.
  ValueListenable<AppLanguage> get selectedLanguageListenable;
}
