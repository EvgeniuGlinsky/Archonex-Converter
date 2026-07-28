import 'package:archonex_converter/project_files/features/file_converters/domain/file_converters_repo.dart';
import 'package:archonex_converter/project_files/features/file_converters/domain/models/converter_tool.dart';

/// Static catalogue for now — becomes a remote or config driven source later.
///
/// Everything listed is built: an entry with `isAvailable: false` is still
/// supported by the tile, but nothing is on the roadmap far enough along to
/// show. There is no separate audio entry either — the media converter already
/// takes audio in and out.
class FileConvertersRepoImpl implements FileConvertersRepo {
  const FileConvertersRepoImpl();

  static const List<ConverterTool> _converters = <ConverterTool>[
    ConverterTool(type: ConverterToolType.media, isAvailable: true),
    ConverterTool(type: ConverterToolType.image, isAvailable: true),
    ConverterTool(type: ConverterToolType.pdf, isAvailable: true),
  ];

  @override
  List<ConverterTool> getConverters() => _converters;
}
