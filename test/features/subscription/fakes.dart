import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:archonex_converter/project_files/features/subscription/domain/checkout_launcher.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/license_gateway.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/license_storage.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/checkout_offer.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/license_check.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/license_record.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_outcome.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_status.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Subscription state driven entirely by the test.
///
/// A successful attempt flips the entitlement, the way a real store would:
/// nothing in the app sets the status from a return value, so a fake that only
/// returned [PurchaseOutcome.succeeded] would never prove the screen reacts.
class FakeSubscriptionRepo implements SubscriptionRepo {
  FakeSubscriptionRepo({
    this.channel = PurchaseChannel.store,
    this.plans = const <SubscriptionPlan>[],
    this.outcome = PurchaseOutcome.succeeded,
    bool isActive = false,
  }) : _status = ValueNotifier<SubscriptionStatus>(
          isActive
              ? const SubscriptionStatus.active(planId: activePlanId)
              : const SubscriptionStatus.free(),
        );

  static const String activePlanId = 'test.plan.monthly';

  @override
  PurchaseChannel channel;

  List<SubscriptionPlan> plans;

  /// What the next purchase, redemption or restore returns.
  PurchaseOutcome outcome;

  final ValueNotifier<SubscriptionStatus> _status;

  int refreshCallCount = 0;
  int restoreCallCount = 0;
  SubscriptionPlan? lastPurchasedPlan;
  String? lastRedeemedKey;

  @override
  ValueListenable<SubscriptionStatus> get statusListenable => _status;

  @override
  Future<void> refresh() async => refreshCallCount++;

  @override
  Future<List<SubscriptionPlan>> loadPlans() async => plans;

  @override
  Future<PurchaseOutcome> purchase(SubscriptionPlan plan) async {
    lastPurchasedPlan = plan;

    return _settle();
  }

  @override
  Future<PurchaseOutcome> redeemLicenseKey(String key) async {
    lastRedeemedKey = key;

    return _settle();
  }

  @override
  Future<PurchaseOutcome> restore() async {
    restoreCallCount++;

    return _settle();
  }

  /// Turns the entitlement on without a purchase, for setting a test up.
  void activate() =>
      _status.value = const SubscriptionStatus.active(planId: activePlanId);

  PurchaseOutcome _settle() {
    if (outcome == PurchaseOutcome.succeeded) {
      activate();
    }

    return outcome;
  }
}

/// A licence service that answers whatever the test set up.
///
/// [isReachable] is the distinction the whole design turns on: unreachable
/// throws, exactly as the real gateway does, so a test can tell "the service
/// said no" apart from "nobody answered" — and prove the app treats them
/// differently.
class FakeLicenseGateway implements LicenseGateway {
  FakeLicenseGateway({
    this.offers = const <CheckoutOffer>[],
    this.check = activeCheck,
    this.isReachable = true,
  });

  static const String instanceId = 'instance-1';
  static const String planId = 'pro.monthly';

  static const LicenseCheck activeCheck = LicenseCheck(
    verdict: LicenseVerdict.active,
    instanceId: instanceId,
    planId: planId,
  );

  List<CheckoutOffer> offers;

  /// What the next `activate` or `validate` answers.
  LicenseCheck check;

  bool isReachable;

  int activateCallCount = 0;
  int validateCallCount = 0;
  String? lastKey;
  String? lastDeviceName;
  String? lastInstanceId;

  @override
  Future<List<CheckoutOffer>> loadOffers() async {
    _requireReachable();

    return offers;
  }

  @override
  Future<LicenseCheck> activate({
    required String key,
    required String deviceName,
  }) async {
    activateCallCount++;
    lastKey = key;
    lastDeviceName = deviceName;
    _requireReachable();

    return check;
  }

  @override
  Future<LicenseCheck> validate({
    required String key,
    required String instanceId,
  }) async {
    validateCallCount++;
    lastKey = key;
    lastInstanceId = instanceId;
    _requireReachable();

    return check;
  }

  /// Counted before the throw, so a test can still prove the call was made.
  void _requireReachable() {
    if (!isReachable) {
      throw const LicenseServiceUnavailable('fake is offline');
    }
  }
}

/// Licence storage in memory, with a switch for a store that refuses to work.
class FakeLicenseStorage implements LicenseStorage {
  FakeLicenseStorage([this.record]);

  LicenseRecord? record;

  /// Reads and writes throw while this is set, standing in for unreadable
  /// preferences or a build with no plugin registered.
  bool isBroken = false;

  int writeCallCount = 0;
  int clearCallCount = 0;

  @override
  Future<LicenseRecord?> read() async {
    if (isBroken) {
      throw Exception('storage is unavailable');
    }

    return record;
  }

  @override
  Future<void> write(LicenseRecord record) async {
    writeCallCount++;

    if (isBroken) {
      throw Exception('storage is unavailable');
    }

    this.record = record;
  }

  @override
  Future<void> clear() async {
    clearCallCount++;
    record = null;
  }
}

/// Stands in for the browser, and remembers where it was pointed.
class FakeCheckoutLauncher implements CheckoutLauncher {
  FakeCheckoutLauncher({this.canOpen = true});

  /// `false` for a device with nothing registered to open a web page.
  bool canOpen;

  Uri? lastUrl;

  @override
  Future<bool> open(Uri url) async {
    lastUrl = url;

    return canOpen;
  }
}

/// An HTTP client that answers from the test instead of from a network.
///
/// Hand written rather than `MockClient`, to keep the rule that the fakes in
/// this project are readable code and not a mocking framework's output.
class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this._respond);

  /// Given the request and its body, returns the status and body to answer
  /// with.
  final http.Response Function(http.BaseRequest request, String body) _respond;

  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  final List<String> bodies = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String body = request is http.Request ? request.body : '';
    requests.add(request);
    bodies.add(body);

    final http.Response response = _respond(request, body);

    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
    );
  }
}
