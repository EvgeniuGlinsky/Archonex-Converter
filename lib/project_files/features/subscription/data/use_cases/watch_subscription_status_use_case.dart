import 'dart:async';

import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_status.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// The entitlement, as a stream the paywall bloc can live on.
class WatchSubscriptionStatusUseCase {
  const WatchSubscriptionStatusUseCase(this._repo);

  final SubscriptionRepo _repo;

  /// Emits the current status immediately, then again on every change.
  Stream<SubscriptionStatus> call() {
    late final StreamController<SubscriptionStatus> controller;

    void emit() => controller.add(_repo.statusListenable.value);

    controller = StreamController<SubscriptionStatus>(
      onListen: () {
        _repo.statusListenable.addListener(emit);
        emit();
      },
      onCancel: () => _repo.statusListenable.removeListener(emit),
    );

    return controller.stream;
  }
}
