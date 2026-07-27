# Archonex Converter

[![CI](https://github.com/EvgeniuGlinsky/Archonex-Converter/actions/workflows/ci.yml/badge.svg)](https://github.com/EvgeniuGlinsky/Archonex-Converter/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A free, offline file converter with no artificial size limits — convert files at the full technical ceiling of the platform, not a discounted fraction of it. Today that means the **media converter** (audio, video and animation) and the **image converter** (photos, in batches); a **document converter** is on the catalogue but not built yet. Both built converters run entirely on-device, on a bundled FFmpeg binary.

Nothing leaves the device. Conversion runs through a bundled FFmpeg binary, not a remote service.

## Status

The media and image converters are implemented end to end. The document converter is listed in the catalogue but not built — the app is deliberately scoped to converters only, with no other product categories.

HEIC and AVIF are listed as read-only sources in the image converter: no encoder for them ships in the bundled FFmpeg build, and whether the *decoders* are present depends on that build. `integration_test/ffmpeg_capability_probe_test.dart` is what answers that per device.

## Platform support

All six Flutter runners are present, but conversion is only available where an FFmpeg engine ships:

| Platform | Conversion | Size ceiling | Why |
| --- | --- | --- | --- |
| Android | yes | 2 GB | Result crosses the platform channel as a Java `byte[]` — length is a signed 32-bit int |
| iOS | yes | 4 GB | Result crosses as `NSData`; the binding limit is Flutter's message codec |
| Windows / macOS | yes | 1 TB (no real ceiling) | FFmpeg streams by path, nothing is ever resident — there is no architectural limit at all |
| Linux / Web | no | — | No conversion engine; the screen says so up front |

Every ceiling above is the platform's real technical maximum, not a discounted offering — there is no free/paid split by file size. Pushing mobile to that raw ceiling trades away a safety margin: saving a result can hold 2–3× its size resident in memory, so very large files risk an out-of-memory crash on real devices. `integration_test/capacity_probe_test.dart` exists to measure a safer, per-device number if that turns out to bite. All of this lives in one place, `lib/core/constants/app_file_limits.dart`, with the reasoning written down next to each number. A future paid tier is planned to gate by **file count**, not size — that is not built yet.

The image converter adds a second ceiling, on how many photos one batch may hold: 30 on mobile, 100 on desktop. Unlike the byte limits this one is a product choice on every platform — files are converted one at a time, so nothing in the stack caps the count.

## Stack

- Flutter (stable channel), Dart SDK `^3.10.0`
- [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) + [`bloc_concurrency`](https://pub.dev/packages/bloc_concurrency) — state management
- [`go_router`](https://pub.dev/packages/go_router) — routing
- [`equatable`](https://pub.dev/packages/equatable) — value equality
- [`file_picker`](https://pub.dev/packages/file_picker) — picking sources and saving results
- [`ffmpeg_kit_flutter_new`](https://pub.dev/packages/ffmpeg_kit_flutter_new) — the conversion engine

## Getting started

```bash
flutter pub get
flutter run
```

Requires the Flutter stable channel. The pinned revision this project was last verified against is recorded in `.metadata`.

## Architecture

```
lib/
├── main.dart                        # runApp(ArchonexApp()) — nothing else
├── core/
│   ├── app/                         # root widget
│   ├── constants/                   # spacing, radius, durations, breakpoints, file limits
│   ├── router/                      # AppRoute enum + GoRouter config
│   ├── theme/
│   ├── utils/
│   └── widgets/                     # shared building blocks
└── project_files/features/<feature>/
    ├── data/                        # repo implementations, use cases, platform adapters
    ├── domain/                      # repo interfaces + models — no Flutter imports
    └── ui/                          # page, view, bloc/, widgets/, mappers/
```

Every feature follows the same three-layer split. `domain` declares interfaces and models and depends on nothing; `data` implements them; `ui` holds the BLoC and widgets and talks to `domain` only. Each screen is a `*_page.dart` (wires up the BLoC) plus a `*_view.dart` (pure presentation), which is what keeps widget tests able to drive a view without standing up the whole app.

Routing has one source of truth: the `AppRoute` enum in `lib/core/router/app_route.dart`, where the enum entry name doubles as the GoRouter route name.

**Before adding or changing a feature, read [`.claude/skills/flutter-feature/SKILL.md`](.claude/skills/flutter-feature/SKILL.md).** It is the mandatory standard for file structure, naming and coding style in this repository, not a suggestion.

### Where the converters live

`lib/project_files/features/media_converter/` is the reference implementation of the pattern:

- `domain/` — `MediaConverterRepo`, `MediaFileRepo` and the models (`ConversionJob`, `ConversionSettings`, `MediaFormat`, …)
- `data/ffmpeg/` — command builder, duration parser, progress classification, plus an `unsupported_*` repo used on platforms with no engine
- `data/file_access/` — picking a source and saving a result
- `data/platform/` — the io/web split
- `data/use_cases/` — one file per action: pick, convert, save, discard, check availability
- `ui/` — `MediaConverterBloc` and the widget tree

`lib/project_files/features/image_converter/` mirrors it for photos. The difference that shapes everything else is that it works on a **batch**: state is a list of `ImageConversionItem`s, progress is the fraction of the batch that has finished rather than a fraction of one file, and a failure on one photo lives on that photo's row instead of ending the run.

`lib/project_files/features/converter_shared/` holds what both of them need, laid out in the same three layers:

- `domain/models/` — `ConversionFailure` (one sealed hierarchy for every converter), `SourceFile`, `ConvertedFile`, `SaveResult`, `NormalizedQuality`
- `data/ffmpeg/` — the error classifier, the quality-scale mapping and the filter fragments
- `data/file_access/` — the picker and the writer, including the batch save that falls back to one dialog per file when a chosen folder turns out to be unwritable
- `ui/` — the failure-to-copy mapper and the widgets both screens render

A converter-specific model stays in its own feature: `MediaFormat` and `ImageFormat` answer different questions and are deliberately not one enum.

## Tests

```bash
flutter analyze
flutter test
```

`test/` holds unit and widget tests, concentrated on the two converters: the FFmpeg command builders, the duration parser and error classifier, every use case, both BLoCs, and a view test each. Fakes are hand written, one file per feature (`test/features/<feature>/fakes.dart`) — there is no mocking package.

`integration_test/` is separate and is **not** part of CI — it needs a real device:

```bash
flutter test integration_test/capacity_probe_test.dart -d <device-id>
flutter test integration_test/ffmpeg_capability_probe_test.dart -d <device-id>
```

The capacity probe measures the actual per-device conversion and save ceilings, so the numbers in `app_file_limits.dart` can eventually be replaced by measured ones rather than derived ones. The capability probe reports which encoders and decoders the bundled FFmpeg actually has, which is the only way to check that `ImageFormat.canEncode` is telling the truth on the platform that ships it. Run it again after any `ffmpeg_kit_flutter_new` upgrade.

## CI

`.github/workflows/ci.yml` runs `flutter analyze` and `flutter test` on every push to `main` and on every pull request.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
