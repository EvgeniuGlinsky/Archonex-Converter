import 'package:archonex/project_files/features/media_converter/data/ffmpeg/ffmpeg_media_converter_repo.dart';
import 'package:archonex/project_files/features/media_converter/data/file_access/io_media_file_repo.dart';
import 'package:archonex/project_files/features/media_converter/domain/media_converter_repo.dart';
import 'package:archonex/project_files/features/media_converter/domain/media_file_repo.dart';

/// Android, iOS, macOS, Windows and Linux.
///
/// The FFmpeg engine reports Linux as unsupported itself — see
/// `FfmpegMediaConverterRepo.isSupported`.
MediaConverterRepo createMediaConverterRepo() =>
    const FfmpegMediaConverterRepo();

MediaFileRepo createMediaFileRepo() => const IoMediaFileRepo();
