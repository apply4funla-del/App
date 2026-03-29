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
  late final String _lockedExtension;
  List<String> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: FeatureFlags.enableAiRename ? 2 : 1,
      vsync: this,
    );
    _lockedExtension = _extractExtension(widget.currentName);
    _nameController = TextEditingController(
      text: _stripExtension(widget.currentName),
    );
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
                    if (_lockedExtension.isEmpty)
                      AppTextInput(
                        controller: _nameController,
                        label: 'New file name',
                        hintText: 'Type your preferred name',
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('New file name'),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextInput(
                                  controller: _nameController,
                                  label: 'Name',
                                  hintText: 'Type your preferred name',
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _lockedExtension,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ],
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
                                      _nameController.text = _stripExtension(suggestion);
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
                      onPressed: () => Navigator.of(context).pop(_buildFinalName()),
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

  String _extractExtension(String value) {
    final dotIndex = value.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == value.length - 1) {
      return '';
    }
    return value.substring(dotIndex);
  }

  String _stripExtension(String value) {
    if (_lockedExtension.isEmpty) {
      return value;
    }
    if (value.toLowerCase().endsWith(_lockedExtension.toLowerCase())) {
      return value.substring(0, value.length - _lockedExtension.length);
    }
    final dotIndex = value.lastIndexOf('.');
    if (dotIndex > 0) {
      return value.substring(0, dotIndex);
    }
    return value;
  }

  String _buildFinalName() {
    var base = _nameController.text.trim();
    if (base.isEmpty) {
      return widget.currentName;
    }
    if (_lockedExtension.isEmpty) {
      return base;
    }
    if (base.toLowerCase().endsWith(_lockedExtension.toLowerCase())) {
      base = base.substring(0, base.length - _lockedExtension.length);
    }
    if (base.endsWith('.')) {
      base = base.substring(0, base.length - 1);
    }
    if (base.isEmpty) {
      return widget.currentName;
    }
    return '$base$_lockedExtension';
  }
}
