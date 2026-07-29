import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archonex_converter/core/theme/app_theme.dart';
import 'package:archonex_converter/l10n/app_localizations.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/get_purchase_channel_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/load_subscription_plans_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/purchase_subscription_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/redeem_license_key_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/restore_purchases_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/data/use_cases/watch_subscription_status_use_case.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/plan_catalog.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/bloc/paywall_bloc.dart';
import 'package:archonex_converter/project_files/features/subscription/ui/paywall_view.dart';

import 'fakes.dart';

/// Tall enough that the whole body is built: it is a `ListView`, so anything
/// below the fold would simply not exist to find.
const Size _tallScreen = Size(1440, 2600);

void main() {
  late AppLocalizations en;

  const SubscriptionPlan monthly = SubscriptionPlan(
    id: 'pro.monthly',
    period: SubscriptionPeriod.monthly,
    priceLabel: r'$0.79',
  );

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  /// The bloc is built inside `BlocProvider.create` on purpose: created in
  /// `setUp` it would live in another async zone, and events added from the
  /// test would never be delivered.
  Future<void> pumpScreen(
    WidgetTester tester, {
    required FakeSubscriptionRepo repo,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = _tallScreen;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<PaywallBloc>(
          create: (_) => PaywallBloc(
            getPurchaseChannel: GetPurchaseChannelUseCase(repo),
            watchSubscriptionStatus: WatchSubscriptionStatusUseCase(repo),
            loadPlans: LoadSubscriptionPlansUseCase(repo),
            purchase: PurchaseSubscriptionUseCase(repo),
            redeemLicenseKey: RedeemLicenseKeyUseCase(repo),
            restorePurchases: RestorePurchasesUseCase(repo),
          )..add(const PaywallStarted()),
          child: const PaywallView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a store build shows the plans it can sell',
      (WidgetTester tester) async {
    await pumpScreen(
      tester,
      repo: FakeSubscriptionRepo(plans: const <SubscriptionPlan>[monthly]),
    );

    expect(find.text(en.paywallTitle), findsOneWidget);
    expect(find.text(en.paywallPeriodMonthly), findsOneWidget);
    expect(find.text(r'$0.79'), findsOneWidget);
    expect(find.text(en.paywallSubscribeLabel), findsOneWidget);
    expect(find.text(en.paywallRestoreLabel), findsOneWidget);
  });

  testWidgets('a shop with nothing in it says so rather than inventing a price',
      (WidgetTester tester) async {
    await pumpScreen(tester, repo: FakeSubscriptionRepo());

    expect(find.text(en.paywallNoPlansNotice), findsOneWidget);
    // No button at all rather than a dead one: there is nothing for it to do,
    // and a permanently greyed-out call to action only invites tapping.
    expect(find.text(en.paywallSubscribeLabel), findsNothing);
    // Nor a retry: the store answered, and it will answer the same again.
    expect(find.text(en.paywallRetryLabel), findsNothing);
  });

  testWidgets('a store that would not answer offers to be asked again',
      (WidgetTester tester) async {
    final FakeSubscriptionRepo repo = FakeSubscriptionRepo(
      emptyCatalogProblem: CatalogProblem.storeUnreachable,
    );

    await pumpScreen(tester, repo: repo);

    expect(find.text(en.paywallStoreUnreachableNotice), findsOneWidget);
    expect(find.text(en.paywallNoPlansNotice), findsNothing);

    // The store comes back, and the screen fills without being left and
    // re-entered.
    repo.plans = const <SubscriptionPlan>[monthly];
    await tester.tap(find.text(en.paywallRetryLabel));
    await tester.pumpAndSettle();

    expect(find.text(r'$0.79'), findsOneWidget);
    expect(find.text(en.paywallSubscribeLabel), findsOneWidget);
    expect(find.text(en.paywallStoreUnreachableNotice), findsNothing);
  });

  testWidgets('a licence build asks for a key and offers to re-check it',
      (WidgetTester tester) async {
    await pumpScreen(
      tester,
      repo: FakeSubscriptionRepo(channel: PurchaseChannel.licenseKey),
    );

    expect(find.text(en.paywallLicenseKeyTitle), findsOneWidget);
    expect(find.text(en.paywallBuyOnWebNotice), findsOneWidget);
    expect(find.text(en.paywallRedeemLabel), findsOneWidget);
    // Restoring re-asks the service about the key already on this device.
    expect(find.text(en.paywallRestoreLabel), findsOneWidget);
  });

  testWidgets('a licence build sells and activates on the same screen',
      (WidgetTester tester) async {
    await pumpScreen(
      tester,
      repo: FakeSubscriptionRepo(
        channel: PurchaseChannel.licenseKey,
        plans: const <SubscriptionPlan>[monthly],
      ),
    );

    expect(find.text(r'$0.79'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Buying leads, because that is what someone who has not paid came for;
    // activating is the quieter button for whoever already holds a key.
    expect(
      find.widgetWithText(FilledButton, en.paywallSubscribeLabel),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, en.paywallRedeemLabel),
      findsOneWidget,
    );
  });

  testWidgets('typing a key wakes the activate button up',
      (WidgetTester tester) async {
    await pumpScreen(
      tester,
      repo: FakeSubscriptionRepo(channel: PurchaseChannel.licenseKey),
    );

    Finder activate() =>
        find.widgetWithText(FilledButton, en.paywallRedeemLabel);

    expect(tester.widget<FilledButton>(activate()).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'ABC-123');
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(activate()).onPressed, isNotNull);
  });

  testWidgets('a build the store will not serve says where to buy instead',
      (WidgetTester tester) async {
    await pumpScreen(
      tester,
      repo: FakeSubscriptionRepo(channel: PurchaseChannel.storeBuildOnly),
    );

    expect(find.text(en.paywallStoreBuildOnlyNotice), findsOneWidget);
    // No button of any kind: this copy cannot take a payment, and offering one
    // would be offering something that fails.
    expect(find.text(en.paywallSubscribeLabel), findsNothing);
    expect(find.text(en.paywallRedeemLabel), findsNothing);
    expect(find.text(en.paywallRestoreLabel), findsNothing);
  });

  testWidgets('an entitled device is congratulated, not sold to',
      (WidgetTester tester) async {
    await pumpScreen(tester, repo: FakeSubscriptionRepo(isActive: true));

    expect(find.text(en.paywallActiveTitle), findsOneWidget);
    expect(find.text(en.paywallSubscribeLabel), findsNothing);
  });

  testWidgets('a finished purchase is announced once',
      (WidgetTester tester) async {
    await pumpScreen(
      tester,
      repo: FakeSubscriptionRepo(plans: const <SubscriptionPlan>[monthly]),
    );

    await tester.tap(find.text(en.paywallSubscribeLabel));
    await tester.pumpAndSettle();

    expect(find.text(en.purchaseSucceeded), findsOneWidget);
    expect(find.text(en.paywallActiveTitle), findsOneWidget);
  });
}
