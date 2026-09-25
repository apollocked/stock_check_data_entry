import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/stock_report.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/motion/animated_number.dart';

/// The headline card: total stock value, counting up, on the brand gradient.
class ValueHeroCard extends StatelessWidget {
  final StockReport report;

  const ValueHeroCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const onBrand = Colors.white;
    final soft = onBrand.withAlpha(210);

    Widget stat(String label, num value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedNumber(
          value: value,
          format: Fmt.compact,
          style: text.titleLarge?.copyWith(color: onBrand),
        ),
        Text(label, style: text.labelMedium?.copyWith(color: soft)),
      ],
    );

    return SurfaceCard(
      padding: const EdgeInsets.all(Gap.xl),
      radius: Radii.xl,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.brandGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: soft),
              const SizedBox(width: Gap.sm),
              Text(
                'Stock value',
                style: text.titleSmall?.copyWith(color: soft),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          AnimatedNumber(
            value: report.stockValue,
            format: Fmt.money,
            style: text.displaySmall?.copyWith(color: onBrand),
          ),
          const SizedBox(height: Gap.xl),
          Row(
            children: [
              Expanded(child: stat('Items', report.totalItems)),
              Expanded(child: stat('Units in stock', report.totalUnits)),
            ],
          ),
        ],
      ),
    );
  }
}
