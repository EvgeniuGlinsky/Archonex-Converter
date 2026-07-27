import 'package:archonex/project_files/features/category_selection/domain/category_repo.dart';
import 'package:archonex/project_files/features/category_selection/domain/models/app_category.dart';

class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repo);

  final CategoryRepo _repo;

  List<AppCategory> call() => _repo.getCategories();
}
