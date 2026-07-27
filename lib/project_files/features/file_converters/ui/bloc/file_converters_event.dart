part of 'file_converters_bloc.dart';

sealed class FileConvertersEvent extends Equatable {
  const FileConvertersEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the converter catalogue.
final class FileConvertersStarted extends FileConvertersEvent {
  const FileConvertersStarted();
}
