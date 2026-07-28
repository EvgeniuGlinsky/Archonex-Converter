import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:archonex_converter/core/constants/app_license_policy.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/license_gateway.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/checkout_offer.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/license_check.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';

/// The licence service over HTTP.
///
/// **The contract with the service.** Every answer the service *means* arrives
/// as `200`, including refusals — a dead key is `{"verdict":"inactive"}`, not a
/// `403`. Anything else at all, from a `500` to a timeout to a body that will
/// not parse, is [LicenseServiceUnavailable]. That one rule is what keeps "your
/// subscription ended" from ever being reported as "you are offline", and the
/// reverse.
///
/// No credentials are sent. The licence key is its own credential, which is why
/// this can live in a binary that anyone can download and read.
class HttpLicenseGateway implements LicenseGateway {
  HttpLicenseGateway({String? baseUrl, http.Client? client})
      : _baseUrl = _trimTrailingSlash(baseUrl ?? AppLicensePolicy.apiBaseUrl),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<List<CheckoutOffer>> loadOffers() async {
    final Map<String, Object?> body = await _send('GET', '/v1/offers');
    final Object? offers = body['offers'];

    if (offers is! List<Object?>) {
      throw const LicenseServiceUnavailable('offers missing from the response');
    }

    // One malformed entry is skipped rather than failing the list: a plan the
    // service describes in a way this build does not understand — a period
    // added later, say — must not hide the plans it does understand.
    return offers
        .map(_offer)
        .whereType<CheckoutOffer>()
        .toList(growable: false);
  }

  @override
  Future<LicenseCheck> activate({
    required String key,
    required String deviceName,
  }) async {
    return _check(
      await _send('POST', '/v1/licenses/activate', <String, Object?>{
        'key': key,
        'deviceName': deviceName,
      }),
    );
  }

  @override
  Future<LicenseCheck> validate({
    required String key,
    required String instanceId,
  }) async {
    return _check(
      await _send('POST', '/v1/licenses/validate', <String, Object?>{
        'key': key,
        'instanceId': instanceId,
      }),
    );
  }

  CheckoutOffer? _offer(Object? entry) {
    if (entry is! Map<String, Object?>) {
      return null;
    }

    final Object? id = entry['id'];
    final Object? priceLabel = entry['priceLabel'];
    final Object? checkoutUrl = entry['checkoutUrl'];
    final SubscriptionPeriod? period = _period(entry['period']);

    if (id is! String ||
        priceLabel is! String ||
        checkoutUrl is! String ||
        period == null) {
      return null;
    }

    final Uri? url = Uri.tryParse(checkoutUrl);
    // http, and only http: this URL is handed to the operating system to open,
    // and a service that has been tampered with must not be able to point it at
    // an arbitrary scheme.
    if (url == null || (url.scheme != 'https' && url.scheme != 'http')) {
      return null;
    }

    return CheckoutOffer(
      plan: SubscriptionPlan(id: id, period: period, priceLabel: priceLabel),
      checkoutUrl: url,
    );
  }

  SubscriptionPeriod? _period(Object? raw) => switch (raw) {
        'monthly' => SubscriptionPeriod.monthly,
        'yearly' => SubscriptionPeriod.yearly,
        _ => null,
      };

  /// A verdict this build does not recognise is read as
  /// [LicenseVerdict.unknown] rather than as an outage: the service *did*
  /// answer, and it did not say the licence was good.
  LicenseCheck _check(Map<String, Object?> body) {
    final LicenseVerdict verdict = switch (body['verdict']) {
      'active' => LicenseVerdict.active,
      'inactive' => LicenseVerdict.inactive,
      'activationLimitReached' => LicenseVerdict.activationLimitReached,
      _ => LicenseVerdict.unknown,
    };

    if (verdict != LicenseVerdict.active) {
      return LicenseCheck.refused(verdict);
    }

    final Object? instanceId = body['instanceId'];
    final Object? planId = body['planId'];

    // An "active" answer with nothing to identify it cannot be stored, and
    // storing it half-formed would strand this device between states.
    if (instanceId is! String || planId is! String) {
      throw const LicenseServiceUnavailable('active verdict without identity');
    }

    final Object? expiresAt = body['expiresAt'];

    return LicenseCheck(
      verdict: LicenseVerdict.active,
      instanceId: instanceId,
      planId: planId,
      expiresAt: expiresAt is String ? DateTime.tryParse(expiresAt) : null,
    );
  }

  Future<Map<String, Object?>> _send(
    String method,
    String path, [
    Map<String, Object?>? payload,
  ]) async {
    final Uri url = Uri.parse('$_baseUrl$path');

    final http.Response response;
    try {
      final Future<http.Response> pending = payload == null
          ? _client.get(url, headers: _headers)
          : _client.post(url, headers: _headers, body: jsonEncode(payload));

      response = await pending.timeout(AppLicensePolicy.requestTimeout);
    } on TimeoutException {
      throw const LicenseServiceUnavailable('timed out');
    } catch (error) {
      throw LicenseServiceUnavailable('$error');
    }

    if (response.statusCode != 200) {
      throw LicenseServiceUnavailable('HTTP ${response.statusCode}');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const LicenseServiceUnavailable('body is not JSON');
    }

    if (decoded is! Map<String, Object?>) {
      throw const LicenseServiceUnavailable('body is not a JSON object');
    }

    return decoded;
  }

  static const Map<String, String> _headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static String _trimTrailingSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
