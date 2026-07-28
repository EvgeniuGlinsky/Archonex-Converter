import 'package:archonex_converter/project_files/features/subscription/data/free_only_subscription_repo.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// The web build has no converters to unlock, so it has nothing to sell.
SubscriptionRepo createSubscriptionRepo() =>
    FreeOnlySubscriptionRepo(channel: PurchaseChannel.unavailable);
