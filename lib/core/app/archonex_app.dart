import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:archonex/core/router/app_router.dart';
import 'package:archonex/core/theme/app_theme.dart';
import 'package:archonex/l10n/app_localizations.dart';
import 'package:archonex/project_files/features/language_selection/data/language_repo_impl.dart';
import 'package:archonex/project_files/features/language_selection/domain/language_repo.dart';
import 'package:archonex/project_files/features/language_selection/domain/models/app_language.dart';

/// Application root.
///
/// App-wide singletons are provided here; feature-scoped dependencies stay in
/// their own `*_page.dart`.
class ArchonexApp extends StatefulWidget {
  const ArchonexApp({super.key});

  @override
  State<ArchonexApp> createState() => _ArchonexAppState();
}

class _ArchonexAppState extends State<ArchonexApp> {
  // Both outlive rebuilds: the router keeps the stack, the repo keeps the
  // chosen language for the whole session.
  final GoRouter _router = AppRouter.create();
  final LanguageRepo _languageRepo = LanguageRepoImpl();

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<LanguageRepo>.value(
      value: _languageRepo,
      child: ValueListenableBuilder<AppLanguage>(
        valueListenable: _languageRepo.selectedLanguageListenable,
        builder: (context, language, _) => MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          locale: Locale(language.code),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
        ),
      ),
    );
  }
}
