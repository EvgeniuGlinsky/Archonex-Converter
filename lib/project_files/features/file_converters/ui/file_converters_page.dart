import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex/project_files/features/file_converters/data/file_converters_repo_impl.dart';
import 'package:archonex/project_files/features/file_converters/data/use_cases/get_converters_use_case.dart';
import 'package:archonex/project_files/features/file_converters/ui/bloc/file_converters_bloc.dart';
import 'package:archonex/project_files/features/file_converters/ui/file_converters_view.dart';

/// Wires the File Converters dependencies. No UI lives here.
class FileConvertersPage extends StatelessWidget {
  const FileConvertersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FileConvertersBloc>(
      create: (_) => FileConvertersBloc(
        getConverters: const GetConvertersUseCase(FileConvertersRepoImpl()),
      )..add(const FileConvertersStarted()),
      child: const FileConvertersView(),
    );
  }
}
