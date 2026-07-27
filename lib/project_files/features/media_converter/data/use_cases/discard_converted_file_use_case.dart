import 'package:archonex/project_files/features/media_converter/domain/media_converter_repo.dart';
import 'package:archonex/project_files/features/media_converter/domain/models/converted_file.dart';

/// Releases a conversion result the user will never see.
///
/// Every conversion writes to its own temporary directory, so without this the
/// app would leave one behind per run.
class DiscardConvertedFileUseCase {
  const DiscardConvertedFileUseCase(this._repo);

  final MediaConverterRepo _repo;

  Future<void> call(ConvertedFile file) => _repo.discard(file);
}
