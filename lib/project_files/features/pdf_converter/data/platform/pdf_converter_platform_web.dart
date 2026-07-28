import 'package:archonex_converter/project_files/features/pdf_converter/data/engine/unsupported_pdf_converter_repo.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/file_access/unsupported_pdf_file_repo.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_converter_repo.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_file_repo.dart';

/// Web, where the engine has no file system to write into.
PdfConverterRepo createPdfConverterRepo() => const UnsupportedPdfConverterRepo();

PdfFileRepo createPdfFileRepo() => const UnsupportedPdfFileRepo();
