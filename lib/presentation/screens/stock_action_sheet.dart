import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_exception.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/stock_movement.dart';
import '../controllers/inventory_controllers.dart';
import '../providers/repository_providers.dart';

Future<void> showStockActionSheet(BuildContext context, {required Item item}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => StockActionSheet(item: item),
  );
}

class StockActionSheet extends ConsumerStatefulWidget {
  final Item item;

  const StockActionSheet({super.key, required this.item});

  @override
  ConsumerState<StockActionSheet> createState() => _StockActionSheetState();
}

class _StockActionSheetState extends ConsumerState<StockActionSheet> {
  bool _busy = false;
  Item? _latestItem;

  Item get _item => _latestItem ?? widget.item;

  Future<void> _afterMovement(Item updated, String message) async {
    if (!mounted) return;
    setState(() {
      _latestItem = updated;
      _busy = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
    ref.invalidate(itemsProvider);
    ref.invalidate(movementsProvider);
    ref.invalidate(dayMovementsProvider);
    ref.invalidate(reportProvider);
  }

  Future<void> _runTransaction(MovementType type) async {
    final qty = await showDialog<int>(
      context: context,
      builder: (context) => _QuantityDialog(type: type, item: _item),
    );
    if (qty == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final newQty = await ref
          .read(inventoryRepositoryProvider)
          .recordMovement(item: widget.item, type: type, quantity: qty);
      await _afterMovement(
        _copyWith(newQty),
        '${_item.name}: ${type.label} $qty → $newQty in stock',
      );
    } on AppException catch (e) {
      await _onError(e.message);
    } catch (e) {
      await _onError('Failed: $e');
    }
  }

  Future<void> _runAdjust() async {
    final delta = await showDialog<int>(
      context: context,
      builder: (context) => _AdjustDialog(item: _item),
    );
    if (delta == null || delta == 0 || !mounted) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final isPositive = delta > 0;
      final newQty = await repo.recordMovement(
        item: widget.item,
        type: isPositive ? MovementType.inbound : MovementType.outbound,
        quantity: delta.abs(),
        note: 'Adjustment ${isPositive ? '+' : ''}$delta',
      );
      await _afterMovement(
        _copyWith(newQty),
        '${_item.name}: adjusted ${delta >= 0 ? '+' : ''}$delta '
        '→ $newQty in stock',
      );
    } on AppException catch (e) {
      await _onError(e.message);
    } catch (e) {
      await _onError('Failed: $e');
    }
  }

  Item _copyWith(int quantity) => Item(
    id: widget.item.id,
    branchId: widget.item.branchId,
    branchName: widget.item.branchName,
    name: widget.item.name,
    description: widget.item.description,
    price: widget.item.price,
    barcode: widget.item.barcode,
    imageUrl: widget.item.imageUrl,
    customFields: widget.item.customFields,
    quantity: quantity,
    createdAt: widget.item.createdAt,
  );

  Future<void> _onError(String message) async {
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final quantity = _item.quantity;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _item.imageUrl != null
                      ? Image.network(
                          _item.imageUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 48,
                            height: 48,
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.broken_image, color: cs.outline),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: cs.outline,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'In stock: $quantity',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: quantity < 0
                              ? cs.error
                              : quantity == 0
                              ? cs.tertiary
                              : quantity <= 5
                              ? Colors.orange.shade800
                              : cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _busy
                  ? null
                  : () => _runTransaction(MovementType.inbound),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Stock in (receive)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _busy
                  ? null
                  : () => _runTransaction(MovementType.outbound),
              icon: const Icon(Icons.remove_shopping_cart),
              label: const Text('Stock out (sell)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: cs.error,
              ),
              onPressed: _busy
                  ? null
                  : () => _runTransaction(MovementType.damage),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report damage'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: _busy ? null : _runAdjust,
              icon: const Icon(Icons.tune),
              label: const Text('Adjust stock (correction)'),
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust lets you type a positive or negative number to fix '
              'stock directly.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityDialog extends StatefulWidget {
  final MovementType type;
  final Item item;

  const _QuantityDialog({required this.type, required this.item});

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _qtyController = TextEditingController(text: '1');
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPositive = widget.type == MovementType.inbound;

    return AlertDialog(
      title: Text('${widget.type.label} — ${widget.item.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current stock: ${widget.item.quantity}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _qtyController,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              prefixIcon: Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isPositive ? cs.primary : cs.error,
          ),
          onPressed: () {
            final qty = int.tryParse(_qtyController.text.trim());
            if (qty == null || qty <= 0) return;
            Navigator.pop(context, qty);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _AdjustDialog extends StatefulWidget {
  final Item item;

  const _AdjustDialog({required this.item});

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  final _deltaController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _deltaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust stock — ${widget.item.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current stock: ${widget.item.quantity}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _deltaController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Change (+ add, - remove)',
              helperText: 'Example: +5 adds 5, -3 removes 3',
              prefixIcon: Icon(Icons.exposure),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final delta = int.tryParse(_deltaController.text.trim());
            if (delta == null || delta == 0) return;
            Navigator.pop(context, delta);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
