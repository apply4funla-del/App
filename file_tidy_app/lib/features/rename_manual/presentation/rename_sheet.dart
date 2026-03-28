import 'package:file_tidy_app/core/config/feature_flags.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/components/app_text_input.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class RenameSheet extends StatefulWidget {
  const RenameSheet({
    super.key,
    required this.currentName,
    required this.suggestionsLoader,
    this.confirmLabel = 'Confirm rename',
  });

  final String currentName;
  final Future<List<String>> Function() suggestionsLoader;
  final String confirmLabel;

  @override
  State<RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<RenameSheet> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _nameController;
  List<String> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: FeatureFlags.enableAiRename ? 2 : 1,
      vsync: this,
    );
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _loading = true;
    });
    final values = await widget.suggestionsLoader();
    if (!mounted) {
      return;
    }
    setState(() {
      _suggestions = values;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[const Tab(text: 'Manual')];
    if (FeatureFlags.enableAiRename) {
      tabs.add(const Tab(text: 'AI Suggest'));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              TabBar(controller: _tabController, tabs: tabs),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    AppTextInput(
                      controller: _nameController,
                      label: 'New file name',
                      hintText: 'Type your preferred name',
                    ),
                    if (FeatureFlags.enableAiRename)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppButton.secondary(
                            label: _loading ? 'Loading...' : 'Generate suggestions',
                            onPressed: _loading ? null : _loadSuggestions,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _suggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = _suggestions[index];
                                return ListTile(
                                  title: Text(suggestion),
                                  trailing: AppButton.secondary(
                                    label: 'Use',
                                    onPressed: () {
                                      _nameController.text = suggestion;
                                      _tabController.animateTo(0);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton.primary(
                      label: widget.confirmLabel,
                      onPressed: () => Navigator.of(context).pop(_nameController.text.trim()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
