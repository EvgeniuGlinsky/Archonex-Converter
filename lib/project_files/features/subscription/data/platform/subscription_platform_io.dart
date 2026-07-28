import 'dart:io';

import 'package:archonex_converter/project_files/features/subscription/data/free_only_subscription_repo.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Every platform that has a file system, and so a converter worth paying for.
SubscriptionRepo createSubscriptionRepo() =>
    FreeOnlySubscriptionRepo(channel: _channel);

/// Android, iOS and macOS ship through a store, and a store is the only way
/// they are allowed to charge for a digital subscription.
///
/// Windows and Linux have no store billing to reach from Flutter, so they buy
/// on the web and unlock with a licence key. Microsoft is the reason that is
/// not a compromise: it takes no cut at all from apps that bring their own
/// payments.
PurchaseChannel get _channel =>
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS
        ? PurchaseChannel.store
        : PurchaseChannel.licenseKey;
