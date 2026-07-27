part of 'splash_bloc.dart';

enum SplashStatus { initial, completed }

final class SplashState extends Equatable {
  const SplashState({this.status = SplashStatus.initial});

  final SplashStatus status;

  SplashState copyWith({SplashStatus? status}) {
    return SplashState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => <Object?>[status];
}
