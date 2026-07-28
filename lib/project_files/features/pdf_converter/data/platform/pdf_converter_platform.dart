/// Picks the data layer that fits the platform the app was compiled for.
///
/// The PDF engine reads and writes real files, so it needs `dart:io`. Web gets
/// the unsupported pair instead, and callers only ever see the two factory
/// functions:
///
/// * `createPdfConverterRepo()`
/// * `createPdfFileRepo()`
library;

export 'pdf_converter_platform_web.dart'
    if (dart.library.io) 'pdf_converter_platform_io.dart';
