import 'package:archonex_converter/project_files/features/media_converter/domain/models/conversion_update.dart';

/// A conversion that is already running.
///
/// Modelled as a handle rather than a plain `Future` so the UI can show
/// progress and stop the work — which is what a real FFmpeg session or a
/// backend job would expose as well.
abstract interface class ConversionJob {
  /// Emits [ConversionProgress] until it emits a single [ConversionCompleted]
  /// and closes. Errors arrive as `ConversionFailure`.
  Stream<ConversionUpdate> get updates;

  /// Stops the work. [updates] then fails with `ConversionCancelledFailure`.
  Future<void> cancel();
}
