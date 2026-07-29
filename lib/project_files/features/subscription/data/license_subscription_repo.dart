import 'package:flutter/foundation.dart';

import 'package:archonex_converter/core/constants/app_license_policy.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/checkout_launcher.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/license_gateway.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/license_storage.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/checkout_offer.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/license_check.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/license_record.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/plan_catalog.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_status.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// The paid tier as it actually ships: bought in a browser, unlocked with a
/// licence key.
///
/// **Why this and not store billing.** A build downloaded from GitHub Releases
/// cannot use Google Play billing at all — `BillingClient` refuses to serve an
/// app that Play did not install and sign — and no desktop platform offers
/// billing that Flutter can reach. One route that works everywhere beats a
/// store sheet that works in one place and shows a dead button in the rest.
///
/// **Where the rules live.** Every decision about clocks, expiry and what to do
/// when nobody answers is here; [LicenseStorage] only holds what these rules
/// produced, and [LicenseGateway] only carries questions and answers. That is
/// what lets all of it be tested without a network or a platform plugin.
///
/// **Which way it fails.** Silence from the service is not a refusal. An
/// unreachable service, a broken preferences file and a request that times out
/// all leave a paying user working, for [AppLicensePolicy.offlineGrace]. Only
/// the service saying *no* takes an entitlement away.
///
/// **What this does not defend against.** The check happens in the app, so a
/// user willing to patch the binary or forge a preferences file can have the
/// paid tier for free. Closing that needs the conversion itself to happen on a
/// server, which is the opposite of what this app is. The licence is a lock on
/// an honest door, and it is worth exactly what a receipt is worth.
class LicenseSubscriptionRepo implements SubscriptionRepo {
  LicenseSubscriptionRepo({
    required LicenseGateway gateway,
    required LicenseStorage storage,
    required CheckoutLauncher launcher,
    required String deviceName,
    DateTime Function()? now,
  })  : _gateway = gateway,
        _storage = storage,
        _launcher = launcher,
        _deviceName = deviceName,
        _now = now ?? DateTime.now;

  final LicenseGateway _gateway;
  final LicenseStorage _storage;
  final CheckoutLauncher _launcher;
  final String _deviceName;
  final DateTime Function() _now;

  final ValueNotifier<SubscriptionStatus> _status =
      ValueNotifier<SubscriptionStatus>(const SubscriptionStatus.free());

  /// The last licence this repository acted on, kept so a preferences file that
  /// stops answering mid-session does not cost the user their entitlement.
  LicenseRecord? _remembered;

  /// What the service last said was for sale. Held because a purchase needs the
  /// checkout URL that came with the plan, and `SubscriptionPlan` deliberately
  /// does not carry one — nothing above this layer should be able to open a
  /// payment page.
  List<CheckoutOffer> _offers = const <CheckoutOffer>[];

  @override
  PurchaseChannel get channel => PurchaseChannel.licenseKey;

  @override
  ValueListenable<SubscriptionStatus> get statusListenable => _status;

  @override
  Future<void> refresh() async {
    final LicenseRecord? stored = await _readStored();

    if (stored == null) {
      _status.value = const SubscriptionStatus.free();

      return;
    }

    // Trusted without asking until the day is up. An app whose whole pitch is
    // working offline should not spend a network round trip on every launch.
    if (!_isRevalidationDue(stored)) {
      _publish(stored);

      return;
    }

    await _revalidate(stored);
  }

  @override
  Future<PlanCatalog> loadPlans() async {
    try {
      _offers = await _gateway.loadOffers();
    } on LicenseServiceUnavailable {
      // Nothing shown and nothing invented, and said as the unreachable service
      // it was rather than as an empty shop: the paywall offers a retry for the
      // first and not for the second.
      _offers = const <CheckoutOffer>[];

      return const PlanCatalog.unavailable(CatalogProblem.storeUnreachable);
    }

    final List<SubscriptionPlan> plans = _offers
        .map((CheckoutOffer offer) => offer.plan)
        .toList(growable: false);

    if (plans.isEmpty) {
      return const PlanCatalog.unavailable(CatalogProblem.nothingOnSale);
    }

    return PlanCatalog.offered(plans);
  }

  /// Opens the checkout page and stops there.
  ///
  /// No entitlement can arrive from this call: payment finishes in a browser,
  /// and the key it produces comes back through [redeemLicenseKey]. Saying so
  /// with [PurchaseOutcome.checkoutOpened] is the point — a screen that reported
  /// success here would be claiming a purchase that has not happened.
  @override
  Future<PurchaseOutcome> purchase(SubscriptionPlan plan) async {
    final CheckoutOffer? offer = _offerFor(plan.id);

    if (offer == null) {
      return PurchaseOutcome.unavailable;
    }

    return await _launcher.open(offer.checkoutUrl)
        ? PurchaseOutcome.checkoutOpened
        : PurchaseOutcome.failed;
  }

  @override
  Future<PurchaseOutcome> redeemLicenseKey(String key) async {
    final String trimmed = key.trim();

    if (trimmed.isEmpty) {
      return PurchaseOutcome.invalidLicenseKey;
    }

    final LicenseCheck check;
    try {
      check = await _gateway.activate(key: trimmed, deviceName: _deviceName);
    } on LicenseServiceUnavailable {
      // Not `invalidLicenseKey`: the key was never judged. Telling someone
      // their key is bad because the network is down is how a support ticket
      // starts.
      return PurchaseOutcome.failed;
    }

    final LicenseRecord? activated = _recordFrom(trimmed, check);

    if (activated == null) {
      return _outcomeFor(check.verdict);
    }

    await _remember(activated);

    return PurchaseOutcome.succeeded;
  }

  @override
  Future<PurchaseOutcome> restore() async {
    final LicenseRecord? stored = await _readStored();

    if (stored == null) {
      return PurchaseOutcome.nothingToRestore;
    }

    final LicenseCheck check;
    try {
      check = await _gateway.validate(
        key: stored.key,
        instanceId: stored.instanceId,
      );
    } on LicenseServiceUnavailable {
      return PurchaseOutcome.failed;
    }

    if (check.isActive) {
      await _remember(stored.confirmedAt(_now(), expiresAt: check.expiresAt));

      return PurchaseOutcome.succeeded;
    }

    await _forget();

    return _outcomeFor(check.verdict);
  }

  Future<void> _revalidate(LicenseRecord stored) async {
    final LicenseCheck check;
    try {
      check = await _gateway.validate(
        key: stored.key,
        instanceId: stored.instanceId,
      );
    } on LicenseServiceUnavailable {
      _honourWithinGrace(stored);

      return;
    }

    if (check.isActive) {
      await _remember(stored.confirmedAt(_now(), expiresAt: check.expiresAt));

      return;
    }

    await _forget();
  }

  /// Silence, handled: the licence keeps working until the grace period runs
  /// out.
  ///
  /// The key is left on disk either way. It may well be a live subscription
  /// behind a dead network, and forgetting it would make the user find their
  /// key again to fix a problem they did not cause.
  void _honourWithinGrace(LicenseRecord stored) {
    if (_elapsedSince(stored.validatedAt) < AppLicensePolicy.offlineGrace) {
      _publish(stored);

      return;
    }

    _status.value = const SubscriptionStatus.free();
  }

  /// The record to store for an accepted key, or `null` when the service did
  /// not accept it.
  LicenseRecord? _recordFrom(String key, LicenseCheck check) {
    final String? instanceId = check.instanceId;
    final String? planId = check.planId;

    if (!check.isActive || instanceId == null || planId == null) {
      return null;
    }

    return LicenseRecord(
      key: key,
      instanceId: instanceId,
      planId: planId,
      validatedAt: _now(),
      expiresAt: check.expiresAt,
    );
  }

  CheckoutOffer? _offerFor(String planId) {
    for (final CheckoutOffer offer in _offers) {
      if (offer.plan.id == planId) {
        return offer;
      }
    }

    return null;
  }

  PurchaseOutcome _outcomeFor(LicenseVerdict verdict) => switch (verdict) {
        LicenseVerdict.active => PurchaseOutcome.succeeded,
        LicenseVerdict.inactive => PurchaseOutcome.subscriptionLapsed,
        // The existing copy for an invalid key already covers a used-up key,
        // and splitting them would tell an attacker which of their guesses was
        // a real key.
        LicenseVerdict.unknown ||
        LicenseVerdict.activationLimitReached =>
          PurchaseOutcome.invalidLicenseKey,
      };

  bool _isRevalidationDue(LicenseRecord stored) =>
      _elapsedSince(stored.validatedAt) >= AppLicensePolicy.revalidateAfter;

  /// How long since [moment], never negative.
  ///
  /// A clock wound backwards reads as negative time passing, and is treated as
  /// no time at all. That leaves a paying user working — the same direction the
  /// quota errs in, and for the same reason. It also means winding the clock
  /// back holds the grace period open, which is a hole an offline app cannot
  /// close and which costs at most one lapsed subscription.
  Duration _elapsedSince(DateTime moment) {
    final Duration elapsed = _now().difference(moment);

    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Storage that refuses to answer is treated as storage that agrees with what
  /// is already in memory, so a preferences file that breaks mid-session does
  /// not take away an entitlement this run already established.
  Future<LicenseRecord?> _readStored() async {
    try {
      return await _storage.read();
    } catch (_) {
      return _remembered;
    }
  }

  Future<void> _remember(LicenseRecord record) async {
    try {
      await _storage.write(record);
    } catch (_) {
      // The user paid. A store that will not take the write costs them the next
      // launch, not this one.
    }

    _publish(record);
  }

  Future<void> _forget() async {
    try {
      await _storage.clear();
    } catch (_) {
      // Nothing to do about it, and the entitlement goes away regardless.
    }

    _remembered = null;
    _status.value = const SubscriptionStatus.free();
  }

  void _publish(LicenseRecord record) {
    _remembered = record;
    _status.value = SubscriptionStatus.active(
      planId: record.planId,
      expiresAt: record.expiresAt,
    );
  }
}
