## Localization (i18n)

- **Add a string**: add the key to every ARB file in `lib/l10n/` (`app_en.arb` is the template, one file per `AppLanguage`) and run `flutter gen-l10n`; generated `app_localizations*.dart` are gitignored — never hand-edit.
- **Use it**: `AppLocalizations.of(context)!.someKey` — no hardcoded copy anywhere, including domain models, so UI mappers (`ui/mappers/*_ui.dart`) expose `String someKey(BuildContext context)` methods instead of getters.
