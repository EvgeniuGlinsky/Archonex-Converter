part of 'language_selection_bloc.dart';

enum LanguageSelectionStatus { initial, ready, submitted }

final class LanguageSelectionState extends Equatable {
  const LanguageSelectionState({
    this.status = LanguageSelectionStatus.initial,
    this.languages = const <AppLanguage>[],
    this.selectedLanguage = AppLanguage.english,
  });

  final LanguageSelectionStatus status;
  final List<AppLanguage> languages;
  final AppLanguage selectedLanguage;

  LanguageSelectionState copyWith({
    LanguageSelectionStatus? status,
    List<AppLanguage>? languages,
    AppLanguage? selectedLanguage,
  }) {
    return LanguageSelectionState(
      status: status ?? this.status,
      languages: languages ?? this.languages,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, languages, selectedLanguage];
}
