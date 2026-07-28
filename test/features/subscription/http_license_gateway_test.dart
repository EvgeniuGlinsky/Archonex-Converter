import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:archonex_converter/project_files/features/subscription/data/license/http_license_gateway.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/license_gateway.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/checkout_offer.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/license_check.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/subscription_plan.dart';

import 'fakes.dart';

/// The contract with the licence service, from the app's side.
///
/// The rule these tests exist to pin down: every answer the service *means*
/// arrives as 200, and everything else is an outage. Get that wrong and the app
/// starts telling offline users their subscription ended.
void main() {
  const String baseUrl = 'https://licence.example.com';

  HttpLicenseGateway gatewayReturning(
    int status,
    Object? body, {
    FakeHttpClient? spy,
  }) {
    final FakeHttpClient client = spy ??
        FakeHttpClient(
          (_, _) => http.Response(
            body is String ? body : jsonEncode(body),
            status,
          ),
        );

    return HttpLicenseGateway(baseUrl: baseUrl, client: client);
  }

  group('offers', () {
    test('a plan is read with the price and link the service supplied',
        () async {
      final HttpLicenseGateway gateway = gatewayReturning(200, <String, Object?>{
        'offers': <Object?>[
          <String, Object?>{
            'id': 'pri_monthly',
            'period': 'monthly',
            'priceLabel': r'$4.99 / month',
            'checkoutUrl': 'https://pay.example.com/m',
          },
        ],
      });

      final List<CheckoutOffer> offers = await gateway.loadOffers();

      expect(offers, hasLength(1));
      expect(offers.single.plan.id, 'pri_monthly');
      expect(offers.single.plan.period, SubscriptionPeriod.monthly);
      expect(offers.single.plan.priceLabel, r'$4.99 / month');
      expect(offers.single.checkoutUrl, Uri.parse('https://pay.example.com/m'));
    });

    test('an empty list is a real answer and means the shop is shut', () async {
      final HttpLicenseGateway gateway = gatewayReturning(
        200,
        <String, Object?>{'offers': <Object?>[]},
      );

      expect(await gateway.loadOffers(), isEmpty);
    });

    test('one unreadable plan does not hide the readable ones', () async {
      final HttpLicenseGateway gateway = gatewayReturning(200, <String, Object?>{
        'offers': <Object?>[
          // A period this build has never heard of.
          <String, Object?>{
            'id': 'pri_weekly',
            'period': 'weekly',
            'priceLabel': r'$1.99',
            'checkoutUrl': 'https://pay.example.com/w',
          },
          // No price at all.
          <String, Object?>{
            'id': 'pri_yearly',
            'period': 'yearly',
            'checkoutUrl': 'https://pay.example.com/y',
          },
          <String, Object?>{
            'id': 'pri_monthly',
            'period': 'monthly',
            'priceLabel': r'$4.99',
            'checkoutUrl': 'https://pay.example.com/m',
          },
        ],
      });

      final List<CheckoutOffer> offers = await gateway.loadOffers();

      expect(offers.map((CheckoutOffer o) => o.plan.id), <String>['pri_monthly']);
    });

    test('a checkout link that is not web is refused', () async {
      // This URL is handed to the operating system to open. A service that has
      // been tampered with must not be able to point it anywhere it likes.
      final HttpLicenseGateway gateway = gatewayReturning(200, <String, Object?>{
        'offers': <Object?>[
          <String, Object?>{
            'id': 'pri_monthly',
            'period': 'monthly',
            'priceLabel': r'$4.99',
            'checkoutUrl': 'file:///etc/passwd',
          },
        ],
      });

      expect(await gateway.loadOffers(), isEmpty);
    });

    test('a response with no offers field is an outage', () async {
      final HttpLicenseGateway gateway =
          gatewayReturning(200, <String, Object?>{'plans': <Object?>[]});

      expect(gateway.loadOffers(), throwsA(isA<LicenseServiceUnavailable>()));
    });
  });

  group('verdicts', () {
    test('a refusal arrives as 200 and becomes a verdict', () async {
      final HttpLicenseGateway gateway =
          gatewayReturning(200, <String, Object?>{'verdict': 'inactive'});

      final LicenseCheck check =
          await gateway.validate(key: 'K', instanceId: 'I');

      expect(check.verdict, LicenseVerdict.inactive);
      expect(check.isActive, isFalse);
    });

    test('an accepted key comes back with its identity', () async {
      final HttpLicenseGateway gateway = gatewayReturning(200, <String, Object?>{
        'verdict': 'active',
        'instanceId': 'inst_9',
        'planId': 'pri_monthly',
        'expiresAt': '2026-08-28T09:00:00.000Z',
      });

      final LicenseCheck check =
          await gateway.activate(key: 'K', deviceName: 'laptop');

      expect(check.verdict, LicenseVerdict.active);
      expect(check.instanceId, 'inst_9');
      expect(check.planId, 'pri_monthly');
      expect(check.expiresAt, DateTime.utc(2026, 8, 28, 9));
    });

    test('a verdict this build does not know is unknown, not an outage',
        () async {
      // The service answered, and it did not say the licence was good. That is
      // information, and treating it as an outage would grant a grace period to
      // a licence the service just refused.
      final HttpLicenseGateway gateway = gatewayReturning(
        200,
        <String, Object?>{'verdict': 'quarantined'},
      );

      expect(
        (await gateway.validate(key: 'K', instanceId: 'I')).verdict,
        LicenseVerdict.unknown,
      );
    });

    test('an active answer with nothing to identify it is an outage', () async {
      final HttpLicenseGateway gateway =
          gatewayReturning(200, <String, Object?>{'verdict': 'active'});

      expect(
        gateway.validate(key: 'K', instanceId: 'I'),
        throwsA(isA<LicenseServiceUnavailable>()),
      );
    });

    test('the key and the device name are what gets posted', () async {
      final FakeHttpClient spy = FakeHttpClient(
        (_, _) => http.Response(
          jsonEncode(<String, Object?>{
            'verdict': 'active',
            'instanceId': 'inst_9',
            'planId': 'pri_monthly',
          }),
          200,
        ),
      );
      final HttpLicenseGateway gateway = gatewayReturning(200, null, spy: spy);

      await gateway.activate(key: 'ARCX-KEY', deviceName: 'laptop (windows)');

      expect(
        spy.requests.single.url,
        Uri.parse('$baseUrl/v1/licenses/activate'),
      );
      expect(
        jsonDecode(spy.bodies.single),
        <String, Object?>{'key': 'ARCX-KEY', 'deviceName': 'laptop (windows)'},
      );
    });
  });

  group('outages', () {
    test('a server error is an outage, never a refusal', () async {
      final HttpLicenseGateway gateway =
          gatewayReturning(500, <String, Object?>{'verdict': 'inactive'});

      expect(
        gateway.validate(key: 'K', instanceId: 'I'),
        throwsA(isA<LicenseServiceUnavailable>()),
      );
    });

    test('a body that is not JSON is an outage', () async {
      final HttpLicenseGateway gateway =
          gatewayReturning(200, '<html>maintenance</html>');

      expect(gateway.loadOffers(), throwsA(isA<LicenseServiceUnavailable>()));
    });

    test('a client that throws is an outage', () async {
      final HttpLicenseGateway gateway = HttpLicenseGateway(
        baseUrl: baseUrl,
        client: FakeHttpClient((_, _) => throw const SocketFailure()),
      );

      expect(gateway.loadOffers(), throwsA(isA<LicenseServiceUnavailable>()));
    });
  });

  test('a trailing slash on the base URL does not double up in the path',
      () async {
    final FakeHttpClient spy = FakeHttpClient(
      (_, _) => http.Response(
        jsonEncode(<String, Object?>{'offers': <Object?>[]}),
        200,
      ),
    );
    final HttpLicenseGateway gateway =
        HttpLicenseGateway(baseUrl: '$baseUrl/', client: spy);

    await gateway.loadOffers();

    expect(spy.requests.single.url, Uri.parse('$baseUrl/v1/offers'));
  });
}

/// Stands in for whatever the platform's socket layer throws when there is no
/// network. Its type does not matter — only that the gateway catches it.
class SocketFailure implements Exception {
  const SocketFailure();
}
