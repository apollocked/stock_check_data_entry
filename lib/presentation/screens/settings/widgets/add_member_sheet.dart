import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../controllers/auth_actions.dart';
import '../../../controllers/auth_controllers.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/common/busy_button.dart';
import '../../../widgets/feedback/app_feedback.dart';
import 'sheet_scaffold.dart';

Future<void> showAddMemberSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _AddMemberSheet(),
  );
}

class _AddMemberSheet extends ConsumerStatefulWidget {
  const _AddMemberSheet();

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(accessRepositoryProvider).addMember(_email.text);
      ref.invalidate(membersProvider);
      if (!mounted) return;
      showAppSnack(
        context,
        '${_email.text.trim()} can now use the store',
        kind: SnackKind.success,
      );
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
      title: 'Add a team member',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'They need to create an account in Stockly first. Then enter '
              'the email they signed up with.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: Gap.lg),
            TextFormField(
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _busy ? null : _add(),
              validator: validateEmail,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: Gap.xl),
            BusyButton(
              label: 'Give access',
              icon: Icons.person_add_alt_1_rounded,
              busy: _busy,
              onPressed: _add,
            ),
          ],
        ),
      ),
    );
  }
}
