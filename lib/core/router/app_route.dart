/// Every destination of the app.
///
/// The enum entry name doubles as the GoRouter route name, so there is exactly
/// one source of truth per destination.
enum AppRoute {
  splash(path: '/'),
  languageSelection(path: '/language'),
  categorySelection(path: '/categories'),

  // Children of [categorySelection] — paths are relative on purpose.
  fileConverters(path: 'file-converters'),
  utilities(path: 'utilities'),
  libraryApps(path: 'library-apps'),
  newsApps(path: 'news-apps'),

  // Children of [fileConverters] — one entry per converter screen.
  mediaConverter(path: 'media');

  const AppRoute({required this.path});

  final String path;

  /// GoRouter route name, e.g. `languageSelection`.
  String get routeName => name;
}
