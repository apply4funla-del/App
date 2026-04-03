import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/use_cases/get_current_user_use_case.dart';
import 'package:file_tidy_app/core/use_cases/sign_in_with_email_use_case.dart';
import 'package:file_tidy_app/core/use_cases/sign_up_with_email_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/components/app_text_input.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

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
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Text(
                'Sign in to connect Google Drive, Dropbox, and restore your plan. Otherwise, use for free.',
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text('We only access the folders you choose.'),
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
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('I have an account'),
                    selected: _hasAccount,
                    onSelected: (_) => setState(() => _hasAccount = true),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ChoiceChip(
                    label: const Text('Create account'),
                    selected: !_hasAccount,
                    onSelected: (_) => setState(() => _hasAccount = false),
                  ),
                ],
              ),
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: wide ? 280 : double.infinity,
                  child: AppButton.primary(
                    label: _busy ? 'Working...' : (_hasAccount ? 'Sign In' : 'Create Account'),
                    onPressed: _busy ? null : _submit,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: wide ? 280 : double.infinity,
                  child: AppButton.secondary(
                    label: 'Use for free',
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.connectorPicker,
                      (route) => false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
