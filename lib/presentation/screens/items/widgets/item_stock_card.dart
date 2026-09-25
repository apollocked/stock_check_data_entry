import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/item.dart';
import '../../../../domain/entities/stock_change.dart';
import '../../../../domain/entities/stock_level.dart';
import '../../../widgets/common/stock_badge.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/motion/animated_number.dart';
import '../../stock/stock_action_sheet.dart';
import '../../stock/widgets/stock_mode_selector.dart';

/// Live stock count, its value, and one-tap buttons for each stock action.
class ItemStockCard extends StatelessWidget {
  final Item item;

  const ItemStockCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = StockLevel.of(item.quantity).color(context);
    final value = item.quantity * (item.price ?? 0);

    return SurfaceCard(
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedNumber(
                value: item.quantity,
                format: (v) => Fmt.count(v),
                style: text.displayMedium?.copyWith(color: color),
              ),
              const SizedBox(width: Gap.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Text('units', style: text.titleMedium),
              ),
              const Spacer(),
              StockBadge(quantity: item.quantity),
            ],
          ),
          Text(
            'Stock value ${Fmt.money(value)}',
            style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              for (final mode in StockMode.values) ...[
                if (mode != StockMode.values.first)
                  const SizedBox(width: Gap.sm),
                Expanded(
                  child: _ActionButton(item: item, mode: mode),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Item item;
  final StockMode mode;

  const _ActionButton({required this.item, required this.mode});

  @override
  Widget build(BuildContext context) {
    final color = mode.color(context);
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: color.withAlpha(34),
        foregroundColor: color,
        minimumSize: const Size(0, 64),
        padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      onPressed: () => showStockActionSheet(context, item: item, mode: mode),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mode.icon),
          const SizedBox(height: Gap.xs),
          Text(mode.shortLabel, maxLines: 1),
        ],
      ),
    );
  }
}
