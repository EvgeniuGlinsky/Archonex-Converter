part of 'splash_bloc.dart';

sealed class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Fired once when the splash screen is mounted.
final class SplashStarted extends SplashEvent {
  const SplashStarted();
}
