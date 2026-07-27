import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/media_converter/domain/media_converter_repo.dart';

/// Releases a conversion result the user will never see.
///
/// Every conversion writes to its own temporary directory, so without this the
/// app would leave one behind per run.
class DiscardConvertedFileUseCase {
  const DiscardConvertedFileUseCase(this._repo);

  final MediaConverterRepo _repo;

  Future<void> call(ConvertedFile file) => _repo.discard(file);
}
