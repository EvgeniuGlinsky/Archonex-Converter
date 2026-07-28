import 'package:url_launcher/url_launcher.dart';

import 'package:archonex_converter/project_files/features/subscription/domain/checkout_launcher.dart';

/// Hands the checkout page to whatever the device uses to browse.
///
/// [LaunchMode.externalApplication] rather than an in-app web view: this is a
/// payment form, and a user is entitled to see it in a browser that shows them
/// the address and the padlock.
class UrlCheckoutLauncher implements CheckoutLauncher {
  const UrlCheckoutLauncher();

  @override
  Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // A device with nothing registered for https throws rather than returning
      // false. Either way the user did not get a checkout page, and the paywall
      // says so.
      return false;
    }
  }
}
