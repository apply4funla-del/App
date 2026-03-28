import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class ConnectorPickerScreen extends StatefulWidget {
  const ConnectorPickerScreen({super.key});

  @override
  State<ConnectorPickerScreen> createState() => _ConnectorPickerScreenState();
}

class _ConnectorPickerScreenState extends State<ConnectorPickerScreen> {
  bool _google = true;
  bool _dropbox = false;
  bool _phone = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect sources')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            CheckboxListTile(
              value: _phone,
              onChanged: (value) => setState(() => _phone = value ?? false),
              title: const Text('Phone files'),
            ),
            CheckboxListTile(
              value: _google,
              onChanged: (value) => setState(() => _google = value ?? false),
              title: const Text('Google Drive'),
            ),
            CheckboxListTile(
              value: _dropbox,
              onChanged: (value) => setState(() => _dropbox = value ?? false),
              title: const Text('Dropbox'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Next: Choose folders',
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.folderPermission),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
