import 'package:archonex_converter/project_files/features/pdf_converter/data/engine/dart_pdf_converter_repo.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/data/file_access/io_pdf_file_repo.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_converter_repo.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/domain/pdf_file_repo.dart';

/// Android, iOS, macOS, Windows and Linux.
///
/// Unlike the media and image converters there is no platform to exclude here:
/// the engine is pure Dart plus PDFium, both of which ship everywhere the app
/// has a file system.
PdfConverterRepo createPdfConverterRepo() => const DartPdfConverterRepo();

PdfFileRepo createPdfFileRepo() => const IoPdfFileRepo();
