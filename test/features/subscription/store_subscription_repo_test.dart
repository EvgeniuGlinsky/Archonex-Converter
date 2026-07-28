import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/project_files/features/subscription/data/store_subscription_repo.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/store_billing.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/store_products.dart';

import 'fakes.dart';

void main() {
  late FakeStoreBilling billing;
  late StoreSubscriptionRepo repo;

  const StoreProduct monthlyProduct = StoreProduct(
    id: StoreProducts.monthly,
    priceLabel: r'$0.99',
  );
  const StoreProduct yearlyProduct = StoreProduct(
    id: StoreProducts.yearly,
    priceLabel: r'$7.99',
  );

  StorePurchase purchase(
    StorePurchaseStatus status, {
    String id = StoreProducts.monthly,
    bool needsCompletion = false,
  }) =>
      StorePurchase(productId: id, status: status, needsCompletion: needsCompletion);

  setUp(() {
    billing = FakeStoreBilling(
      products: const <StoreProduct>[yearlyProduct, monthlyProduct],
    );
    repo = StoreSubscriptionRepo(billing: billing);
  });

  tearDown(() async {
    await repo.dispose();
    await billing.close();
  });

  test('the store is the channel', () {
    expect(repo.channel, PurchaseChannel.store);
  });

  group('what is on sale', () {
    test('plans are priced by the store, shortest commitment first', () async {
      final List<SubscriptionPlan> plans = await repo.loadPlans();

      // The store answered yearly-first; reading order is ours to fix.
      expect(
        plans.map((SubscriptionPlan plan) => plan.id),
        <String>[StoreProducts.monthly, StoreProducts.yearly],
      );
      expect(plans.first.priceLabel, r'$0.99');
      expect(plans.first.period, SubscriptionPeriod.monthly);
    });

    test('a product this build does not sell is ignored, not shown', () async {
      billing.products = const <StoreProduct>[
        monthlyProduct,
        StoreProduct(id: 'archonex_pro_weekly', priceLabel: r'$0.49'),
      ];

      final List<SubscriptionPlan> plans = await repo.loadPlans();

      expect(plans.map((SubscriptionPlan plan) => plan.id), <String>[StoreProducts.monthly]);
    });

    test('a device with no store sells nothing and is not asked', () async {
      billing.available = false;

      expect(await repo.loadPlans(), isEmpty);
      expect(billing.queryCallCount, 0);
    });

    test('a store that will not answer sells nothing rather than throwing',
        () async {
      billing.isBroken = true;

      expect(await repo.loadPlans(), isEmpty);
    });
  });

  group('buying', () {
    test('a completed purchase entitles the device', () async {
      final List<SubscriptionPlan> plans = await repo.loadPlans();

      final Future<PurchaseOutcome> pending = repo.purchase(plans.first);
      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.purchased)]);

      expect(await pending, PurchaseOutcome.succeeded);
      expect(repo.statusListenable.value.isActive, isTrue);
      expect(repo.statusListenable.value.planId, StoreProducts.monthly);
      expect(billing.lastBoughtProductId, StoreProducts.monthly);
    });

    test('the entitlement comes from the stream, not from the return value',
        () async {
      // A purchase made on another device, or a renewal overnight, arrives with
      // nobody waiting on it — and still has to entitle this device.
      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.purchased)]);

      expect(repo.statusListenable.value.isActive, isTrue);
    });

    test('closing the sheet is cancelled, not failed', () async {
      final List<SubscriptionPlan> plans = await repo.loadPlans();

      final Future<PurchaseOutcome> pending = repo.purchase(plans.first);
      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.cancelled)]);

      expect(await pending, PurchaseOutcome.cancelled);
      expect(repo.statusListenable.value.isActive, isFalse);
    });

    test('a store error is a failure and entitles nothing', () async {
      final List<SubscriptionPlan> plans = await repo.loadPlans();

      final Future<PurchaseOutcome> pending = repo.purchase(plans.first);
      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.failed)]);

      expect(await pending, PurchaseOutcome.failed);
      expect(repo.statusListenable.value.isActive, isFalse);
    });

    test('a pending purchase is not reported either way', () async {
      final List<SubscriptionPlan> plans = await repo.loadPlans();

      final Future<PurchaseOutcome> pending = repo.purchase(plans.first);
      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.pending)]);

      // Still waiting: a bank confirmation in progress is not an answer.
      expect(repo.statusListenable.value.isActive, isFalse);

      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.purchased)]);

      expect(await pending, PurchaseOutcome.succeeded);
    });

    test('a plan the store never offered cannot be bought', () async {
      const SubscriptionPlan ghost = SubscriptionPlan(
        id: 'archonex_pro_ghost',
        period: SubscriptionPeriod.monthly,
        priceLabel: r'$1',
      );

      expect(await repo.purchase(ghost), PurchaseOutcome.unavailable);
      expect(billing.lastBoughtProductId, isNull);
    });

    test('a sheet that never opens is a failure', () async {
      final List<SubscriptionPlan> plans = await repo.loadPlans();
      billing.opensSheet = false;

      expect(await repo.purchase(plans.first), PurchaseOutcome.failed);
    });

    test('a store that throws while buying is a failure', () async {
      final List<SubscriptionPlan> plans = await repo.loadPlans();
      billing.isBroken = true;

      expect(await repo.purchase(plans.first), PurchaseOutcome.failed);
    });

    test('a purchase for another product does not settle this one', () async {
      final List<SubscriptionPlan> plans = await repo.loadPlans();

      final Future<PurchaseOutcome> pending = repo.purchase(plans.first);
      // Something bought in an older version of the app. Not ours to act on.
      await billing.report(<StorePurchase>[
        purchase(StorePurchaseStatus.purchased, id: 'archonex_legacy_unlock'),
      ]);

      expect(repo.statusListenable.value.isActive, isFalse);

      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.purchased)]);

      expect(await pending, PurchaseOutcome.succeeded);
    });
  });

  group('acknowledging', () {
    test('a purchase the store is waiting on is always completed', () async {
      // Google reverses a purchase that is never acknowledged, so a subscriber
      // who paid would be refunded within days and lose access for no visible
      // reason.
      await billing.report(<StorePurchase>[
        purchase(StorePurchaseStatus.purchased, needsCompletion: true),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(billing.completed, hasLength(1));
    });

    test('one nobody was waiting for is completed too', () async {
      await billing.report(<StorePurchase>[
        purchase(StorePurchaseStatus.restored, needsCompletion: true),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(billing.completed, hasLength(1));
    });

    test('a purchase the store is not waiting on is left alone', () async {
      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.purchased)]);
      await Future<void>.delayed(Duration.zero);

      expect(billing.completed, isEmpty);
    });
  });

  group('restoring', () {
    test('an owned subscription comes back', () async {
      billing.ownedPurchases = <StorePurchase>[purchase(StorePurchaseStatus.restored)];

      expect(await repo.restore(), PurchaseOutcome.succeeded);
      expect(repo.statusListenable.value.isActive, isTrue);
    });

    test('nothing owned is said plainly', () async {
      expect(await repo.restore(), PurchaseOutcome.nothingToRestore);
      expect(repo.statusListenable.value.isActive, isFalse);
      expect(billing.restoreCallCount, 1);
    });

    test('a store that will not answer does not take the licence away',
        () async {
      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.purchased)]);
      billing.isBroken = true;

      expect(await repo.restore(), PurchaseOutcome.failed);
      // The store said nothing, which is not evidence of anything.
      expect(repo.statusListenable.value.isActive, isTrue);
    });

    test('a device with no store has nothing to restore from', () async {
      billing.available = false;

      expect(await repo.restore(), PurchaseOutcome.unavailable);
    });
  });

  group('on launch', () {
    test('an owned subscription is found', () async {
      billing.ownedPurchases = <StorePurchase>[purchase(StorePurchaseStatus.restored)];

      await repo.refresh();

      expect(repo.statusListenable.value.isActive, isTrue);
    });

    test('a cancelled subscription is noticed and dropped', () async {
      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.purchased)]);
      expect(repo.statusListenable.value.isActive, isTrue);

      // The store now owns nothing, which is the only way a cancellation made
      // outside the app is ever seen.
      billing.ownedPurchases = const <StorePurchase>[];
      await repo.refresh();

      expect(repo.statusListenable.value.isActive, isFalse);
    });

    test('a store that will not answer leaves the entitlement alone', () async {
      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.purchased)]);
      billing.isBroken = true;

      await repo.refresh();

      expect(repo.statusListenable.value.isActive, isTrue);
    });

    test('a device with no store is left alone rather than downgraded',
        () async {
      await billing.report(<StorePurchase>[purchase(StorePurchaseStatus.purchased)]);
      billing.available = false;

      await repo.refresh();

      expect(repo.statusListenable.value.isActive, isTrue);
      expect(billing.restoreCallCount, 0);
    });
  });

  test('there is no key to redeem in a store build', () async {
    expect(await repo.redeemLicenseKey('ANY-KEY'), PurchaseOutcome.unavailable);
  });
}
