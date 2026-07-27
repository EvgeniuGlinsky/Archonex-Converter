import 'package:archonex/project_files/features/image_converter/domain/models/image_conversion_update.dart';

/// A batch conversion that is already running.
///
/// Modelled as a handle rather than a plain `Future` so the UI can follow the
/// queue and stop it part way, which is what a real FFmpeg run or a backend job
/// would expose as well.
abstract interface class ImageConversionJob {
  /// Emits one update per photo as the queue works through it, then closes.
  ///
  /// The stream closing is what says the batch is over — individual failures
  /// arrive as [ImageItemFailed] and do not end it. A cancellation, and only a
  /// cancellation, ends the stream with a `ConversionCancelledFailure`.
  Stream<ImageConversionUpdate> get updates;

  /// Stops the queue. Whatever was already produced is discarded with it.
  Future<void> cancel();
}
