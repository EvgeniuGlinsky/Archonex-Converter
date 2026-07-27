import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/project_files/features/converter_shared/data/ffmpeg/ffmpeg_error_classifier.dart';
import 'package:archonex_converter/project_files/features/converter_shared/domain/models/conversion_failure.dart';

void main() {
  late FfmpegErrorClassifier classifier;

  setUp(
    () => classifier = FfmpegErrorClassifier(
      missingStreamFailure: const NoAudioTrackFailure(),
    ),
  );

  test('says nothing about output that reports no problem', () {
    classifier.add('frame=  100 fps=25 q=28.0 size=512kB');

    expect(classifier.classify(), isNull);
  });

  test('recognises a source with no audio track', () {
    classifier.add("Stream map '0:a:0' matches no streams.");

    expect(classifier.classify(), isA<NoAudioTrackFailure>());
  });

  test('recognises the marker even when it arrives in fragments', () {
    // FFmpeg delivers each av_log argument separately, so a marker is
    // routinely split across two callbacks.
    classifier
      ..add("Stream map '0:a:0' ")
      ..add('matches no streams.');

    expect(classifier.classify(), isA<NoAudioTrackFailure>());
  });

  test('recognises an unreadable source', () {
    classifier.add('Invalid data found when processing input');

    expect(classifier.classify(), isA<CorruptSourceFailure>());
  });

  test('recognises a full disk', () {
    classifier.add('av_interleaved_write_frame(): No space left on device');

    expect(classifier.classify(), isA<InsufficientStorageFailure>());
  });

  test('matches whatever the casing of the message', () {
    classifier.add('MOOV ATOM NOT FOUND');

    expect(classifier.classify(), isA<CorruptSourceFailure>());
  });

  test('keeps the tail, so a marker after a long run still lands', () {
    for (int i = 0; i < 500; i++) {
      classifier.add('frame=  100 fps=25 q=28.0 size=512kB time=00:00:04.00 ');
    }
    classifier.add('Output file does not contain any stream');

    expect(classifier.classify(), isA<NoAudioTrackFailure>());
  });
}
