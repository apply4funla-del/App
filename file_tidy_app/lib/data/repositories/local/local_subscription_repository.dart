import 'package:file_tidy_app/core/interfaces/subscription_repository.dart';
import 'package:file_tidy_app/core/models/subscription_status.dart';

class LocalSubscriptionRepository implements SubscriptionRepository {
  const LocalSubscriptionRepository();

  @override
  Future<SubscriptionStatus> getStatus() async {
    return const SubscriptionStatus(
      plan: SubscriptionPlan.free,
      priceLabel: 'Free mode',
    );
  }
}
