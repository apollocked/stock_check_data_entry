import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';

/// Horizontal strip of recent days, today on the right. Tapping a day
/// selects it; the selected pill grows and fills with the primary color.
class DayStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final int days;

  const DayStrip({
    super.key,
    required this.selected,
    required this.onSelect,
    this.days = 60,
  });

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        itemCount: days,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
        itemBuilder: (context, i) {
          final day = DateTime(today.year, today.month, today.day - i);
          return _DayPill(
            day: day,
            isToday: i == 0,
            selected: sameDay(day, selected),
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(day);
            },
          );
        },
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool selected;
  final VoidCallback onTap;

  const _DayPill({
    required this.day,
    required this.isToday,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fg = selected ? cs.onPrimary : cs.onSurface;

    return Semantics(
      selected: selected,
      button: true,
      label: Fmt.day(day),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.emphasized,
          width: selected ? 64 : 52,
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: isToday && !selected ? Border.all(color: cs.primary) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isToday ? 'Today' : Fmt.weekday(day),
                style: text.labelSmall?.copyWith(color: fg.withAlpha(200)),
              ),
              const SizedBox(height: 2),
              Text('${day.day}', style: text.titleLarge?.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
