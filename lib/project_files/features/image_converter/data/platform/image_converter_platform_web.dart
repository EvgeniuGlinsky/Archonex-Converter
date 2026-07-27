import 'package:archonex_converter/project_files/features/image_converter/data/ffmpeg/unsupported_image_converter_repo.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/file_access/unsupported_image_file_repo.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/image_converter_repo.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/image_file_repo.dart';

/// Web. FFmpeg is not available in the browser, so the screen explains that
/// instead of offering a conversion it cannot run.
ImageConverterRepo createImageConverterRepo() =>
    const UnsupportedImageConverterRepo();

ImageFileRepo createImageFileRepo() => const UnsupportedImageFileRepo();
