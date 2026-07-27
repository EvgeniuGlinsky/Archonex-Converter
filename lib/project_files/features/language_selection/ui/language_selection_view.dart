import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:archonex/core/constants/app_strings.dart';
import 'package:archonex/core/router/app_route.dart';
import 'package:archonex/core/widgets/app_primary_button.dart';
import 'package:archonex/core/widgets/app_screen_header.dart';
import 'package:archonex/core/widgets/app_screen_layout.dart';
import 'package:archonex/project_files/features/language_selection/domain/models/app_language.dart';
import 'package:archonex/project_files/features/language_selection/ui/bloc/language_selection_bloc.dart';
import 'package:archonex/project_files/features/language_selection/ui/widgets/language_list.dart';

class LanguageSelectionView extends StatelessWidget {
  const LanguageSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LanguageSelectionBloc, LanguageSelectionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStatusChanged,
      child: Scaffold(
        body: AppScreenLayout(
          header: const AppScreenHeader(
            title: AppStrings.languageTitle,
            subtitle: AppStrings.languageSubtitle,
          ),
          body: BlocBuilder<LanguageSelectionBloc, LanguageSelectionState>(
            builder: (context, state) => LanguageList(
              languages: state.languages,
              selectedLanguage: state.selectedLanguage,
              onLanguageSelected: (language) => _onLanguageSelected(
                context,
                language,
              ),
            ),
          ),
          bottom: AppPrimaryButton(
            label: AppStrings.continueLabel,
            onPressed: () => _onContinuePressed(context),
          ),
        ),
      ),
    );
  }

  void _onLanguageSelected(BuildContext context, AppLanguage language) {
    context.read<LanguageSelectionBloc>().add(LanguageChanged(language));
  }

  void _onContinuePressed(BuildContext context) {
    context
        .read<LanguageSelectionBloc>()
        .add(const LanguageSelectionSubmitted());
  }

  void _onStatusChanged(BuildContext context, LanguageSelectionState state) {
    if (state.status == LanguageSelectionStatus.submitted) {
      context.goNamed(AppRoute.categorySelection.routeName);
    }
  }
}
