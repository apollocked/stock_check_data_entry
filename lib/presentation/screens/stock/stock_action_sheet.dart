import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/entities/stock_change.dart';
import '../../controllers/inventory_controllers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/common/busy_button.dart';
import '../../widgets/feedback/app_feedback.dart';
import '../../widgets/item_image.dart';
import 'widgets/quantity_stepper.dart';
import 'widgets/stock_mode_selector.dart';
import 'widgets/stock_preview.dart';

/// Opens the stock sheet for [item], starting in [mode].
Future<void> showStockActionSheet(
  BuildContext context, {
  required Item item,
  StockMode mode = StockMode.receive,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => StockActionSheet(item: item, initialMode: mode),
  );
}

class StockActionSheet extends ConsumerStatefulWidget {
  final Item item;
  final StockMode initialMode;

  const StockActionSheet({
    super.key,
    required this.item,
    this.initialMode = StockMode.receive,
  });

  @override
  ConsumerState<StockActionSheet> createState() => _StockActionSheetState();
}

class _StockActionSheetState extends ConsumerState<StockActionSheet> {
  late StockMode _mode = widget.initialMode;
  late final _amount = TextEditingController(text: _defaultAmount(_mode));
  final _note = TextEditingController();
  bool _busy = false;

  Item get _item =>
      ref.watch(itemByIdProvider(widget.item.id)).value ?? widget.item;

  String _defaultAmount(StockMode mode) => mode == StockMode.count
      ? '${widget.item.quantity.clamp(0, 1 << 30)}'
      : '1';

  StockChange? get _plan =>
      StockChange.plan(_mode, _item.quantity, int.tryParse(_amount.text) ?? 0);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _setMode(StockMode mode) {
    HapticFeedback.selectionClick();
    setState(() {
      _mode = mode;
      _amount.text = _defaultAmount(mode);
    });
  }

  Future<void> _save() async {
    final plan = _plan;
    if (plan == null) return;
    setState(() => _busy = true);
    final note = [
      plan.autoNote,
      _note.text.trim(),
    ].where((s) => s != null && s.isNotEmpty).join(' — ');
    try {
      final newQty = await ref
          .read(inventoryRepositoryProvider)
          .recordMovement(
            item: _item,
            type: plan.type,
            quantity: plan.quantity,
            note: note,
          );
      invalidateStock(ref);
      if (!mounted) return;
      showAppSnack(
        context,
        '${_item.name}: ${_mode.label.toLowerCase()} saved · $newQty in stock',
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
    final text = Theme.of(context).textTheme;
    final color = _mode.color(context);
    final plan = _plan;
    final item = _item;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.xl,
        0,
        Gap.xl,
        Gap.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ItemImage(url: item.imageUrl, size: 52, radius: Radii.md),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.lg),
            StockModeSelector(mode: _mode, onChanged: _setMode),
            const SizedBox(height: Gap.lg),
            Text(
              _mode == StockMode.count ? 'Counted on the shelf' : 'Quantity',
              textAlign: TextAlign.center,
              style: text.labelLarge,
            ),
            QuantityStepper(
              controller: _amount,
              color: color,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Gap.sm),
            StockPreview(
              current: item.quantity,
              next: plan?.applyTo(item.quantity),
            ),
            const SizedBox(height: Gap.lg),
            TextField(
              controller: _note,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.sticky_note_2_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: Gap.lg),
            BusyButton(
              label: plan == null
                  ? 'Nothing to change'
                  : 'Save ${_mode.label.toLowerCase()}',
              icon: Icons.check_rounded,
              color: color,
              busy: _busy,
              onPressed: plan == null ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
