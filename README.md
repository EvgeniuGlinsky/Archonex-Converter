# Archonex Converter

[![CI](https://github.com/EvgeniuGlinsky/Archonex-Converter/actions/workflows/ci.yml/badge.svg)](https://github.com/EvgeniuGlinsky/Archonex-Converter/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

An offline file converter with no artificial size limits — convert files at the full technical ceiling of the platform, not a discounted fraction of it. The free tier is bounded by **how many files** you convert, never by how large they are: ten source files a month, and a subscription lifts the count. Three converters ship today:

- **Media converter** — audio, video and animation, on FFmpeg.
- **Image converter** — photos, in batches, on FFmpeg.
- **PDF converter** — photos or text into a PDF, and a PDF back out as one image per page. No FFmpeg involved.

Nothing leaves the device. Everything runs on a bundled engine, never a remote service.

## Status

All three converters are implemented end to end, and the free tier is enforced. The app is deliberately scoped to converters only, with no other product categories.

**Office documents are not supported, and are not planned.** DOCX, XLSX and PPTX to PDF with any layout fidelity has no mature offline Dart path; every alternative is either a cloud API, which would break the promise above, or a bundled LibreOffice. The PDF converter is named after what it actually does rather than after what people wish it did.

Two other honest limits worth knowing:

- **Text to PDF covers Latin, Greek and Cyrillic**, the coverage of the embedded Noto Sans. Chinese, Japanese and Korean are refused with a clear message rather than written out as a page of blank boxes — which is what the fonts built into the `pdf` package do, silently.
- **HEIC and AVIF are read-only sources** in the image converter: no encoder for them ships in the bundled FFmpeg build, and whether the *decoders* are present depends on that build. `integration_test/ffmpeg_capability_probe_test.dart` answers that per device.

## Roadmap

Not built, in rough order of how well each fits what is already here:

| Idea | Notes |
| --- | --- |
| Archive converter | ZIP ↔ TAR ↔ TAR.GZ ↔ TAR.BZ2 through the pure-Dart `archive` package. No native dependency. RAR and 7z cannot be *created* — both are proprietary. |
| Subtitle converter | SRT ↔ VTT ↔ ASS. Nearly free: FFmpeg is already bundled and already does this. |
| Data format converter | CSV ↔ JSON ↔ XML ↔ YAML. Trivial in pure Dart, but aimed at developers rather than at the audience the rest of the app serves. |

The paid tier is built, billed and described below. What is still missing there is delivery of a licence key by email — today the key is shown on the page the buyer returns to after paying.

## Platform support

All six Flutter runners are present, but which converters work depends on which engines ship:

| Platform | Media / Image | PDF | Size ceiling | Why that ceiling |
| --- | --- | --- | --- | --- |
| Android | yes | yes | 2 GB | Result crosses the platform channel as a Java `byte[]` — length is a signed 32-bit int |
| iOS | yes | yes | 4 GB | Result crosses as `NSData`; the binding limit is Flutter's message codec |
| Windows / macOS | yes | yes | 1 TB (no real ceiling) | Nothing is ever resident — the save is an OS-level copy |
| Linux | no | yes | 1 TB (no real ceiling) | No FFmpeg engine ships, but the PDF converter needs none |
| Web | no | no | — | No file system to write into; the screen says so up front |

Engine availability and the size ceiling are two separate questions, and `AppFileLimits` answers only the second. Whether a given converter can run is reported by its own repository — which is why Linux carries a desktop ceiling despite having no FFmpeg.

Every ceiling above is the platform's real technical maximum, not a discounted offering: there is no free/paid split by file size. Pushing mobile to that raw ceiling trades away a safety margin, since saving a result can hold 2–3× its size resident in memory, so very large files risk an out-of-memory crash on real devices. `integration_test/capacity_probe_test.dart` exists to measure a safer, per-device number if that turns out to bite. All of it lives in `lib/core/constants/app_file_limits.dart`, with the reasoning next to each number.

The image and PDF converters add a second ceiling, on how many files one batch may hold: 30 on mobile, 100 on desktop. Unlike the byte limits this one is a product choice on every platform — files are handled one at a time, so nothing in the stack caps the count.

## Free tier and subscription

Ten **source** files per calendar month, then conversion is blocked until the count refills on the 1st or a subscription lifts it. Source files rather than produced ones: a batch of five photos costs five, five photos merged into one PDF costs five, and one PDF exploded into twelve images costs one. What was handed over is what can be predicted in advance.

Only files that actually made it through are counted. A cancelled run, a failed run and the one unreadable photo in a batch of thirty all cost nothing.

The count lives on the device, in `shared_preferences`, because the app has no accounts and no server. A clock wound backwards is ignored — `QuotaRecord.lastSeen` wins — so a spent month cannot be replayed by changing the date. A clock wound *forwards* does grant a fresh count once; closing that needs a server, which an offline app does not have. Reinstalling also clears it. Both are known and accepted.

### Who takes the money

The rule is deliberately unambitious: **where a store will sell for us, it sells; where none will, the paid tier is bought once and kept.** A store is the merchant of record — it takes the payment, remits the tax in every country it sells in, and owns the entitlement — so on those platforms there is no server to run and nothing to remember. Building that machinery ourselves for the platforms a store cannot reach would cost more than the first product is worth.

| Platform | How it is sold | Why |
| --- | --- | --- |
| Android, from Google Play | Subscription, `$0.99`/month or `$7.99`/year | Google is merchant of record and owns the entitlement. No server, no keys |
| Android, downloaded as an APK | Not sold — the paywall says where the paid version is | Play refuses billing to an app it did not install and sign |
| Windows, Linux | One-time unlock, planned | No store billing Flutter can reach. Nothing expires, so nothing has to be checked again |
| iOS, macOS | Subscription, when those builds exist | Same as Play. Neither can be built on Windows |
| Web | Not sold | No converters there either |

How a build charges depends on how it was **distributed**, which is a different question from which platform it runs on — and it cannot be detected at runtime, so it is declared at build time:

```bash
flutter build apk                                                   # direct: not sold here
flutter build appbundle --dart-define=ARCHONEX_DISTRIBUTION=store   # for Play: subscriptions live
```

The default is the cautious answer. A build that says nothing about itself is assumed not to have come from a store, which produces an honest screen rather than a purchase that cannot complete.

### The store route

`StoreSubscriptionRepo` holds every rule; `StoreBilling` behind it carries none, which is what lets a purchase, a cancellation and a store that will not answer all be tested with no store present. Three things about it are worth knowing before touching it:

- **Everything arrives out of band.** The store reports through one stream rather than by returning from the call that caused it, and it reports things the app never asked for — a renewal overnight, a purchase made on another device, a refund. So the entitlement is only ever set from that stream, and what `purchase` returns says how the attempt went and nothing more.
- **A purchase must be acknowledged or it is reversed.** Google refunds a purchase the app never completes, within days. Every entitling purchase is acknowledged, including ones nothing was waiting for.
- **A cancellation is only ever noticed by asking.** Nothing is pushed when a subscription lapses, so `refresh()` re-asks on every launch and waits `AppStorePolicy.restoreWindow` for an answer. A store that will not answer leaves the entitlement alone — silence is not evidence.

The receipt is not verified against a server, because there is no server. A rooted device running a patched store client can claim a purchase that never happened; closing that would mean converting files somewhere other than the user's machine, which is the opposite of what this app is.

### The licence route, reserved

`LicenseGateway`, `LicenseSubscriptionRepo`, `LicenseStorage` and `CheckoutLauncher` are a complete second route — bought outside the app, unlocked with a key, trusted for a day, honoured for fourteen days of silence. It is written, tested and currently **unreachable**: no build returns `PurchaseChannel.licenseKey`, because no provider that will pay out to this project's country also sells without a store.

It is kept rather than deleted because it is exactly where the desktop one-time unlock lands, whichever channel turns out to work there. Nothing above it changes when that happens — one gateway implementation and one constant.

## Stack

- Flutter (stable channel), Dart SDK `^3.10.0`
- [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) + [`bloc_concurrency`](https://pub.dev/packages/bloc_concurrency) — state management
- [`go_router`](https://pub.dev/packages/go_router) — routing
- [`equatable`](https://pub.dev/packages/equatable) — value equality
- [`file_picker`](https://pub.dev/packages/file_picker) — picking sources and saving results
- [`ffmpeg_kit_flutter_new`](https://pub.dev/packages/ffmpeg_kit_flutter_new) — the media and image engine
- [`pdf`](https://pub.dev/packages/pdf) + [`printing`](https://pub.dev/packages/printing) — the PDF engine: the first writes, the second rasterises through PDFium
- [`image`](https://pub.dev/packages/image) — encoding rasterised pages to PNG or JPEG
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) — the monthly conversion count and the licence, the only state in the app that outlives the process
- [`in_app_purchase`](https://pub.dev/packages/in_app_purchase) — store billing, and how the paid tier is actually sold
- [`http`](https://pub.dev/packages/http) + [`url_launcher`](https://pub.dev/packages/url_launcher) — the reserved licence route only. Converting never touches the network

Both PDF packages are held one minor version below the latest: those require Dart 3.12, and the toolchain is pinned to the Flutter release that ships 3.11.

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

`lib/project_files/features/pdf_converter/` follows the same skeleton with `data/engine/` in place of `data/ffmpeg/`, and differs in three ways worth knowing before touching it:

- **The direction is inferred, not chosen.** What was picked decides what can be produced, and the target then decides the shape of the run: `PdfTarget.mergesBatch` is the single question everything downstream reads.
- **Progress counts pages, not files.** Many photos collapse into one PDF and one PDF explodes into many images, so "which source is this update about" has no answer that holds for all three directions. Pages do.
- **The writer runs on an isolate.** It is pure Dart, and assembling thirty full size photos on the UI isolate is a frozen screen. Rasterising does not — `Printing.raster` is a plugin bound to the root isolate, and PDFium does the work natively anyway.

`lib/project_files/features/converter_shared/` holds what all three need, laid out in the same three layers:

- `domain/models/` — `ConversionFailure` (one sealed hierarchy for every converter), `SourceFile`, `ConvertedFile`, `SaveResult`, `NormalizedQuality`
- `data/ffmpeg/` — the error classifier, the quality-scale mapping and the filter fragments. FFmpeg-specific, and the only part of the shared layer the PDF converter does not touch.
- `data/file_access/` — the picker and the writer, including the batch save that falls back to one dialog per file when a chosen folder turns out to be unwritable
- `ui/` — the failure-to-copy mapper and the widgets every screen renders

Two features exist for the paid tier rather than for converting. `usage_quota/` owns the count: every rule about calendar months and device clocks lives in `UsageQuotaRepoImpl`, and `QuotaStorage` behind it only reads and writes what those rules produced — which is what lets the rules be tested without a platform plugin. `subscription/` owns the entitlement and the paywall screen, and repeats the same split for the licence: `LicenseSubscriptionRepo` holds every rule, while `LicenseGateway`, `LicenseStorage` and `CheckoutLauncher` behind it carry no decisions at all — which is what lets the offline grace period, a revoked key and a clock wound backwards all be tested with no network and no plugin. The two features meet in exactly one place, `WatchConversionAllowanceUseCase`, which hands the converters a single `ConversionAllowance`; no converter screen ever asks about subscriptions. Both repositories are app-wide singletons provided in `archonex_app.dart`, because the same count is spent from three screens.

There is no server anywhere in this project. On the platforms that sell, the store is the merchant of record and owns the entitlement; on the platforms that do not, nothing is sold yet. That is a deliberate ceiling on how much machinery the first release carries.

A converter-specific model stays in its own feature: `MediaFormat`, `ImageFormat` and `PdfFormat` answer different questions and are deliberately not one enum. Adding a failure to the sealed `ConversionFailure` hierarchy will not compile until it is given copy in all three ARB files — that is the mechanism working, not an obstacle.

## Tests

```bash
flutter analyze
flutter test
```

`test/` holds unit and widget tests, concentrated on the three converters: the FFmpeg command builders, the duration parser and error classifier, every use case, every BLoC, the format and settings models, and a view test each. The paid tier is covered alongside them: month rollover, a clock wound backwards, overlapping counts, what each converter charges for, and the paywall in both of its forms. The licence gets the same treatment — a revoked key, a used-up key, an unreachable service inside and outside the grace window, and the rule that a refusal arrives as `200` while an outage does not. Fakes are hand written, one file per feature (`test/features/<feature>/fakes.dart`) — there is no mocking package.

`integration_test/` is separate and is **not** part of CI — it needs a real device:

```bash
flutter test integration_test/capacity_probe_test.dart -d <device-id>
flutter test integration_test/ffmpeg_capability_probe_test.dart -d <device-id>
flutter test integration_test/pdf_engine_probe_test.dart -d <device-id>
```

The **capacity probe** measures the actual per-device conversion and save ceilings, so the numbers in `app_file_limits.dart` can eventually be replaced by measured ones rather than derived ones.

The **capability probe** reports which encoders and decoders the bundled FFmpeg actually has, which is the only way to check that `ImageFormat.canEncode` is telling the truth on the platform that ships it. Run it again after any `ffmpeg_kit_flutter_new` upgrade.

The **PDF engine probe** drives the real writer and the real rasteriser, which the unit tests cannot: they run against fakes, so nothing there touches the `pdf` writer, the embedded font, the background isolate, or PDFium. It is what proves that Cyrillic really is written and that CJK really is refused. Run it again after any `pdf` or `printing` upgrade.

## CI

`.github/workflows/ci.yml` runs `flutter analyze` and `flutter test` on every push to `main` and on every pull request.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
