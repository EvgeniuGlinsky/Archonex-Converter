import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex/core/constants/app_durations.dart';

part 'splash_event.dart';
part 'splash_state.dart';

/// Holds the splash screen for a short beat before the flow continues.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(const SplashState()) {
    // droppable: re-entering the screen must not queue a second timer.
    on<SplashStarted>(_onStarted, transformer: droppable());
  }

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    await Future<void>.delayed(AppDurations.splash);
    emit(state.copyWith(status: SplashStatus.completed));
  }
}
