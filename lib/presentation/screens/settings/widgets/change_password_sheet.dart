import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/password_policy.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../controllers/auth_actions.dart';
import '../../../widgets/common/busy_button.dart';
import '../../../widgets/feedback/app_feedback.dart';
import '../../auth/widgets/password_field.dart';
import 'sheet_scaffold.dart';

Future<void> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
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
      if (!mounted) return;
      showAppSnack(context, 'Password changed', kind: SnackKind.success);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showErrorSnack(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Change password',
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
              const SizedBox(height: Gap.md),
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
                label: 'Change password',
                icon: Icons.lock_reset_rounded,
                busy: _busy,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
