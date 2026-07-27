import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex/project_files/features/file_converters/data/use_cases/get_converters_use_case.dart';
import 'package:archonex/project_files/features/file_converters/domain/models/converter_tool.dart';

part 'file_converters_event.dart';
part 'file_converters_state.dart';

/// Supplies the converter catalogue shown by the File Converters category.
class FileConvertersBloc extends Bloc<FileConvertersEvent, FileConvertersState> {
  FileConvertersBloc({required GetConvertersUseCase getConverters})
      : _getConverters = getConverters,
        super(const FileConvertersState()) {
    // restartable: a reload always supersedes the one in flight.
    on<FileConvertersStarted>(_onStarted, transformer: restartable());
  }

  final GetConvertersUseCase _getConverters;

  void _onStarted(
    FileConvertersStarted event,
    Emitter<FileConvertersState> emit,
  ) {
    emit(
      state.copyWith(
        status: FileConvertersStatus.ready,
        converters: _getConverters(),
      ),
    );
  }
}
