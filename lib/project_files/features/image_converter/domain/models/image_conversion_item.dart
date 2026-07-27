import 'package:equatable/equatable.dart';

import 'package:archonex/project_files/features/converter_shared/domain/models/conversion_failure.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/converted_file.dart';
import 'package:archonex/project_files/features/converter_shared/domain/models/source_file.dart';

/// Where one photo has got to inside a batch.
enum ImageItemStatus { pending, converting, done, failed }

/// One photo in the batch, together with whatever became of it.
///
/// A failure lives on the item rather than on the batch: one unreadable photo
/// out of thirty should mark itself and let the other twenty-nine through.
class ImageConversionItem extends Equatable {
  const ImageConversionItem({
    required this.source,
    this.status = ImageItemStatus.pending,
    this.result,
    this.failure,
  });

  final SourceFile source;
  final ImageItemStatus status;

  /// Set once [status] is [ImageItemStatus.done].
  final ConvertedFile? result;

  /// Set once [status] is [ImageItemStatus.failed].
  final ConversionFailure? failure;

  ImageConversionItem copyWith({
    ImageItemStatus? status,
    ConvertedFile? result,
    ConversionFailure? failure,
    bool clearResult = false,
    bool clearFailure = false,
  }) {
    return ImageConversionItem(
      source: source,
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  /// Back to the untouched state, dropping whatever the last run produced.
  ImageConversionItem reset() => ImageConversionItem(source: source);

  @override
  List<Object?> get props => <Object?>[source, status, result, failure];
}
