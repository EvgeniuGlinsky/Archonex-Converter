import 'package:archonex/project_files/features/media_converter/domain/media_converter_repo.dart';

/// Whether this build has a conversion engine behind it.
class GetConverterAvailabilityUseCase {
  const GetConverterAvailabilityUseCase(this._repo);

  final MediaConverterRepo _repo;

  bool call() => _repo.isSupported;
}
