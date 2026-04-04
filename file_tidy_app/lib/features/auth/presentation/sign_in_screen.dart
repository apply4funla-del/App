import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/use_cases/get_current_user_use_case.dart';
import 'package:file_tidy_app/core/use_cases/sign_in_with_email_use_case.dart';
import 'package:file_tidy_app/core/use_cases/sign_up_with_email_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_text_input.dart';
import 'package:file_tidy_app/design_system/components/onboarding_asset_button.dart';
import 'package:file_tidy_app/design_system/components/onboarding_screen.dart';
import 'package:file_tidy_app/design_system/tokens/app_assets.dart';
import 'package:file_tidy_app/design_system/tokens/app_colors.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    this.initialCreateAccount = false,
  });

  final bool initialCreateAccount;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _dependencies = DependencyContainer.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final SignInWithEmailUseCase _signInWithEmailUseCase;
  late final SignUpWithEmailUseCase _signUpWithEmailUseCase;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  bool _busy = false;
  String? _message;
  bool _hasAccount = true;

  @override
  void initState() {
    super.initState();
    _signInWithEmailUseCase = SignInWithEmailUseCase(_dependencies.appAuthRepository);
    _signUpWithEmailUseCase = SignUpWithEmailUseCase(_dependencies.appAuthRepository);
    _getCurrentUserUseCase = GetCurrentUserUseCase(_dependencies.appAuthRepository);
    _hasAccount = !widget.initialCreateAccount;
    _loadSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final current = await _getCurrentUserUseCase();
    if (!mounted || current == null) {
      return;
    }
    _emailController.text = current.email;
    setState(() {
      _message = 'Signed in as ${current.email}.';
    });
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = 'Enter your email and password.');
      return;
    }
    if (!_dependencies.appAuthRepository.isConfigured) {
      setState(() {
        _message =
            'Supabase is not configured yet. Add SUPABASE_URL and SUPABASE_ANON_KEY to enable sign-in.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_hasAccount) {
        await _signInWithEmailUseCase(email: email, password: password);
      } else {
        await _signUpWithEmailUseCase(email: email, password: password);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.connectorPicker,
        (route) => false,
      );
    } on AuthException catch (error) {
      setState(() => _message = error.message);
    } on StateError catch (error) {
      setState(() => _message = error.message);
    } catch (_) {
      setState(() => _message = 'Unable to continue right now.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 720;
    final compact = width < 390;
    final buttonWidth = wide ? 360.0 : width.clamp(220.0, 360.0);
    return OnboardingScreen(
      title: _hasAccount ? 'Sign in' : 'Create\nAccount',
      onBack: () => Navigator.of(context).maybePop(),
      maxWidth: 620,
      child: Column(
        children: [
          Text(
            _hasAccount
                ? 'Sign in to connect Google Drive, Dropbox, and restore your plan.'
                : 'Create an account to connect Google Drive, Dropbox, and restore your plan later.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You can still use the phone tidy tools for free.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ModeToggle(
            hasAccount: _hasAccount,
            onChanged: (value) => setState(() => _hasAccount = value),
            stacked: compact,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextInput(
            controller: _emailController,
            label: 'Email',
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextInput(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Enter password',
            obscureText: true,
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: buttonWidth),
            child: OnboardingAssetButton(
              assetPath: _hasAccount ? AppAssets.signInButton : AppAssets.signUpButton,
              semanticLabel: _hasAccount ? 'Sign in' : 'Create account',
              onPressed: _busy ? null : _submit,
            ),
          ),
          if (_hasAccount) ...[
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: buttonWidth),
              child: OnboardingAssetButton(
                assetPath: AppAssets.passwordHelpButton,
                semanticLabel: 'I need my password',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset will be added next.'),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.connectorPicker,
              (route) => false,
            ),
            child: const Text('Use phone tools for free'),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.hasAccount,
    required this.onChanged,
    required this.stacked,
  });

  final bool hasAccount;
  final ValueChanged<bool> onChanged;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: stacked
          ? Column(
              children: [
                _ModeChip(
                  label: 'I have an account',
                  selected: hasAccount,
                  onTap: () => onChanged(true),
                ),
                const SizedBox(height: AppSpacing.xs),
                _ModeChip(
                  label: 'Create account',
                  selected: !hasAccount,
                  onTap: () => onChanged(false),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _ModeChip(
                    label: 'I have an account',
                    selected: hasAccount,
                    onTap: () => onChanged(true),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _ModeChip(
                    label: 'Create account',
                    selected: !hasAccount,
                    onTap: () => onChanged(false),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.brandDark : AppColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? Colors.white : AppColors.ink,
              ),
        ),
      ),
    );
  }
}
