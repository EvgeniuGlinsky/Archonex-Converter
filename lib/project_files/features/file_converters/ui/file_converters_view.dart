import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:archonex/core/router/app_route.dart';
import 'package:archonex/core/widgets/app_screen_header.dart';
import 'package:archonex/core/widgets/app_screen_layout.dart';
import 'package:archonex/l10n/app_localizations.dart';
import 'package:archonex/project_files/features/file_converters/domain/models/converter_tool.dart';
import 'package:archonex/project_files/features/file_converters/ui/bloc/file_converters_bloc.dart';
import 'package:archonex/project_files/features/file_converters/ui/mappers/converter_tool_ui.dart';
import 'package:archonex/project_files/features/file_converters/ui/widgets/converter_tool_list.dart';

class FileConvertersView extends StatelessWidget {
  const FileConvertersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: AppScreenLayout(
        header: AppScreenHeader(
          title: AppLocalizations.of(context)!.fileConvertersTitle,
          subtitle: AppLocalizations.of(context)!.fileConvertersScreenSubtitle,
        ),
        body: BlocBuilder<FileConvertersBloc, FileConvertersState>(
          builder: (context, state) => ConverterToolList(
            tools: state.converters,
            onToolSelected: (tool) => _onToolSelected(context, tool),
          ),
        ),
      ),
    );
  }

  void _onToolSelected(BuildContext context, ConverterTool tool) {
    final AppRoute? route = tool.type.route;
    if (route == null) {
      return;
    }

    context.goNamed(route.routeName);
  }
}
