import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/models/connector_account_state.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/use_cases/list_connector_states_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  final _dependencies = DependencyContainer.instance;
  late final ListConnectorStatesUseCase _listConnectorStatesUseCase;

  bool _aiEnabled = true;
  bool _semiAuto = true;
  bool _loading = false;
  Map<FileSource, ConnectorAccountState> _states = {};

  @override
  void initState() {
    super.initState();
    _listConnectorStatesUseCase = ListConnectorStatesUseCase(_dependencies.connectorAuthRepository);
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final values = await _listConnectorStatesUseCase();
    if (!mounted) {
      return;
    }
    setState(() {
      _states = values;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectedSources = _states.values.where((item) => item.connected).toList();
    final connectedLabel = connectedSources.map((item) => item.source.label).join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ListView(
                children: [
                  Text('Account', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Plan: Free'),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.secondary(
                    label: 'Manage subscription',
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.subscription),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      label: 'Logout',
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.signIn,
                        (route) => false,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
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
                  Text('Sources', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Connected sources: ${connectedLabel.isEmpty ? 'None' : connectedLabel}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text('Allowed folders: user selected only'),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.secondary(label: 'Manage folders', onPressed: () {}),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.secondary(label: 'Disconnect accounts', onPressed: () {}),
                ],
              ),
            ),
    );
  }
}
