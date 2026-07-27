import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:archonex_converter/core/router/app_route.dart';
import 'package:archonex_converter/project_files/features/splash/ui/bloc/splash_bloc.dart';
import 'package:archonex_converter/project_files/features/splash/ui/widgets/splash_branding.dart';
import 'package:archonex_converter/project_files/features/splash/ui/widgets/splash_layout.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStatusChanged,
      child: const Scaffold(
        body: SplashLayout(body: SplashBranding()),
      ),
    );
  }

  void _onStatusChanged(BuildContext context, SplashState state) {
    if (state.status == SplashStatus.completed) {
      context.goNamed(AppRoute.languageSelection.routeName);
    }
  }
}
