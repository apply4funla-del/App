import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class FolderPermissionScreen extends StatefulWidget {
  const FolderPermissionScreen({super.key});

  @override
  State<FolderPermissionScreen> createState() => _FolderPermissionScreenState();
}

class _FolderPermissionScreenState extends State<FolderPermissionScreen> {
  final Map<String, bool> _folders = {
    '/Travel': true,
    '/Documents/Contracts': true,
    '/Receipts': false,
    '/Photos/Family': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose folders')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Only selected folders will be processed.'),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                children: _folders.entries
                    .map(
                      (entry) => CheckboxListTile(
                        value: entry.value,
                        onChanged: (value) => setState(
                          () => _folders[entry.key] = value ?? false,
                        ),
                        title: Text(entry.key),
                      ),
                    )
                    .toList(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Open explorer',
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.explorer,
                  (route) => false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
