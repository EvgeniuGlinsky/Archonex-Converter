import 'package:archonex/project_files/features/language_selection/domain/language_repo.dart';
import 'package:archonex/project_files/features/language_selection/domain/models/app_language.dart';

class GetAvailableLanguagesUseCase {
  const GetAvailableLanguagesUseCase(this._repo);

  final LanguageRepo _repo;

  List<AppLanguage> call() => _repo.getAvailableLanguages();
}
