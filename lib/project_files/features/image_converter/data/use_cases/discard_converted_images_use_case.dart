import 'package:archonex_converter/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/image_converter_repo.dart';

/// Releases results the user will never see.
///
/// Every batch writes into its own temporary directory, so without this the app
/// would leave one behind per run — and a batch directory holds thirty files,
/// not one.
class DiscardConvertedImagesUseCase {
  const DiscardConvertedImagesUseCase(this._repo);

  final ImageConverterRepo _repo;

  Future<void> call(List<ConvertedFile> files) =>
      files.isEmpty ? Future<void>.value() : _repo.discard(files);
}
