import 'package:archonex_converter/project_files/features/language_selection/domain/language_repo.dart';
import 'package:archonex_converter/project_files/features/language_selection/domain/models/app_language.dart';

class GetSelectedLanguageUseCase {
  const GetSelectedLanguageUseCase(this._repo);

  final LanguageRepo _repo;

  AppLanguage call() => _repo.getSelectedLanguage();
}
