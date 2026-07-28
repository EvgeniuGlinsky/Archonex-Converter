import 'package:archonex_converter/project_files/features/media_converter/data/ffmpeg/unsupported_media_converter_repo.dart';
import 'package:archonex_converter/project_files/features/media_converter/data/file_access/unsupported_media_file_repo.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/media_converter_repo.dart';
import 'package:archonex_converter/project_files/features/media_converter/domain/media_file_repo.dart';

/// Web. FFmpeg is not available in the browser, so the screen explains that
/// instead of offering a conversion it cannot run.
MediaConverterRepo createMediaConverterRepo() =>
    const UnsupportedMediaConverterRepo();

MediaFileRepo createMediaFileRepo() => const UnsupportedMediaFileRepo();
