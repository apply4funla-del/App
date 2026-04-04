import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/use_cases/get_current_user_use_case.dart';
import 'package:file_tidy_app/core/use_cases/sign_in_with_email_use_case.dart';
import 'package:file_tidy_app/core/use_cases/sign_up_with_email_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_text_input.dart';
import 'package:file_tidy_app/design_system/components/onboarding_asset_button.dart';
import 'package:file_tidy_app/design_system/services/button_press_feedback.dart';
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
  late bool _hasAccount;

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
    final buttonWidth = width >= 720 ? 360.0 : width.clamp(220.0, 360.0);
    final formWidth = width >= 720 ? 420.0 : width.clamp(250.0, 360.0);

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                minHeight: MediaQuery.sizeOf(context).height - 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: width >= 420 ? 56 : 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: ButtonPressFeedback.wrap(() => Navigator.of(context).maybePop()),
                        child: Image.asset(
                          AppAssets.backButton,
                          width: width >= 420 ? 46 : 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Create\nAccount',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.black,
                          height: 1.05,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: formWidth),
                    child: AppTextInput(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: formWidth),
                    child: AppTextInput(
                      controller: _passwordController,
                      label: 'Password',
                      hintText: 'Password',
                      obscureText: true,
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: formWidth),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: buttonWidth),
                    child: OnboardingAssetButton(
                      assetPath: _hasAccount ? AppAssets.loginToAccountButton : AppAssets.signUpButton,
                      semanticLabel: _hasAccount ? 'Log in to account' : 'Sign up',
                      onPressed: _busy ? null : _submit,
                    ),
                  ),
                  if (_hasAccount) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Forgotten your password?\nDon’t worry. Click here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
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
                  ] else ...[
                    const SizedBox(height: AppSpacing.xl),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: buttonWidth),
                      child: OnboardingAssetButton(
                        assetPath: AppAssets.iAlreadyHaveAccountButton,
                        semanticLabel: 'I already have an account',
                        onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.signIn),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'You agree to Tidily Privacy Policy\nwhen creating an account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.link,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
