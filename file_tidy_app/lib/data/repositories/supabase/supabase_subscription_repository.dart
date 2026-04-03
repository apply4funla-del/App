import 'package:file_tidy_app/core/interfaces/subscription_repository.dart';
import 'package:file_tidy_app/core/models/subscription_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  SupabaseSubscriptionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<SubscriptionStatus> getStatus() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const SubscriptionStatus(
        plan: SubscriptionPlan.free,
        priceLabel: 'Free mode',
      );
    }

    final row = await _client
        .from('profiles')
        .select('subscription_tier, billing_cycle')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      return const SubscriptionStatus(
        plan: SubscriptionPlan.free,
        priceLabel: 'Free mode',
      );
    }

    final tier = row['subscription_tier'] as String? ?? 'free';
    final cycle = row['billing_cycle'] as String?;
    if (tier == 'usb_pro' && cycle == 'annual') {
      return const SubscriptionStatus(
        plan: SubscriptionPlan.usbAnnual,
        priceLabel: '\$3.90/month billed annually',
      );
    }
    if (tier == 'usb_pro' && cycle == 'monthly') {
      return const SubscriptionStatus(
        plan: SubscriptionPlan.usbMonthly,
        priceLabel: '\$8.90/month',
      );
    }
    return const SubscriptionStatus(
      plan: SubscriptionPlan.free,
      priceLabel: 'Free mode',
    );
  }
}
