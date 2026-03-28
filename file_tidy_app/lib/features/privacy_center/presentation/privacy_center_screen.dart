import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  bool _aiEnabled = true;
  bool _semiAuto = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Center')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              value: _aiEnabled,
              onChanged: (value) => setState(() => _aiEnabled = value),
              title: const Text('AI suggestions enabled'),
              subtitle: const Text('Only snippets are sent when enabled.'),
            ),
            SwitchListTile(
              value: _semiAuto,
              onChanged: (value) => setState(() => _semiAuto = value),
              title: const Text('Semi-auto on selected folders'),
              subtitle: const Text('Off = manual mode only.'),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Connected sources: Phone, Google Drive, Dropbox'),
            const SizedBox(height: AppSpacing.xs),
            const Text('Allowed folders: 3 selected'),
            const Spacer(),
            AppButton.secondary(label: 'Manage folders', onPressed: () {}),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(label: 'Disconnect accounts', onPressed: () {}),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(label: 'Delete my app data', onPressed: () {}),
            ),
          ],
        ),
      ),
    );
  }
}
