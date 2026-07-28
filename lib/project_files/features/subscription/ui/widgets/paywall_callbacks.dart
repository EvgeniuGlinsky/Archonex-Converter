import 'package:flutter/foundation.dart';

/// Everything the paywall can be asked to do, in one bundle.
///
/// Same reason as `ImageConverterCallbacks`: the widgets stay unaware of their
/// parent, and no signature turns into a wall of arguments.
@immutable
class PaywallCallbacks {
  const PaywallCallbacks({
    required this.onPlanSelected,
    required this.onLicenseKeyChanged,
    required this.onRedeemPressed,
    required this.onSubscribePressed,
    required this.onRestorePressed,
  });

  final ValueChanged<String> onPlanSelected;
  final ValueChanged<String> onLicenseKeyChanged;
  final VoidCallback onRedeemPressed;
  final VoidCallback onSubscribePressed;
  final VoidCallback onRestorePressed;
}
