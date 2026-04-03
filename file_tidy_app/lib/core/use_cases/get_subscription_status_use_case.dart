import 'package:file_tidy_app/core/interfaces/subscription_repository.dart';
import 'package:file_tidy_app/core/models/subscription_status.dart';

class GetSubscriptionStatusUseCase {
  const GetSubscriptionStatusUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<SubscriptionStatus> call() {
    return _repository.getStatus();
  }
}
