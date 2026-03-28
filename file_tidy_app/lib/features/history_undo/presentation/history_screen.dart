import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/models/rename_record.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repository = DependencyContainer.instance.fileRepository;
  List<RenameRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final values = await _repository.listHistory();
    if (!mounted) {
      return;
    }
    setState(() => _records = values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History and Undo')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _records.isEmpty
            ? const Center(child: Text('No rename actions yet.'))
            : ListView.builder(
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final record = _records[index];
                  return Card(
                    child: ListTile(
                      title: Text('${record.beforeName} -> ${record.afterName}'),
                      subtitle: Text(record.createdAt.toString()),
                      trailing: AppButton.secondary(
                        label: 'Undo',
                        onPressed: () async {
                          await _repository.undoRename(record.id);
                          await _refresh();
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
