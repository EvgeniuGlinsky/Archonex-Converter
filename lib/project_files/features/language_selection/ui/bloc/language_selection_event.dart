part of 'language_selection_bloc.dart';

sealed class LanguageSelectionEvent extends Equatable {
  const LanguageSelectionEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the available languages and the currently stored one.
final class LanguageSelectionStarted extends LanguageSelectionEvent {
  const LanguageSelectionStarted();
}

/// The user tapped a language tile.
final class LanguageChanged extends LanguageSelectionEvent {
  const LanguageChanged(this.language);

  final AppLanguage language;

  @override
  List<Object?> get props => <Object?>[language];
}

/// The user confirmed the choice with the continue button.
final class LanguageSelectionSubmitted extends LanguageSelectionEvent {
  const LanguageSelectionSubmitted();
}
