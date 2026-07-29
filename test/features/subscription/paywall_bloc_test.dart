import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/project_files/features/subscription/data/use_cases/get_purchase_channel_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/load_subscription_plans_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/purchase_subscription_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/redeem_license_key_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/restore_purchases_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/watch_subscription_status_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/plan_catalog.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/bloc/paywall_bloc.dart';

import 'fakes.dart';

void main() {
  late FakeSubscriptionRepo repo;
  late PaywallBloc bloc;

  const SubscriptionPlan monthly = SubscriptionPlan(
    id: 'pro.monthly',
    period: SubscriptionPeriod.monthly,
    priceLabel: r'$0.79',
  );
  const SubscriptionPlan yearly = SubscriptionPlan(
    id: 'pro.yearly',
    period: SubscriptionPeriod.yearly,
    priceLabel: r'$7.99',
  );

  void buildBloc() {
    bloc = PaywallBloc(
      getPurchaseChannel: GetPurchaseChannelUseCase(repo),
      watchSubscriptionStatus: WatchSubscriptionStatusUseCase(repo),
      loadPlans: LoadSubscriptionPlansUseCase(repo),
      purchase: PurchaseSubscriptionUseCase(repo),
      redeemLicenseKey: RedeemLicenseKeyUseCase(repo),
      restorePurchases: RestorePurchasesUseCase(repo),
    )..add(const PaywallStarted());
  }

  setUp(() {
    repo = FakeSubscriptionRepo(plans: <SubscriptionPlan>[monthly, yearly]);
  });

  tearDown(() => bloc.close());

  /// Lets the bloc drain its event queue and any awaited futures.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('opening', () {
    test('loads what the store sells', () async {
      buildBloc();
      await settle();

      expect(bloc.state.status, PaywallStatus.ready);
      expect(bloc.state.plans, <SubscriptionPlan>[monthly, yearly]);
      expect(bloc.state.channel, PurchaseChannel.store);
    });

    test('preselects the yearly plan, which is the cheaper way to pay',
        () async {
      buildBloc();
      await settle();

      expect(bloc.state.selectedPlanId, yearly.id);
      expect(bloc.state.canSubscribe, isTrue);
    });

    test('an empty shop offers nothing to buy', () async {
      repo.plans = const <SubscriptionPlan>[];
      buildBloc();
      await settle();

      expect(bloc.state.plans, isEmpty);
      expect(bloc.state.selectedPlanId, isNull);
      expect(bloc.state.canSubscribe, isFalse);
      expect(bloc.state.showsNoPlansNotice, isTrue);
      // Asking a shop that answered again would only hear the same answer.
      expect(bloc.state.canRetryPlans, isFalse);
    });

    test('a store that would not answer is told apart from an empty shop',
        () async {
      repo
        ..plans = const <SubscriptionPlan>[]
        ..emptyCatalogProblem = CatalogProblem.storeUnreachable;
      buildBloc();
      await settle();

      expect(bloc.state.showsStoreUnreachableNotice, isTrue);
      expect(bloc.state.showsNoPlansNotice, isFalse);
      expect(bloc.state.canRetryPlans, isTrue);
    });

    test('a device that is already subscribed says so', () async {
      repo.activate();
      buildBloc();
      await settle();

      expect(bloc.state.isSubscribed, isTrue);
      expect(bloc.state.canSubscribe, isFalse);
    });
  });

  group('trying the store again', () {
    setUp(() {
      repo
        ..plans = const <SubscriptionPlan>[]
        ..emptyCatalogProblem = CatalogProblem.storeUnreachable;
    });

    test('a store that answers the second time fills the screen', () async {
      buildBloc();
      await settle();

      repo.plans = <SubscriptionPlan>[monthly, yearly];
      bloc.add(const PaywallPlansRetried());
      await settle();

      expect(bloc.state.plans, <SubscriptionPlan>[monthly, yearly]);
      expect(bloc.state.catalogProblem, isNull);
      expect(bloc.state.selectedPlanId, yearly.id);
      expect(bloc.state.canSubscribe, isTrue);
      expect(bloc.state.status, PaywallStatus.ready);
    });

    test('a store still silent leaves the retry offered', () async {
      buildBloc();
      await settle();

      bloc.add(const PaywallPlansRetried());
      await settle();

      expect(bloc.state.canRetryPlans, isTrue);
      expect(repo.loadPlansCallCount, 2);
    });

    test('an empty shop is never retried, however often it is tapped',
        () async {
      repo.emptyCatalogProblem = CatalogProblem.nothingOnSale;
      buildBloc();
      await settle();

      bloc.add(const PaywallPlansRetried());
      await settle();

      // The guard is in the bloc as well as in the widget: a screen that stopped
      // drawing the button is not what makes the rule true.
      expect(repo.loadPlansCallCount, 1);
    });

    test('a screen already showing plans has nothing to retry', () async {
      repo.plans = <SubscriptionPlan>[monthly, yearly];
      buildBloc();
      await settle();

      bloc.add(const PaywallPlansRetried());
      await settle();

      expect(repo.loadPlansCallCount, 1);
      expect(bloc.state.selectedPlanId, yearly.id);
    });
  });

  group('buying', () {
    test('buys the selected plan and reports the outcome', () async {
      buildBloc();
      await settle();

      bloc.add(const PaywallPlanSelected('pro.monthly'));
      await settle();
      bloc.add(const PaywallSubscribeRequested());
      await settle();

      expect(repo.lastPurchasedPlan, monthly);
      expect(bloc.state.outcome, PurchaseOutcome.succeeded);
      expect(bloc.state.status, PaywallStatus.ready);
    });

    test('the entitlement comes from the status, not from the outcome',
        () async {
      buildBloc();
      await settle();

      bloc.add(const PaywallSubscribeRequested());
      await settle();

      expect(bloc.state.isSubscribed, isTrue);
    });

    test('a cancelled purchase leaves the device where it was', () async {
      repo.outcome = PurchaseOutcome.cancelled;
      buildBloc();
      await settle();

      bloc.add(const PaywallSubscribeRequested());
      await settle();

      expect(bloc.state.outcome, PurchaseOutcome.cancelled);
      expect(bloc.state.isSubscribed, isFalse);
    });
  });

  group('licence keys', () {
    setUp(() {
      repo = FakeSubscriptionRepo(channel: PurchaseChannel.licenseKey);
    });

    test('a licence build asks for a key and offers to re-check it', () async {
      buildBloc();
      await settle();

      expect(bloc.state.showsLicenseKeyField, isTrue);
      // This fake sells nothing, so there is no price to show.
      expect(bloc.state.showsPlans, isFalse);
      // Restoring re-asks the service about the key already on this device,
      // which is how a renewal after a lapse is picked up.
      expect(bloc.state.showsRestore, isTrue);
    });

    test('a licence build prices what it sells, next to the key field',
        () async {
      repo = FakeSubscriptionRepo(
        channel: PurchaseChannel.licenseKey,
        plans: <SubscriptionPlan>[monthly, yearly],
      );
      buildBloc();
      await settle();

      // Both halves of one flow: buy in a browser, come back and paste the key.
      expect(bloc.state.showsPlans, isTrue);
      expect(bloc.state.showsLicenseKeyField, isTrue);
      expect(bloc.state.selectedPlanId, yearly.id);
    });

    test('an empty field cannot be submitted', () async {
      buildBloc();
      await settle();

      bloc.add(const PaywallLicenseKeyChanged('   '));
      await settle();

      expect(bloc.state.canRedeem, isFalse);
    });

    test('a pasted key is trimmed before it is judged', () async {
      buildBloc();
      await settle();

      bloc.add(const PaywallLicenseKeyChanged('  ABC-123\n'));
      await settle();
      bloc.add(const PaywallLicenseKeyRedeemRequested());
      await settle();

      expect(repo.lastRedeemedKey, 'ABC-123');
      expect(bloc.state.isSubscribed, isTrue);
    });

    test('a rejected key says so and changes nothing', () async {
      repo.outcome = PurchaseOutcome.invalidLicenseKey;
      buildBloc();
      await settle();

      bloc.add(const PaywallLicenseKeyChanged('nope'));
      await settle();
      bloc.add(const PaywallLicenseKeyRedeemRequested());
      await settle();

      expect(bloc.state.outcome, PurchaseOutcome.invalidLicenseKey);
      expect(bloc.state.isSubscribed, isFalse);
    });
  });

  group('restoring', () {
    test('brings back a purchase the store still remembers', () async {
      buildBloc();
      await settle();

      bloc.add(const PaywallRestoreRequested());
      await settle();

      expect(repo.restoreCallCount, 1);
      expect(bloc.state.isSubscribed, isTrue);
    });

    test('says plainly when there is nothing to bring back', () async {
      repo.outcome = PurchaseOutcome.nothingToRestore;
      buildBloc();
      await settle();

      bloc.add(const PaywallRestoreRequested());
      await settle();

      expect(bloc.state.outcome, PurchaseOutcome.nothingToRestore);
      expect(bloc.state.isSubscribed, isFalse);
    });
  });
}
