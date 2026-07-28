import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:archonex_converter/core/constants/app_durations.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/refresh_subscription_use_case.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/refresh_quota_use_case.dart';

part 'splash_event.dart';
part 'splash_state.dart';

/// Holds the splash screen for a short beat, and spends it reading the state
/// that has to exist before the first screen: the monthly count and whether
/// this device is subscribed.
///
/// Both run alongside the beat rather than after it, so warming up costs no
/// extra time.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({
    required RefreshQuotaUseCase refreshQuota,
    required RefreshSubscriptionUseCase refreshSubscription,
  })  : _refreshQuota = refreshQuota,
        _refreshSubscription = refreshSubscription,
        super(const SplashState()) {
    // droppable: re-entering the screen must not queue a second timer.
    on<SplashStarted>(_onStarted, transformer: droppable());
  }

  final RefreshQuotaUseCase _refreshQuota;
  final RefreshSubscriptionUseCase _refreshSubscription;

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    await Future.wait<void>(<Future<void>>[
      Future<void>.delayed(AppDurations.splash),
      _warmUp(),
    ]);

    emit(state.copyWith(status: SplashStatus.completed));
  }

  /// Storage that refuses to answer must not strand anyone on the splash
  /// screen. The count then starts from what is in memory, which errs towards
  /// letting the user convert rather than towards charging them.
  Future<void> _warmUp() async {
    try {
      await Future.wait<void>(<Future<void>>[
        _refreshQuota(),
        _refreshSubscription(),
      ]);
    } catch (_) {
      return;
    }
  }
}
