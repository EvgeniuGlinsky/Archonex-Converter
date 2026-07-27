import 'package:archonex_converter/project_files/features/file_converters/domain/file_converters_repo.dart';
import 'package:archonex_converter/project_files/features/file_converters/domain/models/converter_tool.dart';

class GetConvertersUseCase {
  const GetConvertersUseCase(this._repo);

  final FileConvertersRepo _repo;

  List<ConverterTool> call() => _repo.getConverters();
}
