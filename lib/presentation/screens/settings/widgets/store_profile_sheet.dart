import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/store.dart';
import '../../../controllers/inventory_controllers.dart';
import '../../../widgets/common/busy_button.dart';
import '../../../widgets/feedback/app_feedback.dart';
import 'sheet_scaffold.dart';

Future<void> showStoreProfileSheet(BuildContext context, Store store) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _StoreProfileSheet(store: store),
  );
}

class _StoreProfileSheet extends ConsumerStatefulWidget {
  final Store store;

  const _StoreProfileSheet({required this.store});

  @override
  ConsumerState<_StoreProfileSheet> createState() => _StoreProfileSheetState();
}

class _StoreProfileSheetState extends ConsumerState<_StoreProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.store.name);
  late final _location = TextEditingController(text: widget.store.location);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(storeProvider.notifier)
          .updateProfile(name: _name.text, location: _location.text);
      if (!mounted) return;
      showAppSnack(context, 'Store updated', kind: SnackKind.success);
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
      title: 'Store profile',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Store name',
                prefixIcon: Icon(Icons.storefront_rounded),
                counterText: '',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: Gap.md),
            TextFormField(
              controller: _location,
              maxLength: 200,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                prefixIcon: Icon(Icons.place_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: Gap.xl),
            BusyButton(
              label: 'Save',
              icon: Icons.check_rounded,
              busy: _busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
