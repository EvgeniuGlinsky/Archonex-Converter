import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_converter_repo.dart';

/// Whether this platform can convert at all.
class GetPdfConverterAvailabilityUseCase {
  const GetPdfConverterAvailabilityUseCase(this._repo);

  final PdfConverterRepo _repo;

  bool call() => _repo.isSupported;
}
