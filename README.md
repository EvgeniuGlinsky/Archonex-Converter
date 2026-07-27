# Archonex

[![CI](https://github.com/EvgeniuGlinsky/Archonex/actions/workflows/ci.yml/badge.svg)](https://github.com/EvgeniuGlinsky/Archonex/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A Flutter application that bundles a set of everyday tools behind one launcher. The tools are grouped into categories — file converters, utilities, a library of apps and a news section — and the one that carries real weight today is the **media converter**: a local, offline audio/video converter built on FFmpeg.

Nothing leaves the device. Conversion runs through a bundled FFmpeg binary, not a remote service.

## Status

The media converter is implemented end to end. `utilities`, `library_apps` and `news_apps` are routed and reachable but still render a placeholder — they are scaffolding for what comes next, not finished screens.

## Platform support

All six Flutter runners are present, but conversion is only available where an FFmpeg engine ships:

| Platform | Conversion | Size ceiling | Why |
| --- | --- | --- | --- |
| Android | yes | 512 MB | Result crosses the platform channel as a Java `byte[]` — length is a signed 32-bit int |
| iOS | yes | 1 GB | Result crosses as `NSData`; the binding limit is Flutter's message codec |
| Windows / macOS | yes | 4 GB | FFmpeg streams by path, nothing is ever resident — the limit is a product choice, not a constraint |
| Linux / Web | no | — | No conversion engine; the screen says so up front |

The offered ceiling is 30% of each platform's technical maximum, deliberately leaving headroom — the technical maximum is where things break, not where they work well. All of this lives in one place, `lib/core/constants/app_file_limits.dart`, with the reasoning written down next to each number.

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
│   ├── constants/                   # spacing, radius, durations, breakpoints, strings, file limits
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

### Where the media converter lives

`lib/project_files/features/media_converter/` is the reference implementation of the pattern:

- `domain/` — `MediaConverterRepo`, `MediaFileRepo` and the models (`ConversionJob`, `ConversionSettings`, `MediaFormat`, `ConversionFailure`, …)
- `data/ffmpeg/` — command builder, duration parser, progress and error classification, plus an `unsupported_*` repo used on platforms with no engine
- `data/file_access/` — picking a source and saving a result
- `data/platform/` — the io/web split
- `data/use_cases/` — one file per action: pick, convert, save, discard, check availability
- `ui/` — `MediaConverterBloc` and the widget tree

## Tests

```bash
flutter analyze
flutter test
```

`test/` holds unit and widget tests, concentrated on the media converter: the FFmpeg command builder, duration parser and error classifier, every use case, the BLoC, and a view test. Fakes live in `test/features/media_converter/fakes.dart`.

`integration_test/` is separate and is **not** part of CI — it needs a real device:

```bash
flutter test integration_test/capacity_probe_test.dart -d <device-id>
```

The capacity probe measures the actual per-device conversion and save ceilings, so the numbers in `app_file_limits.dart` can eventually be replaced by measured ones rather than derived ones.

## CI

`.github/workflows/ci.yml` runs `flutter analyze` and `flutter test` on every push to `main` and on every pull request.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
