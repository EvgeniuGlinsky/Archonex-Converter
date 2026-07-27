import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/project_files/features/file_converters/domain/file_converters_repo.dart';
import 'package:archonex/project_files/features/file_converters/domain/models/converter_tool.dart';

/// Static catalogue for now — becomes a remote or config driven source later.
///
/// Only [ConverterToolType.media] is built; the rest are listed so the roadmap
/// is visible from inside the app. There is no separate audio entry: the media
/// converter already takes audio in and out.
class FileConvertersRepoImpl implements FileConvertersRepo {
  const FileConvertersRepoImpl();

  static const List<ConverterTool> _converters = <ConverterTool>[
    ConverterTool(
      type: ConverterToolType.media,
      title: AppStrings.mediaConverter,
      subtitle: AppStrings.mediaConverterSubtitle,
      isAvailable: true,
    ),
    ConverterTool(
      type: ConverterToolType.image,
      title: AppStrings.imageConverter,
      subtitle: AppStrings.imageConverterSubtitle,
      isAvailable: false,
    ),
    ConverterTool(
      type: ConverterToolType.document,
      title: AppStrings.documentConverter,
      subtitle: AppStrings.documentConverterSubtitle,
      isAvailable: false,
    ),
  ];

  @override
  List<ConverterTool> getConverters() => _converters;
}
