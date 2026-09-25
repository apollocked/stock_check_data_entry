import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/password_policy.dart';
import '../../../core/theme/app_tokens.dart';
import '../../controllers/auth_actions.dart';
import '../../widgets/common/busy_button.dart';
import '../../widgets/feedback/app_feedback.dart';
import 'widgets/auth_layout.dart';
import 'widgets/password_field.dart';

/// Shown after the user opens a password-reset link from their email. Once
/// the password is saved, Supabase emits `userUpdated` and the router moves
/// on to the app by itself.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authActionsProvider).updatePassword(_password.text);
      if (mounted) {
        showAppSnack(
          context,
          'Password updated. You are signed in.',
          kind: SnackKind.success,
        );
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    try {
      await ref.read(authActionsProvider).signOut();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Set a new password',
      subtitle: 'Choose a password you have not used before.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                controller: _password,
                label: 'New password',
                isNew: true,
                showStrength: true,
                action: TextInputAction.next,
                validator: validateNewPassword,
              ),
              const SizedBox(height: Gap.lg),
              PasswordField(
                controller: _confirm,
                label: 'Confirm new password',
                isNew: true,
                onSubmitted: (_) => _busy ? null : _save(),
                validator: (v) =>
                    v == _password.text ? null : 'Passwords do not match',
              ),
              const SizedBox(height: Gap.xl),
              BusyButton(
                label: 'Save password',
                icon: Icons.check_rounded,
                busy: _busy,
                onPressed: _save,
              ),
              const SizedBox(height: Gap.sm),
              TextButton(
                onPressed: _busy ? null : _cancel,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
