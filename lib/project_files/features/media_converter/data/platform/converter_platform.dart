/// Picks the data layer that fits the platform the app was compiled for.
///
/// `ffmpeg_kit_flutter_new` reaches for `dart:io`, so importing it from code
/// that also compiles to web breaks the web build outright. Everything that
/// touches it therefore lives behind this one boundary, and callers only ever
/// see the two factory functions below:
///
/// * `createMediaConverterRepo()`
/// * `createMediaFileRepo()`
library;

export 'converter_platform_web.dart'
    if (dart.library.io) 'converter_platform_io.dart';
