import 'package:archonex_converter/project_files/features/subscription/domain/models/purchase_channel.dart';
import 'package:archonex_converter/project_files/features/subscription/domain/subscription_repo.dart';

/// Which route to money this build has, and so which paywall to draw.
class GetPurchaseChannelUseCase {
  const GetPurchaseChannelUseCase(this._repo);

  final SubscriptionRepo _repo;

  PurchaseChannel call() => _repo.channel;
}
