import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/models/app_user_session.dart';
import 'package:file_tidy_app/core/models/connector_account_state.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/use_cases/connect_connector_use_case.dart';
import 'package:file_tidy_app/core/use_cases/disconnect_connector_use_case.dart';
import 'package:file_tidy_app/core/use_cases/get_current_user_use_case.dart';
import 'package:file_tidy_app/core/use_cases/list_connector_states_use_case.dart';
import 'package:file_tidy_app/design_system/components/onboarding_pill_button.dart';
import 'package:file_tidy_app/design_system/components/onboarding_screen.dart';
import 'package:file_tidy_app/design_system/tokens/app_assets.dart';
import 'package:file_tidy_app/design_system/tokens/app_colors.dart';
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
    return '${source.label.toLowerCase()}@connected';
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
    final width = MediaQuery.sizeOf(context).width;
    final landscapeGrid = width >= 900;
    final buttonWidth = landscapeGrid ? 260.0 : width.clamp(220.0, 320.0);
    return OnboardingScreen(
      title: 'Connect',
      onBack: () => Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.welcome,
        (route) => false,
      ),
      maxWidth: 1080,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Text(
                  _currentUser == null
                      ? 'Choose one source. Sign in only if you want Google Drive or Dropbox.'
                      : 'Signed in as ${_currentUser!.email}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: buttonWidth,
                  child: OnboardingPillButton(
                    label: 'Next',
                    onPressed: _selectedSource == null ? null : _goToMethod,
                  ),
                ),
              ],
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
        ? Text(
            'Connected',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.brandDark,
                ),
          )
        : cloudRequiresSignIn
            ? OnboardingPillButton(
                label: 'Sign in',
                compact: true,
                tone: OnboardingPillTone.green,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signIn),
              )
        : connected
            ? OnboardingPillButton(
                label: 'Disconnect',
                compact: true,
                tone: OnboardingPillTone.white,
                onPressed: () => _disconnect(source),
              )
            : OnboardingPillButton(
                label: 'Connect',
                compact: true,
                tone: OnboardingPillTone.green,
                onPressed: () => _connect(source),
              );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: selected ? AppColors.brandDark : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => setState(() => _selectedSource = source),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            height: compact ? 220 : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      _imageFor(source),
                      width: compact ? 62 : 56,
                      height: compact ? 62 : 56,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.label,
                            style: compact
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            connected ? 'Connected${label == null ? '' : ' as $label'}' : 'Not connected',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  source == FileSource.phone
                      ? 'Use files already on this device.'
                      : cloudRequiresSignIn
                          ? 'Sign in to enable this cloud source.'
                          : 'Connect this cloud source before continuing.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (compact) const Spacer() else const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: compact ? 132 : 160,
                    child: action,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _imageFor(FileSource source) {
    switch (source) {
      case FileSource.phone:
        return AppAssets.phoneLogo;
      case FileSource.googleDrive:
        return AppAssets.googleDriveLogo;
      case FileSource.dropbox:
        return AppAssets.dropboxLogo;
    }
  }
}
