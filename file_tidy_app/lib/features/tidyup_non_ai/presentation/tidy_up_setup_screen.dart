import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class TidyUpSetupScreen extends StatefulWidget {
  const TidyUpSetupScreen({super.key});

  @override
  State<TidyUpSetupScreen> createState() => _TidyUpSetupScreenState();
}

class _TidyUpSetupScreenState extends State<TidyUpSetupScreen> {
  bool _aiMode = false;
  bool _includeSummary = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tidy Up')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            const Text('Folder: /Travel/Japan'),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              value: _aiMode,
              onChanged: (value) => setState(() => _aiMode = value),
              title: const Text('Use AI mode'),
            ),
            SwitchListTile(
              value: _includeSummary,
              onChanged: (value) => setState(() => _includeSummary = value),
              title: const Text('Generate short summary'),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Rename style: Date + Place + Sequence'),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Preview changes',
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tidyUpReview),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
