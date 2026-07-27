import 'package:archonex/project_files/features/image_converter/domain/image_converter_repo.dart';

/// Whether this build has a conversion engine behind it.
class GetImageConverterAvailabilityUseCase {
  const GetImageConverterAvailabilityUseCase(this._repo);

  final ImageConverterRepo _repo;

  bool call() => _repo.isSupported;
}
