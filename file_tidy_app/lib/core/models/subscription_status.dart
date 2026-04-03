enum SubscriptionPlan {
  free,
  usbMonthly,
  usbAnnual,
}

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.plan,
    this.priceLabel,
  });

  final SubscriptionPlan plan;
  final String? priceLabel;

  bool get isPaid => plan != SubscriptionPlan.free;
  bool get canUseUsbArchive => isPaid;

  String get label {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.usbMonthly:
        return 'USB Monthly';
      case SubscriptionPlan.usbAnnual:
        return 'USB Annual';
    }
  }
}
