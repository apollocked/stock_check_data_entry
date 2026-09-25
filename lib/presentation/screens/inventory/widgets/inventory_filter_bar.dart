import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/stock_level.dart';
import '../../../controllers/inventory_controllers.dart';
import '../../../controllers/inventory_query.dart';
import '../../../widgets/common/stock_badge.dart';

/// Filter chips with live counts: All, Low, Out, Negative.
class InventoryFilterBar extends ConsumerWidget {
  const InventoryFilterBar({super.key});

  static const _levels = [
    StockLevel.low,
    StockLevel.out,
    StockLevel.negative,
    StockLevel.healthy,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(inventoryQueryProvider).level;
    final items = ref.watch(itemsProvider).value ?? const [];
    final counts = countByLevel(items);
    final controller = ref.read(inventoryQueryProvider.notifier);

    void select(StockLevel? level) {
      HapticFeedback.selectionClick();
      controller.setLevel(level);
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        children: [
          _Chip(
            label: 'All · ${items.length}',
            selected: selected == null,
            onTap: () => select(null),
          ),
          for (final level in _levels)
            if (counts[level]! > 0 || selected == level)
              _Chip(
                label: '${level.label} · ${counts[level]}',
                icon: level.icon,
                color: level.color(context),
                selected: selected == level,
                onTap: () => select(selected == level ? null : level),
              ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tint = color ?? cs.primary;
    return Padding(
      padding: const EdgeInsets.only(right: Gap.sm),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onTap(),
        avatar: icon == null
            ? null
            : Icon(icon, size: 18, color: selected ? cs.onPrimary : tint),
        label: Text(label),
        selectedColor: tint,
        labelStyle: TextStyle(
          color: selected ? cs.onPrimary : cs.onSurface,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: selected ? tint : cs.outlineVariant),
      ),
    );
  }
}
