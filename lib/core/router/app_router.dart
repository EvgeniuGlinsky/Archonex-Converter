import 'package:go_router/go_router.dart';

import 'package:archonex_converter/core/router/app_route.dart';
import 'package:archonex_converter/project_files/features/file_converters/ui/file_converters_page.dart';
import 'package:archonex_converter/project_files/features/image_converter/ui/image_converter_page.dart';
import 'package:archonex_converter/project_files/features/language_selection/ui/language_selection_page.dart';
import 'package:archonex_converter/project_files/features/media_converter/ui/media_converter_page.dart';
import 'package:archonex_converter/project_files/features/pdf_converter/ui/pdf_converter_page.dart';
import 'package:archonex_converter/project_files/features/splash/ui/splash_page.dart';

/// Builds the application router.
///
/// New products are added by appending a [GoRoute] under the matching category.
class AppRouter {
  const AppRouter._();

  static GoRouter create() {
    return GoRouter(
      initialLocation: AppRoute.splash.path,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoute.splash.path,
          name: AppRoute.splash.routeName,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoute.languageSelection.path,
          name: AppRoute.languageSelection.routeName,
          builder: (context, state) => const LanguageSelectionPage(),
        ),
        GoRoute(
          path: AppRoute.fileConverters.path,
          name: AppRoute.fileConverters.routeName,
          builder: (context, state) => const FileConvertersPage(),
          routes: <RouteBase>[
            GoRoute(
              path: AppRoute.mediaConverter.path,
              name: AppRoute.mediaConverter.routeName,
              builder: (context, state) => const MediaConverterPage(),
            ),
            GoRoute(
              path: AppRoute.imageConverter.path,
              name: AppRoute.imageConverter.routeName,
              builder: (context, state) => const ImageConverterPage(),
            ),
            GoRoute(
              path: AppRoute.pdfConverter.path,
              name: AppRoute.pdfConverter.routeName,
              builder: (context, state) => const PdfConverterPage(),
            ),
          ],
        ),
      ],
    );
  }
}
