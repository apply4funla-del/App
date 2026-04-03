import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class MethodScreen extends StatefulWidget {
  const MethodScreen({
    super.key,
    required this.source,
  });

  final FileSource source;

  @override
  State<MethodScreen> createState() => _MethodScreenState();
}

class _MethodScreenState extends State<MethodScreen> {
  String? _selectedAction;

  void _continue() {
    if (_selectedAction == 'tidy') {
      Navigator.of(context).pushNamed(
        AppRoutes.tidyMethod,
        arguments: widget.source,
      );
      return;
    }
    if (_selectedAction == 'archive') {
      Navigator.of(context).pushNamed(AppRoutes.usbArchive);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Method')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Source: ${widget.source.label}'),
          const SizedBox(height: AppSpacing.sm),
          const Text('Choose what you want to do:'),
          const SizedBox(height: AppSpacing.md),
          _methodTile(
            id: 'tidy',
            title: 'Tidy Files',
            subtitle: 'Browse, preview, and rename files.',
            icon: Icons.edit_note_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          _methodTile(
            id: 'archive',
            title: 'Archive Memories',
            subtitle: 'Copy photos or folders to your USB memory stick.',
            icon: Icons.usb_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            label: 'Continue',
            onPressed: _selectedAction == null ? null : _continue,
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _selectedAction == id;
    return Card(
      child: ListTile(
        selected: selected,
        leading: Icon(selected ? Icons.check_circle : icon),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () => setState(() => _selectedAction = id),
      ),
    );
  }
}
