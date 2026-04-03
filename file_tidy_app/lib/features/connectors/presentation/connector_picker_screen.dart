import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/models/app_user_session.dart';
import 'package:file_tidy_app/core/models/connector_account_state.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/use_cases/connect_connector_use_case.dart';
import 'package:file_tidy_app/core/use_cases/get_current_user_use_case.dart';
import 'package:file_tidy_app/core/use_cases/disconnect_connector_use_case.dart';
import 'package:file_tidy_app/core/use_cases/list_connector_states_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/components/app_text_input.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class ConnectorPickerScreen extends StatefulWidget {
  const ConnectorPickerScreen({super.key});

  @override
  State<ConnectorPickerScreen> createState() => _ConnectorPickerScreenState();
}

class _ConnectorPickerScreenState extends State<ConnectorPickerScreen> {
  final _dependencies = DependencyContainer.instance;

  late final ConnectConnectorUseCase _connectConnectorUseCase;
  late final DisconnectConnectorUseCase _disconnectConnectorUseCase;
  late final ListConnectorStatesUseCase _listConnectorStatesUseCase;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  bool _loading = false;
  Map<FileSource, ConnectorAccountState> _states = {};
  FileSource? _selectedSource;
  AppUserSession? _currentUser;

  @override
  void initState() {
    super.initState();
    _connectConnectorUseCase = ConnectConnectorUseCase(_dependencies.connectorAuthRepository);
    _disconnectConnectorUseCase = DisconnectConnectorUseCase(_dependencies.connectorAuthRepository);
    _listConnectorStatesUseCase = ListConnectorStatesUseCase(_dependencies.connectorAuthRepository);
    _getCurrentUserUseCase = GetCurrentUserUseCase(_dependencies.appAuthRepository);
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final values = await _listConnectorStatesUseCase();
    final currentUser = await _getCurrentUserUseCase();
    if (!mounted) {
      return;
    }
    setState(() {
      _states = values;
      _currentUser = currentUser;
      _loading = false;
    });
  }

  Future<void> _connect(FileSource source) async {
    if (source == FileSource.phone) {
      await _refresh();
      return;
    }
    if (_currentUser == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to access Google Drive and Dropbox.')),
      );
      Navigator.of(context).pushNamed(AppRoutes.signIn);
      return;
    }

    final label = await _showAccountLabelPrompt(source);
    if (!mounted || label == null) {
      return;
    }

    await _connectConnectorUseCase(
      source: source,
      accountLabel: label.trim().isEmpty ? null : label.trim(),
    );
    await _refresh();
  }

  Future<void> _disconnect(FileSource source) async {
    await _disconnectConnectorUseCase(source);
    await _refresh();
  }

  Future<String?> _showAccountLabelPrompt(FileSource source) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Connect ${source.label}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter account label (email or nickname). OAuth provider wiring is modular and can be swapped in next.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextInput(
                controller: controller,
                label: 'Account label',
                hintText: 'you@example.com',
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: 100,
              child: AppButton.secondary(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            SizedBox(
              width: 100,
              child: AppButton.primary(
                label: 'Connect',
                onPressed: () => Navigator.of(context).pop(controller.text),
              ),
            ),
          ],
        );
      },
    );
  }

  void _goToMethod() {
    final source = _selectedSource;
    if (source == null) {
      return;
    }
    final connected = _states[source]?.connected ?? (source == FileSource.phone);
    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connect ${source.label} first.')),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.method,
      arguments: source,
    );
  }

  @override
  Widget build(BuildContext context) {
    final landscapeGrid = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(title: const Text('Connect sources')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ListView(
                    children: [
                      Text(
                        _currentUser == null
                            ? 'Using free mode. Sign in to access Google Drive and Dropbox.'
                            : 'Signed in as ${_currentUser!.email}',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text('Tap one source to continue.'),
                      const SizedBox(height: AppSpacing.md),
                      if (landscapeGrid)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var index = 0; index < FileSource.values.length; index++) ...[
                              Expanded(
                                child: _buildConnectorCard(
                                  FileSource.values[index],
                                  compact: true,
                                ),
                              ),
                              if (index < FileSource.values.length - 1)
                                const SizedBox(width: AppSpacing.md),
                            ],
                          ],
                        )
                      else
                        ...FileSource.values.map(
                          (source) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _buildConnectorCard(source),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: landscapeGrid ? 260 : double.infinity,
                          child: AppButton.primary(
                            label: 'Next: Method',
                            onPressed: _selectedSource == null ? null : _goToMethod,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildConnectorCard(FileSource source, {bool compact = false}) {
    final state = _states[source];
    final connected = state?.connected ?? (source == FileSource.phone);
    final label = state?.accountLabel;
    final selected = _selectedSource == source;

    final cloudRequiresSignIn = source != FileSource.phone && _currentUser == null;

    final action = source == FileSource.phone
        ? const Text('Always On')
        : cloudRequiresSignIn
            ? AppButton.secondary(
                label: 'Sign In',
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signIn),
              )
        : connected
            ? AppButton.secondary(
                label: 'Disconnect',
                onPressed: () => _disconnect(source),
              )
            : AppButton.primary(
                label: 'Connect',
                onPressed: () => _connect(source),
              );

    return Card(
      color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : null,
      child: InkWell(
        onTap: () => setState(() => _selectedSource = source),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            height: compact ? 220 : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_iconFor(source)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(source.label, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            connected ? 'Connected${label == null ? '' : ' as $label'}' : 'Not connected',
                          ),
                        ],
                      ),
                    ),
                    if (selected) const Icon(Icons.check_circle_outline),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (compact)
                  Text(
                    source == FileSource.phone
                        ? 'Use files already on this device.'
                        : cloudRequiresSignIn
                            ? 'Sign in to enable this cloud source.'
                        : 'Connect this cloud source before continuing.',
                  ),
                if (compact) const Spacer() else const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: action,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(FileSource source) {
    switch (source) {
      case FileSource.phone:
        return Icons.smartphone_outlined;
      case FileSource.googleDrive:
        return Icons.cloud_outlined;
      case FileSource.dropbox:
        return Icons.inventory_2_outlined;
    }
  }
}
