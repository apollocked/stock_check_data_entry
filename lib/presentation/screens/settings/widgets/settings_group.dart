import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../widgets/common/icon_tile.dart';

/// A rounded group of settings rows, separated by thin dividers.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.lg),
      child: ColoredBox(
        color: cs.surfaceContainerLow,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(indent: 72),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      minTileHeight: 64,
      shape: const RoundedRectangleBorder(),
      leading: IconTile(icon: icon, color: tint, size: 40),
      title: Text(title, style: color == null ? null : TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing:
          trailing ??
          (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
      onTap: onTap,
    );
  }
}
