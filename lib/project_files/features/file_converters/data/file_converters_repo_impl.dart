import 'package:archonex/project_files/features/file_converters/domain/file_converters_repo.dart';
import 'package:archonex/project_files/features/file_converters/domain/models/converter_tool.dart';

/// Static catalogue for now — becomes a remote or config driven source later.
///
/// The document converter is listed while unbuilt so the roadmap is visible
/// from inside the app. There is no separate audio entry: the media converter
/// already takes audio in and out.
class FileConvertersRepoImpl implements FileConvertersRepo {
  const FileConvertersRepoImpl();

  static const List<ConverterTool> _converters = <ConverterTool>[
    ConverterTool(type: ConverterToolType.media, isAvailable: true),
    ConverterTool(type: ConverterToolType.image, isAvailable: true),
    ConverterTool(type: ConverterToolType.document, isAvailable: false),
  ];

  @override
  List<ConverterTool> getConverters() => _converters;
}
