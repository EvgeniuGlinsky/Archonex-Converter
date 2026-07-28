import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/project_files/features/splash/ui/bloc/splash_bloc.dart';
import 'package:archonex_converter/project_files/features/splash/ui/splash_view.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/refresh_subscription_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/refresh_quota_use_case.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/usage_quota_repo.dart';

/// Wires the splash dependencies. No UI lives here.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SplashBloc>(
      create: (_) => SplashBloc(
        refreshQuota: RefreshQuotaUseCase(context.read<UsageQuotaRepo>()),
        refreshSubscription:
            RefreshSubscriptionUseCase(context.read<SubscriptionRepo>()),
      )..add(const SplashStarted()),
      child: const SplashView(),
    );
  }
}
