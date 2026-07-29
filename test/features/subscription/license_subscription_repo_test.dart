import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/constants/app_license_policy.dart';
import 'package:archonex_converter/project_files/features/subscription/data/license_subscription_repo.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/checkout_offer.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/license_check.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/license_record.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/plan_catalog.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';

import 'fakes.dart';

void main() {
  late FakeLicenseGateway gateway;
  late FakeLicenseStorage storage;
  late FakeCheckoutLauncher launcher;
  late DateTime clock;

  const SubscriptionPlan monthly = SubscriptionPlan(
    id: FakeLicenseGateway.planId,
    period: SubscriptionPeriod.monthly,
    priceLabel: r'$4.99 / month',
  );
  final CheckoutOffer monthlyOffer = CheckoutOffer(
    plan: monthly,
    checkoutUrl: Uri.parse('https://pay.example.com/monthly'),
  );

  /// A licence confirmed at [clock], which is where every stored-licence test
  /// starts from before winding the clock forward.
  LicenseRecord storedLicence() => LicenseRecord(
        key: 'ARCX-1111-2222',
        instanceId: FakeLicenseGateway.instanceId,
        planId: FakeLicenseGateway.planId,
        validatedAt: clock,
      );

  LicenseSubscriptionRepo buildRepo() => LicenseSubscriptionRepo(
        gateway: gateway,
        storage: storage,
        launcher: launcher,
        deviceName: 'test-machine (windows)',
        now: () => clock,
      );

  setUp(() {
    gateway = FakeLicenseGateway();
    storage = FakeLicenseStorage();
    launcher = FakeCheckoutLauncher();
    clock = DateTime.utc(2026, 7, 28, 9);
  });

  test('the licence route is the channel, whatever the platform', () {
    expect(buildRepo().channel, PurchaseChannel.licenseKey);
  });

  group('redeeming a key', () {
    test('an accepted key entitles the device and is remembered', () async {
      final LicenseSubscriptionRepo repo = buildRepo();

      final PurchaseOutcome outcome = await repo.redeemLicenseKey('ARCX-KEY');

      expect(outcome, PurchaseOutcome.succeeded);
      expect(repo.statusListenable.value.isActive, isTrue);
      expect(repo.statusListenable.value.planId, FakeLicenseGateway.planId);
      expect(storage.record?.key, 'ARCX-KEY');
      expect(storage.record?.validatedAt, clock);
      expect(gateway.lastDeviceName, 'test-machine (windows)');
    });

    test('a pasted key is trimmed before it is sent', () async {
      await buildRepo().redeemLicenseKey('  ARCX-KEY\n');

      expect(gateway.lastKey, 'ARCX-KEY');
    });

    test('an empty field never reaches the service', () async {
      final PurchaseOutcome outcome = await buildRepo().redeemLicenseKey('   ');

      expect(outcome, PurchaseOutcome.invalidLicenseKey);
      expect(gateway.activateCallCount, 0);
    });

    test('a key the service does not know is refused, and nothing is stored',
        () async {
      gateway.check = const LicenseCheck.refused(LicenseVerdict.unknown);
      final LicenseSubscriptionRepo repo = buildRepo();

      final PurchaseOutcome outcome = await repo.redeemLicenseKey('NOPE');

      expect(outcome, PurchaseOutcome.invalidLicenseKey);
      expect(repo.statusListenable.value.isActive, isFalse);
      expect(storage.record, isNull);
    });

    test('a used-up key is refused without saying which guess was real',
        () async {
      gateway.check =
          const LicenseCheck.refused(LicenseVerdict.activationLimitReached);

      expect(
        await buildRepo().redeemLicenseKey('ARCX-KEY'),
        PurchaseOutcome.invalidLicenseKey,
      );
    });

    test('a lapsed key is told the truth rather than called invalid', () async {
      gateway.check = const LicenseCheck.refused(LicenseVerdict.inactive);

      expect(
        await buildRepo().redeemLicenseKey('ARCX-KEY'),
        PurchaseOutcome.subscriptionLapsed,
      );
    });

    test('a service nobody can reach is a failure, not a verdict on the key',
        () async {
      gateway.isReachable = false;

      // The distinction that matters: "we could not ask" must never be reported
      // as "your key is bad".
      expect(
        await buildRepo().redeemLicenseKey('ARCX-KEY'),
        PurchaseOutcome.failed,
      );
    });

    test('an active answer with no identity is treated as no answer', () async {
      // The gateway itself would normally reject this, so this covers the
      // repository refusing to store half a licence if one ever got through.
      gateway.check = const LicenseCheck(verdict: LicenseVerdict.active);
      final LicenseSubscriptionRepo repo = buildRepo();

      final PurchaseOutcome outcome = await repo.redeemLicenseKey('ARCX-KEY');

      expect(outcome, PurchaseOutcome.succeeded);
      expect(storage.record, isNull);
    });
  });

  group('on launch', () {
    test('nothing stored means nothing is entitled', () async {
      final LicenseSubscriptionRepo repo = buildRepo();

      await repo.refresh();

      expect(repo.statusListenable.value.isActive, isFalse);
      expect(gateway.validateCallCount, 0);
    });

    test('a fresh licence is honoured without asking again', () async {
      storage.record = storedLicence();
      clock = clock.add(AppLicensePolicy.revalidateAfter - const Duration(minutes: 1));
      final LicenseSubscriptionRepo repo = buildRepo();

      await repo.refresh();

      expect(repo.statusListenable.value.isActive, isTrue);
      // The whole point of the interval: an offline app does not spend a network
      // round trip on every launch.
      expect(gateway.validateCallCount, 0);
    });

    test('a licence past the interval is re-checked and re-stamped', () async {
      storage.record = storedLicence();
      clock = clock.add(AppLicensePolicy.revalidateAfter);
      final DateTime renewal = clock.add(const Duration(days: 30));
      gateway.check = const LicenseCheck(
        verdict: LicenseVerdict.active,
        instanceId: FakeLicenseGateway.instanceId,
        planId: FakeLicenseGateway.planId,
      ).copyWithExpiry(renewal);
      final LicenseSubscriptionRepo repo = buildRepo();

      await repo.refresh();

      expect(gateway.validateCallCount, 1);
      expect(repo.statusListenable.value.isActive, isTrue);
      expect(storage.record?.validatedAt, clock);
      expect(storage.record?.expiresAt, renewal);
    });

    test('a revoked licence is dropped and forgotten', () async {
      storage.record = storedLicence();
      clock = clock.add(AppLicensePolicy.revalidateAfter);
      gateway.check = const LicenseCheck.refused(LicenseVerdict.inactive);
      final LicenseSubscriptionRepo repo = buildRepo();

      await repo.refresh();

      expect(repo.statusListenable.value.isActive, isFalse);
      expect(storage.record, isNull);
      expect(storage.clearCallCount, 1);
    });

    test('silence inside the grace window costs the subscriber nothing',
        () async {
      storage.record = storedLicence();
      clock = clock.add(AppLicensePolicy.offlineGrace - const Duration(days: 1));
      gateway.isReachable = false;
      final LicenseSubscriptionRepo repo = buildRepo();

      await repo.refresh();

      expect(repo.statusListenable.value.isActive, isTrue);
    });

    test('silence past the grace window suspends the licence but keeps the key',
        () async {
      storage.record = storedLicence();
      clock = clock.add(AppLicensePolicy.offlineGrace + const Duration(days: 1));
      gateway.isReachable = false;
      final LicenseSubscriptionRepo repo = buildRepo();

      await repo.refresh();

      expect(repo.statusListenable.value.isActive, isFalse);
      // Kept, not cleared: the subscription may be alive behind a dead network,
      // and the next successful check restores it without the user hunting for
      // their key again.
      expect(storage.record, isNotNull);
      expect(storage.clearCallCount, 0);
    });

    test('a clock wound backwards changes nothing', () async {
      storage.record = storedLicence();
      clock = clock.subtract(const Duration(days: 400));
      gateway.isReachable = false;
      final LicenseSubscriptionRepo repo = buildRepo();

      await repo.refresh();

      // Negative elapsed time reads as none at all, which errs towards letting
      // a paying user work — the same direction the quota errs in.
      expect(repo.statusListenable.value.isActive, isTrue);
    });
  });

  group('buying', () {
    test('buying opens the checkout the service supplied, and claims nothing',
        () async {
      gateway.offers = <CheckoutOffer>[monthlyOffer];
      final LicenseSubscriptionRepo repo = buildRepo();
      await repo.loadPlans();

      final PurchaseOutcome outcome = await repo.purchase(monthly);

      expect(launcher.lastUrl, monthlyOffer.checkoutUrl);
      // Not `succeeded`: payment happens in a browser, and the entitlement only
      // arrives when the key comes back.
      expect(outcome, PurchaseOutcome.checkoutOpened);
      expect(repo.statusListenable.value.isActive, isFalse);
    });

    test('a plan the service never offered cannot be bought', () async {
      final LicenseSubscriptionRepo repo = buildRepo();
      await repo.loadPlans();

      expect(await repo.purchase(monthly), PurchaseOutcome.unavailable);
      expect(launcher.lastUrl, isNull);
    });

    test('a device with nothing to open a page with says so', () async {
      gateway.offers = <CheckoutOffer>[monthlyOffer];
      launcher.canOpen = false;
      final LicenseSubscriptionRepo repo = buildRepo();
      await repo.loadPlans();

      expect(await repo.purchase(monthly), PurchaseOutcome.failed);
    });

    test('plans are priced by the service, and empty when it cannot be reached',
        () async {
      gateway.offers = <CheckoutOffer>[monthlyOffer];
      final LicenseSubscriptionRepo repo = buildRepo();

      expect((await repo.loadPlans()).plans, <SubscriptionPlan>[monthly]);

      gateway.isReachable = false;

      // Nothing invented — and said as the unreachable service it was, which is
      // the case the paywall offers a retry for.
      final PlanCatalog catalog = await repo.loadPlans();

      expect(catalog.plans, isEmpty);
      expect(catalog.problem, CatalogProblem.storeUnreachable);
    });

    test('a service with an empty catalogue is a shut shop, not a silent one',
        () async {
      gateway.offers = const <CheckoutOffer>[];

      expect(
        (await buildRepo().loadPlans()).problem,
        CatalogProblem.nothingOnSale,
      );
    });
  });

  group('restoring', () {
    test('nothing stored is said plainly', () async {
      expect(await buildRepo().restore(), PurchaseOutcome.nothingToRestore);
      expect(gateway.validateCallCount, 0);
    });

    test('a renewed subscription comes back', () async {
      storage.record = storedLicence();
      final LicenseSubscriptionRepo repo = buildRepo();

      expect(await repo.restore(), PurchaseOutcome.succeeded);
      expect(repo.statusListenable.value.isActive, isTrue);
    });

    test('a cancelled subscription is forgotten and reported as lapsed',
        () async {
      storage.record = storedLicence();
      gateway.check = const LicenseCheck.refused(LicenseVerdict.inactive);
      final LicenseSubscriptionRepo repo = buildRepo();

      expect(await repo.restore(), PurchaseOutcome.subscriptionLapsed);
      expect(storage.record, isNull);
    });

    test('an unreachable service does not take the licence away', () async {
      storage.record = storedLicence();
      gateway.isReachable = false;
      final LicenseSubscriptionRepo repo = buildRepo();

      expect(await repo.restore(), PurchaseOutcome.failed);
      expect(storage.record, isNotNull);
    });
  });

  group('storage that will not answer', () {
    test('a store that cannot be written to still entitles this run', () async {
      storage.isBroken = true;
      final LicenseSubscriptionRepo repo = buildRepo();

      final PurchaseOutcome outcome = await repo.redeemLicenseKey('ARCX-KEY');

      // The user paid. A broken preferences file costs them the next launch, not
      // this one.
      expect(outcome, PurchaseOutcome.succeeded);
      expect(repo.statusListenable.value.isActive, isTrue);
    });

    test('a store that breaks mid-session keeps the entitlement it granted',
        () async {
      final LicenseSubscriptionRepo repo = buildRepo();
      await repo.redeemLicenseKey('ARCX-KEY');

      storage.isBroken = true;
      await repo.refresh();

      expect(repo.statusListenable.value.isActive, isTrue);
    });
  });
}

/// Rebuilds a check with an expiry, so the tests can state a renewal date
/// without spelling the whole constructor out again.
extension on LicenseCheck {
  LicenseCheck copyWithExpiry(DateTime expiresAt) => LicenseCheck(
        verdict: verdict,
        instanceId: instanceId,
        planId: planId,
        expiresAt: expiresAt,
      );
}
