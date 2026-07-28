import 'package:archonex_converter/project_files/features/file_converters/domain/models/converter_tool.dart';

/// Contract for reading the converter catalogue.
abstract interface class FileConvertersRepo {
  List<ConverterTool> getConverters();
}
