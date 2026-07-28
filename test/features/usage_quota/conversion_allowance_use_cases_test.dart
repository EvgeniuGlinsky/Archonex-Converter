import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_quota_limits.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/consume_quota_use_case.dart';
import 'package:archonex_converter/project_files/features/usage_quota/data/use_cases/watch_conversion_allowance_use_case.dart';
import 'package:archonex_converter/project_files/features/usage_quota/domain/models/conversion_allowance.dart';

import '../subscription/fakes.dart';
import 'fakes.dart';

void main() {
  late FakeUsageQuotaRepo quotaRepo;
  late FakeSubscriptionRepo subscriptionRepo;

  setUp(() {
    quotaRepo = FakeUsageQuotaRepo();
    subscriptionRepo = FakeSubscriptionRepo();
  });

  WatchConversionAllowanceUseCase buildWatch() =>
      WatchConversionAllowanceUseCase(
        quotaRepo: quotaRepo,
        subscriptionRepo: subscriptionRepo,
      );

  ConsumeQuotaUseCase buildConsume() => ConsumeQuotaUseCase(
        quotaRepo: quotaRepo,
        subscriptionRepo: subscriptionRepo,
      );

  group('allowance', () {
    test('a free device is bounded by the monthly count', () async {
      quotaRepo.setUsed(4);

      final ConversionAllowance allowance = await buildWatch()().first;

      expect(allowance.isUnlimited, isFalse);
      expect(allowance.limit, AppQuotaLimits.freeFilesPerMonth);
      expect(allowance.remaining, AppQuotaLimits.freeFilesPerMonth - 4);
      expect(allowance.allows(6), isTrue);
      expect(allowance.allows(7), isFalse);
    });

    test('a spent month allows nothing and never goes negative', () async {
      quotaRepo.setUsed(AppQuotaLimits.freeFilesPerMonth + 3);

      final ConversionAllowance allowance = await buildWatch()().first;

      expect(allowance.isExhausted, isTrue);
      expect(allowance.remaining, 0);
      expect(allowance.allows(1), isFalse);
    });

    test('a subscription lifts the count entirely', () async {
      quotaRepo.setUsed(AppQuotaLimits.freeFilesPerMonth);
      subscriptionRepo.activate();

      final ConversionAllowance allowance = await buildWatch()().first;

      expect(allowance.isUnlimited, isTrue);
      expect(allowance.allows(500), isTrue);
    });

    test('listening asks the counter to roll the month over', () async {
      await buildWatch()().first;

      expect(quotaRepo.refreshCallCount, 1);
    });

    test('a purchase reaches a screen that is already watching', () async {
      final List<bool> unlimited = <bool>[];
      final Stream<ConversionAllowance> stream = buildWatch()();
      final StreamSubscription<ConversionAllowance> subscription =
          stream.listen((allowance) => unlimited.add(allowance.isUnlimited));

      await Future<void>.delayed(Duration.zero);
      subscriptionRepo.activate();
      await Future<void>.delayed(Duration.zero);

      expect(unlimited, <bool>[false, true]);

      await subscription.cancel();
    });
  });

  group('consume', () {
    test('a free device is charged for what it converted', () async {
      await buildConsume()(3);

      expect(quotaRepo.consumed, <int>[3]);
    });

    test('a subscriber is not charged at all', () async {
      subscriptionRepo.activate();

      await buildConsume()(3);

      expect(quotaRepo.consumed, isEmpty);
    });
  });
}
