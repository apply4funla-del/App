import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Free'),
            SizedBox(height: AppSpacing.xs),
            Text('- Manual rename'),
            Text('- Basic tidy up'),
            SizedBox(height: AppSpacing.md),
            Text('Pro Local'),
            SizedBox(height: AppSpacing.xs),
            Text('- Batch rename'),
            Text('- Templates and history tools'),
            SizedBox(height: AppSpacing.md),
            Text('Pro AI add-on'),
            SizedBox(height: AppSpacing.xs),
            Text('- AI rename suggestions'),
            Text('- AI folder summaries'),
          ],
        ),
      ),
    );
  }
}
