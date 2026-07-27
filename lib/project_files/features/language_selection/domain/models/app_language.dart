/// Languages the launcher can run in.
enum AppLanguage {
  english(code: 'en', label: 'English', nativeLabel: 'English'),
  russian(code: 'ru', label: 'Russian', nativeLabel: 'Русский'),
  chinese(code: 'zh', label: 'Chinese', nativeLabel: '中文');

  const AppLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
  });

  /// ISO 639-1 code, ready for a localization delegate later on.
  final String code;

  /// Name in English.
  final String label;

  /// Name as written by native speakers.
  final String nativeLabel;
}
