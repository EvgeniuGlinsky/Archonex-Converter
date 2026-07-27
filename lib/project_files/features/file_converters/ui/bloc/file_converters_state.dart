part of 'file_converters_bloc.dart';

enum FileConvertersStatus { initial, ready }

final class FileConvertersState extends Equatable {
  const FileConvertersState({
    this.status = FileConvertersStatus.initial,
    this.converters = const <ConverterTool>[],
  });

  final FileConvertersStatus status;
  final List<ConverterTool> converters;

  FileConvertersState copyWith({
    FileConvertersStatus? status,
    List<ConverterTool>? converters,
  }) {
    return FileConvertersState(
      status: status ?? this.status,
      converters: converters ?? this.converters,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, converters];
}
