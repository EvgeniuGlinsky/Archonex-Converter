## Localization (i18n)

- **Add a string**: add the key to every ARB file in `lib/l10n/` (`app_en.arb` is the template, one file per `AppLanguage`) and run `flutter gen-l10n`; generated `app_localizations*.dart` are gitignored — never hand-edit.
- **Use it**: `AppLocalizations.of(context)!.someKey` — no hardcoded copy anywhere, including domain models, so UI mappers (`ui/mappers/*_ui.dart`) expose `String someKey(BuildContext context)` methods instead of getters.

## Platform boundaries

- **Add one**: `data/platform/<feature>_platform.dart` holding only a conditional export — `export '<feature>_platform_web.dart' if (dart.library.io) '<feature>_platform_io.dart';` — plus one file per side declaring the same factory function.
- **Use it**: call that factory; `Platform.is*` and `kIsWeb` never appear in the widget tree or in a BLoC. A build-time question (`String.fromEnvironment`) belongs on this boundary too, not at the call site.

## Test fakes

- **Add one**: hand written, one file per feature — `test/features/<feature>/fakes.dart`. Public fields instead of constructor-only config, call counters for what must be proved to have happened, and a boolean per failure mode (`isBroken`, `isReachable`). There is no mocking package in this project.
- **Use it**: fake the `domain/` contract, never a `data/` implementation. A rule that cannot be tested through an interface is a missing interface, not a reason to reach past one.

## Injectable clock

- **Add one**: `DateTime Function()? now` on the repository constructor, stored as `_now = now ?? DateTime.now`.
- **Use it**: every time-dependent rule reads `_now()`, and elapsed time is clamped at zero so a clock wound backwards changes nothing. Month boundaries and grace periods are otherwise untestable without waiting for them.

## Build-time configuration

- **Add one**: `static const X = String.fromEnvironment('ARCHONEX_X', defaultValue: …)` in `lib/core/constants/`, with the reason for the default written next to it.
- **Use it**: `--dart-define=ARCHONEX_X=…` at build time. The default must be independently correct: builds handed out through GitHub Releases carry whatever was compiled in, and nobody updates them for us.

## Where things live

- **App-wide**: repositories that outlive a screen — language, quota, subscription — are constructed once in `lib/core/app/archonex_app.dart` and provided from there. Anything counted or paid for belongs here, because a per-screen instance would count the same file twice.
- **Feature-scoped**: everything else is built in that feature's `ui/<feature>_page.dart`, which wires the BLoC and holds no UI. `ui/<feature>_view.dart` is pure presentation, which is what lets a widget test drive a screen without standing up the app.
