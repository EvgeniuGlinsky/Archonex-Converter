import 'package:go_router/go_router.dart';

import 'package:archonex/core/router/app_route.dart';
import 'package:archonex/project_files/features/category_selection/ui/category_selection_page.dart';
import 'package:archonex/project_files/features/file_converters/ui/file_converters_page.dart';
import 'package:archonex/project_files/features/language_selection/ui/language_selection_page.dart';
import 'package:archonex/project_files/features/library_apps/ui/library_apps_page.dart';
import 'package:archonex/project_files/features/media_converter/ui/media_converter_page.dart';
import 'package:archonex/project_files/features/news_apps/ui/news_apps_page.dart';
import 'package:archonex/project_files/features/splash/ui/splash_page.dart';
import 'package:archonex/project_files/features/utilities/ui/utilities_page.dart';

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
          path: AppRoute.categorySelection.path,
          name: AppRoute.categorySelection.routeName,
          builder: (context, state) => const CategorySelectionPage(),
          routes: <RouteBase>[
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
              ],
            ),
            GoRoute(
              path: AppRoute.utilities.path,
              name: AppRoute.utilities.routeName,
              builder: (context, state) => const UtilitiesPage(),
            ),
            GoRoute(
              path: AppRoute.libraryApps.path,
              name: AppRoute.libraryApps.routeName,
              builder: (context, state) => const LibraryAppsPage(),
            ),
            GoRoute(
              path: AppRoute.newsApps.path,
              name: AppRoute.newsApps.routeName,
              builder: (context, state) => const NewsAppsPage(),
            ),
          ],
        ),
      ],
    );
  }
}
