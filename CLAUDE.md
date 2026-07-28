## Localization (i18n)

- **Add a string**: add the key to every ARB file in `lib/l10n/` (`app_en.arb` is the template, one file per `AppLanguage`) and run `flutter gen-l10n`; generated `app_localizations*.dart` are gitignored — never hand-edit.
- **Use it**: `AppLocalizations.of(context)!.someKey` — no hardcoded copy anywhere, including domain models. Nothing checks parity for you: a key added to `app_en.arb` alone compiles, passes every test, and ships English to a Russian user.

## Failures

- **Add one**: `final class <Reason>Failure extends ConversionFailure` in `converter_shared/domain/models/conversion_failure.dart`, carrying numbers and labels for interpolation and never a sentence — a `String message` field compiles quietly and puts user-facing copy in the domain layer. An exception no screen renders as an error stays out of the hierarchy: `LicenseServiceUnavailable` is caught in `data/` and becomes a `PurchaseOutcome`.
- **Use it**: raw stderr and platform exceptions become a failure only in `data/` — `ffmpeg_error_classifier.dart`, `mapSaveError`, the `PdfWriteError` switch — because that is the only layer that knows what the engine actually said.

## Platform boundaries

- **Add one**: `data/platform/<feature>_platform.dart` holding only a conditional export — `export '<feature>_platform_web.dart' if (dart.library.io) '<feature>_platform_io.dart';` — one file per side declaring the same factory, and beside every real implementation in `ffmpeg/`, `engine/` or `file_access/` a refusing sibling the excluded side returns instead: `unsupported_<x>_repo.dart`, never in `platform/`.
- **Use it**: call the factory — `Platform.is*`, `kIsWeb` and `String.fromEnvironment` never appear in a widget or a BLoC, because a compile-time question asked at the call site breaks the web build, which no CI job builds. A refusal reports `isSupported => false`, errors its job's stream with `ConversionUnsupportedFailure` and throws it from anything reaching the file system, while capability getters still answer (`reportsSaveLocation => false`) and `discard` stays a no-op, so the screen explains itself instead of crashing.

## Conversion jobs

- **Add one**: the job class is private, sits next to its repository and is built on `StreamController(onListen: _start)`, so the work begins on the first listener — a plain `StreamController()` starts converting the moment the use case returns.
- **Use it**: the stream closing says the run is over, not that it succeeded — an image batch closes with failed items still in it — and a cancellation, and only a cancellation, ends the stream with `ConversionCancelledFailure`, after the temp directory is already gone. The BLoC consumes with `emit.forEach`, holds `_activeJob` and cancels it in `close()`, or an FFmpeg session outlives the screen that started it.

## Bloc state

- **Add one**: every question a widget asks about a state is a getter on the state class — `canConvert`, `isBusy`, `progress`, `hasAdvancedSettings` — computed from the fields and never stored. Any `copyWith`, on a state or on a domain model, clears a nullable field through an explicit `bool clearX = false`, because `null` in that signature already means "leave it alone" and cannot also mean "unset it".
- **Use it**: widgets read `state.canX` and derive nothing, because two widgets deriving one condition separately is how a button ends up enabled while the handler refuses. `props` lists every field: leave one out and the screen never rebuilds when it changes, which no lint and no compiler will tell you.

## Test fakes

- **Add one**: hand written, one file per feature — `test/features/<feature>/fakes.dart`. There is no mocking package here and none is to be added: `mockito`, `mocktail` and `bloc_test` are absent from `pubspec.yaml` on purpose, and an absence is the one thing reading the code cannot tell you.
- **Use it**: fake the `domain/` contract, never a `data/` implementation. A rule that cannot be tested through an interface is a missing interface, not a reason to reach past one.

## Bloc and widget tests

- **Add one**: `Future<void> settle() => Future<void>.delayed(Duration.zero);` at the top of the file, awaited after every `add` — with no `bloc_test`, nothing else drains the event queue before an assertion reads `bloc.state`.
- **Use it**: in a widget test the bloc is built inside `BlocProvider.create`, never in `setUp`, because a bloc from `setUp` lives in another async zone and silently never receives the events — the test just does nothing, with no error pointing at the cause. A bloc test builds it in `setUp` and is right to.

## Injectable clock

- **Add one**: `DateTime Function()? now` on the repository constructor, stored as `_now = now ?? DateTime.now`. Month boundaries and grace periods are otherwise untestable without waiting for them.
- **Use it**: every time-dependent rule reads `_now()`, and a clock wound backwards changes nothing — `UsageQuotaRepoImpl` takes the later of `_now()` and the stored `lastSeen`, so moving the device clock back cannot hand out a fresh month.

## Build-time configuration

- **Add one**: `static const X = String.fromEnvironment('ARCHONEX_X', defaultValue: …)` read once, on the platform boundary or in `lib/core/constants/`, with the reason for the default written next to it.
- **Use it**: `--dart-define=ARCHONEX_X=…` at build time, and the default is the safe value rather than the production one. Only the Play app bundle is built with `ARCHONEX_DISTRIBUTION=store`, because a store refuses billing to a build it did not install, and a build handed out through GitHub Releases carries whatever was compiled in for good — nobody updates those for us.

## Constants and tokens

- **Add one**: every number encoding a product decision carries its reason next to it, and a value the platform decides becomes a `static` getter over a private tier table rather than a `const` — `AppFileLimits` answers per platform that way.
- **Use it**: `Theme.of(context)` read into a local on the first line of `build`, and no raw colour anywhere — `Color(0x…)` exists once, in `app_theme.dart`. Width-dependent counts come from `LayoutBuilder`, never `MediaQuery`, because `AppScreenLayout` caps content far below the window and the window would overstate the room.

## Where things live

- **App-wide**: repositories that outlive a screen — language, quota, subscription — are constructed once in `lib/core/app/archonex_app.dart` and provided from there. Anything counted or paid for belongs here, because a per-screen instance would count the same file twice, and no test can catch it: every test injects a fake repository and none of them sees the wiring.
- **Feature-scoped**: everything else is built in that feature's `ui/<feature>_page.dart`, which wires the BLoC and holds no UI. `ui/<feature>_view.dart` is pure presentation, which is what lets a widget test drive a screen without standing up the app.

## Doc comments

- **Add one**: repositories, domain models, constants classes, platform barrels, jobs and any use case carrying a guard open with one `///` sentence saying what it is, then a blank `///` and a paragraph naming the alternative that was rejected. That second paragraph is why `AppFileLimits`, `AppStorePolicy` and the platform barrels need no document outside the code.
- **Use it**: cross-reference by backticked class or file name, and say so outright when a file repeats a sibling's convention — `PrefsLicenseStorage` names `PrefsQuotaStorage`. A private single-use widget, a one-line use case and an event class earn nothing: there the name is the whole story.
