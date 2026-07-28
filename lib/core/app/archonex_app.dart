import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:archonex_converter/core/router/app_router.dart';
import 'package:archonex_converter/core/theme/app_theme.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/language_selection/data/language_repo_impl.dart';
import 'package:archonex_converter/project_files/features/language_selection/domain/language_repo.dart';
import 'package:archonex_converter/project_files/features/language_selection/domain/models/app_language.dart';
import 'package:archonex_converter/project_files/features/subscription/data/platform/subscription_platform.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

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
  // All of these outlive rebuilds: the router keeps the stack, the language
  // repo keeps the chosen language, and the subscription repo holds one
  // entitlement for the whole app — every screen that can offer the paid tier
  // has to read the same answer.
  final GoRouter _router = AppRouter.create();
  final LanguageRepo _languageRepo = LanguageRepoImpl();
  final SubscriptionRepo _subscriptionRepo = createSubscriptionRepo();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<LanguageRepo>.value(value: _languageRepo),
        RepositoryProvider<SubscriptionRepo>.value(value: _subscriptionRepo),
      ],
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
