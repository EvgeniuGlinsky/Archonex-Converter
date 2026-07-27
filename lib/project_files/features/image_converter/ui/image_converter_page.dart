import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/project_files/features/image_converter/data/platform/image_converter_platform.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/convert_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/discard_converted_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/get_image_converter_availability_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/pick_source_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/save_all_converted_images_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/data/use_cases/save_converted_image_use_case.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/image_converter_repo.dart';
import 'package:archonex_converter/project_files/features/image_converter/domain/image_file_repo.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/bloc/image_converter_bloc.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/image_converter_view.dart';

/// Wires the image converter dependencies. No UI lives here.
///
/// Which implementations arrive is decided by the platform boundary in
/// `data/platform/image_converter_platform.dart`, not by this file.
class ImageConverterPage extends StatelessWidget {
  const ImageConverterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ImageConverterRepo converterRepo = createImageConverterRepo();
    final ImageFileRepo imageFileRepo = createImageFileRepo();

    return BlocProvider<ImageConverterBloc>(
      create: (_) => ImageConverterBloc(
        getConverterAvailability:
            GetImageConverterAvailabilityUseCase(converterRepo),
        pickSourceImages: PickSourceImagesUseCase(imageFileRepo),
        convertImages: ConvertImagesUseCase(converterRepo),
        saveConvertedImage: SaveConvertedImageUseCase(imageFileRepo),
        saveAllConvertedImages: SaveAllConvertedImagesUseCase(imageFileRepo),
        discardConvertedImages: DiscardConvertedImagesUseCase(converterRepo),
      )..add(const ImageConverterStarted()),
      child: const ImageConverterView(),
    );
  }
}
