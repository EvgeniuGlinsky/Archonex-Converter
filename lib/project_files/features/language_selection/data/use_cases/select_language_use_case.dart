import 'package:archonex_converter/project_files/features/language_selection/domain/language_repo.dart';
import 'package:archonex_converter/project_files/features/language_selection/domain/models/app_language.dart';

class SelectLanguageUseCase {
  const SelectLanguageUseCase(this._repo);

  final LanguageRepo _repo;

  void call(AppLanguage language) => _repo.selectLanguage(language);
}
