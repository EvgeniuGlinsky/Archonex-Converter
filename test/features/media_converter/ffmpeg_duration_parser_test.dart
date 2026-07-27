import 'package:flutter_test/flutter_test.dart';

import 'package:archonex/project_files/features/media_converter/data/ffmpeg/ffmpeg_duration_parser.dart';

void main() {
  late FfmpegDurationParser parser;

  setUp(() => parser = FfmpegDurationParser());

  test('reports nothing until a duration has been seen', () {
    parser.add('ffmpeg version 8.1.2 Copyright (c) the FFmpeg developers');

    expect(parser.durationMs, isNull);
  });

  test('reads a duration out of one log line', () {
    parser.add('  Duration: 00:01:00.37, start: 0.000000, bitrate: 1234 kb/s');

    expect(parser.durationMs, 60370);
  });

  test('reads a duration split across fragments', () {
    // FFmpeg hands over each av_log argument separately, so the header
    // routinely arrives in pieces.
    parser
      ..add('  Duration: ')
      ..add('00:00:02.50')
      ..add(', start: 0.000000');

    expect(parser.durationMs, 2500);
  });

  test('pads a short fraction so .4 reads as 400 ms', () {
    parser.add('Duration: 00:00:01.4,');

    expect(parser.durationMs, 1400);
  });

  test('counts hours and minutes into the total', () {
    parser.add('Duration: 01:02:03.00,');

    expect(parser.durationMs, ((1 * 60 + 2) * 60 + 3) * 1000);
  });

  test('never matches an input that reports no duration', () {
    parser.add('  Duration: N/A, start: 0.000000, bitrate: N/A');

    expect(parser.durationMs, isNull);
  });

  test('gives up rather than buffering a whole conversion', () {
    for (int i = 0; i < 100; i++) {
      parser.add('frame=  100 fps=25 q=28.0 size=    512kB time=00:00:04.00 ');
    }

    // The header is long gone by now; a duration arriving this late is noise.
    parser.add('Duration: 00:01:00.00,');

    expect(parser.durationMs, isNull);
  });

  test('keeps the first duration it saw, ignoring the output header', () {
    parser
      ..add('Duration: 00:00:10.00,')
      ..add('Duration: 00:05:00.00,');

    expect(parser.durationMs, 10000);
  });
}
