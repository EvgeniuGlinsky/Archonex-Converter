import 'package:archonex_converter/project_files/features/image_converter/data/ffmpeg/ffmpeg_image_converter_repo.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/file_access/io_image_file_repo.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/image_converter_repo.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/image_file_repo.dart';

/// Android, iOS, macOS, Windows and Linux.
///
/// The FFmpeg engine reports Linux as unsupported itself — see
/// `FfmpegImageConverterRepo.isSupported`.
ImageConverterRepo createImageConverterRepo() =>
    const FfmpegImageConverterRepo();

ImageFileRepo createImageFileRepo() => const IoImageFileRepo();
