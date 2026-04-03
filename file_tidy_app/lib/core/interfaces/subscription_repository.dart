import 'package:file_tidy_app/core/models/subscription_status.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionStatus> getStatus();
}
