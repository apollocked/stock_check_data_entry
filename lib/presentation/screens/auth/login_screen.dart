import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/password_policy.dart';
import '../../../core/theme/app_tokens.dart';
import '../../controllers/auth_actions.dart';
import '../../widgets/common/busy_button.dart';
import '../../widgets/feedback/app_feedback.dart';
import 'widgets/auth_layout.dart';
import 'widgets/password_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    final auth = ref.read(authActionsProvider);
    await _run(() async {
      if (!_isSignUp) return auth.signIn(_email.text, _password.text);
      final needsConfirm = await auth.signUp(_email.text, _password.text);
      if (!needsConfirm || !mounted) return;
      showAppSnack(
        context,
        'Account created. Confirm your email from your inbox, then sign in.',
        kind: SnackKind.success,
      );
      setState(() => _isSignUp = false);
    });
  }

  Future<void> _forgotPassword() async {
    if (validateEmail(_email.text) != null) {
      showAppSnack(context, 'Enter your email above first.');
      return;
    }
    await _run(() async {
      await ref.read(authActionsProvider).sendPasswordReset(_email.text);
      if (!mounted) return;
      // Same answer whether or not the account exists.
      showAppSnack(
        context,
        'If an account exists for ${_email.text.trim()}, a reset link is on '
        'its way. Open it on this phone.',
        kind: SnackKind.success,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: _isSignUp ? 'Create your account' : 'Welcome back',
      subtitle: 'Stock, inventory and sales in one simple app',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Sign in')),
                  ButtonSegment(value: true, label: Text('Create account')),
                ],
                selected: {_isSignUp},
                onSelectionChanged: _busy
                    ? null
                    : (s) => setState(() => _isSignUp = s.first),
              ),
              const SizedBox(height: Gap.xl),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: Gap.lg),
              PasswordField(
                controller: _password,
                isNew: _isSignUp,
                showStrength: _isSignUp,
                onSubmitted: (_) => _busy ? null : _submit(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your password';
                  // Existing accounts may have older, shorter passwords.
                  return _isSignUp ? validateNewPassword(v) : null;
                },
              ),
              AnimatedSize(
                duration: Motion.medium,
                curve: Motion.emphasized,
                child: _isSignUp
                    ? const SizedBox(height: Gap.xl, width: double.infinity)
                    : Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _forgotPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),
              ),
              BusyButton(
                label: _isSignUp ? 'Create account' : 'Sign in',
                icon: _isSignUp
                    ? Icons.person_add_alt_1_rounded
                    : Icons.arrow_forward_rounded,
                busy: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
