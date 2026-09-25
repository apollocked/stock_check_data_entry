import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/store.dart';
import '../../controllers/inventory_controllers.dart';
import '../../widgets/common/busy_button.dart';
import '../../widgets/feedback/app_feedback.dart';
import '../../widgets/states/error_state.dart';
import 'widgets/settings_group.dart';

/// Choose which fields items record. Name and price are always on.
class ItemFieldsScreen extends ConsumerStatefulWidget {
  const ItemFieldsScreen({super.key});

  @override
  ConsumerState<ItemFieldsScreen> createState() => _ItemFieldsScreenState();
}

class _ItemFieldsScreenState extends ConsumerState<ItemFieldsScreen> {
  /// Edits in progress; null until the store has loaded.
  Map<String, bool>? _enabled;
  Map<String, bool> _saved = const {};
  bool _saving = false;

  static Map<String, bool> _fromStore(Store store) => {
    for (final option in defaultValueFields())
      option.id:
          option.required ||
          store.fields.any((f) => f.id == option.id && f.enabled),
  };

  bool get _changed =>
      _enabled != null &&
      _enabled!.entries.any((e) => _saved[e.key] != e.value);

  Future<void> _save() async {
    // Fix: the old screen kept toggles in each tile and saved the old values.
    final enabled = _enabled!;
    setState(() => _saving = true);
    try {
      await ref.read(storeProvider.notifier).updateFields([
        for (final option in defaultValueFields())
          ItemField(
            id: option.id,
            label: option.label,
            type: option.type,
            enabled: enabled[option.id]!,
            required: option.required,
          ),
      ]);
      if (!mounted) return;
      setState(() => _saved = Map.of(enabled));
      showAppSnack(context, 'Item fields saved', kind: SnackKind.success);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  IconData _icon(String type) => switch (type) {
    'image' => Icons.image_outlined,
    'number' => Icons.numbers_rounded,
    _ => Icons.text_fields_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final loaded = store.value;
    if (loaded != null && _enabled == null) {
      _saved = _fromStore(loaded);
      _enabled = Map.of(_saved);
    }
    final enabled = _enabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Item fields')),
      body: enabled == null
          ? (store.hasError
                ? ErrorState(
                    error: store.error!,
                    onRetry: () => ref.invalidate(storeProvider),
                  )
                : const Center(child: CircularProgressIndicator()))
          : ListView(
              padding: const EdgeInsets.all(Gap.lg),
              children: [
                Text(
                  'Pick what you record for each item. Fields you turn off '
                  'are hidden from forms and exports; saved values are kept.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: Gap.lg),
                SettingsGroup(
                  children: [
                    for (final option in defaultValueFields())
                      SwitchListTile(
                        secondary: Icon(_icon(option.type)),
                        title: Text(option.label),
                        subtitle: option.required
                            ? const Text('Always on')
                            : null,
                        value: enabled[option.id]!,
                        onChanged: option.required || _saving
                            ? null
                            : (v) {
                                HapticFeedback.selectionClick();
                                setState(() => enabled[option.id] = v);
                              },
                      ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.lg),
        child: BusyButton(
          label: _changed ? 'Save changes' : 'No changes',
          icon: Icons.check_rounded,
          busy: _saving,
          onPressed: _changed ? _save : null,
        ),
      ),
    );
  }
}
