import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class TidyUpReviewScreen extends StatelessWidget {
  const TidyUpReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('IMG_4582.jpg', '2025-11-08-Kyoto-001.jpg'),
      ('IMG_4583.jpg', '2025-11-08-Kyoto-002.jpg'),
      ('IMG_4584.jpg', '2025-11-08-Kyoto-003.jpg'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Review Tidy Up')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ...rows.map(
            (row) => ListTile(
              title: Text(row.$1),
              subtitle: Text('-> ${row.$2}'),
            ),
          ),
          const Divider(),
          const Text('Summary: Kyoto day 1 photos'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              label: 'Approve and apply',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
