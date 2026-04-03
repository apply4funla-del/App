import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/models/subscription_status.dart';
import 'package:file_tidy_app/core/use_cases/get_current_user_use_case.dart';
import 'package:file_tidy_app/core/use_cases/get_subscription_status_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _dependencies = DependencyContainer.instance;

  late final GetSubscriptionStatusUseCase _getSubscriptionStatusUseCase;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  SubscriptionStatus _status = const SubscriptionStatus(plan: SubscriptionPlan.free);
  String? _email;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getSubscriptionStatusUseCase = GetSubscriptionStatusUseCase(_dependencies.subscriptionRepository);
    _getCurrentUserUseCase = GetCurrentUserUseCase(_dependencies.appAuthRepository);
    _load();
  }

  Future<void> _load() async {
    final currentUser = await _getCurrentUserUseCase();
    final status = await _getSubscriptionStatusUseCase();
    if (!mounted) {
      return;
    }
    setState(() {
      _email = currentUser?.email;
      _status = status;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  _email == null
                      ? 'Sign in first to restore or manage a paid USB plan.'
                      : 'Signed in as $_email',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Current plan: ${_status.label}'),
                if (_status.priceLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(_status.priceLabel!),
                ],
                const SizedBox(height: AppSpacing.lg),
                _PlanCard(
                  title: 'Free',
                  price: '\$0',
                  points: const [
                    'Use the app for free on local phone files',
                    'Sign in to access Google Drive and Dropbox',
                    'USB archive is locked on free plan',
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _PlanCard(
                  title: 'USB Annual',
                  price: '\$3.90/month billed yearly',
                  highlight: true,
                  points: const [
                    'Unlock USB archive',
                    'Use Archive Memories flow',
                    'Best value annual plan',
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _PlanCard(
                  title: 'USB Monthly',
                  price: '\$8.90/month',
                  points: const [
                    'Unlock USB archive',
                    'Monthly flexibility',
                    'Cancel anytime once billing is added',
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_email == null)
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      label: 'Sign In',
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signIn),
                    ),
                  )
                else
                  const Text(
                    'Billing integration comes next. For now, USB access checks the plan stored for your signed-in account in Supabase.',
                  ),
              ],
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.points,
    this.highlight = false,
  });

  final String title;
  final String price;
  final List<String> points;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: highlight ? colorScheme.primary.withValues(alpha: 0.08) : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(price, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final point in points) ...[
              Text('• $point'),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}
