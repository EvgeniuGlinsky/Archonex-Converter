/// Every destination of the app.
///
/// The enum entry name doubles as the GoRouter route name, so there is exactly
/// one source of truth per destination.
enum AppRoute {
  splash(path: '/'),
  languageSelection(path: '/language'),
  fileConverters(path: '/converters'),

  /// Reachable from every converter, so it sits at the top level rather than
  /// under one of them.
  paywall(path: '/paywall'),

  // Children of [fileConverters] — one entry per converter screen.
  mediaConverter(path: 'media'),
  imageConverter(path: 'image'),
  pdfConverter(path: 'pdf');

  const AppRoute({required this.path});

  final String path;

  /// GoRouter route name, e.g. `languageSelection`.
  String get routeName => name;
}
