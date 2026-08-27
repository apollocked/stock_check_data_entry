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

  Future<void> _runTransaction(MovementType type) async {
    final qty = await showDialog<int>(
      context: context,
      builder: (context) => _TransactionDialog(type: type, item: _item),
    );
    if (qty == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final newQty = await ref
          .read(inventoryRepositoryProvider)
          .recordMovement(item: widget.item, type: type, quantity: qty);
      if (!mounted) return;
      setState(() {
        _latestItem = Item(
          id: widget.item.id,
          branchId: widget.item.branchId,
          branchName: widget.item.branchName,
          name: widget.item.name,
          description: widget.item.description,
          price: widget.item.price,
          barcode: widget.item.barcode,
          imageUrl: widget.item.imageUrl,
          customFields: widget.item.customFields,
          quantity: newQty,
          createdAt: widget.item.createdAt,
        );
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_item.name}: ${type.label} $qty → $newQty in stock'),
          duration: const Duration(seconds: 2),
        ),
      );
      ref.invalidate(itemsProvider);
      ref.invalidate(movementsProvider);
      ref.invalidate(reportProvider);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final needStockOut = _item.quantity <= 0;

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
                        'In stock: ${_item.quantity}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _item.quantity == 0
                              ? cs.error
                              : _item.quantity <= 5
                              ? cs.error
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
              onPressed: _busy || needStockOut
                  ? null
                  : () => _runTransaction(MovementType.outbound),
              icon: const Icon(Icons.remove_shopping_cart),
              label: Text(
                _item.quantity <= 0
                    ? 'Stock out (no stock)'
                    : 'Stock out (sell)',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: cs.error,
              ),
              onPressed: _busy || needStockOut
                  ? null
                  : () => _runTransaction(MovementType.damage),
              icon: const Icon(Icons.report_problem_outlined),
              label: Text(
                _item.quantity <= 0 ? 'Damage (no stock)' : 'Report damage',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionDialog extends StatefulWidget {
  final MovementType type;
  final Item item;

  const _TransactionDialog({required this.type, required this.item});

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final _qtyController = TextEditingController(text: '1');
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _positiveLabel => switch (widget.type) {
    MovementType.inbound => 'Stock in',
    MovementType.outbound => 'Stock out',
    MovementType.damage => 'Damage',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPositive = widget.type == MovementType.inbound;

    return AlertDialog(
      title: Text('$_positiveLabel — ${widget.item.name}'),
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
            decoration: InputDecoration(
              labelText: 'Quantity',
              prefixIcon: const Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: const Icon(Icons.notes),
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
