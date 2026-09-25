import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/member.dart';

/// A team member: initial avatar, email, when they were added, and a
/// remove button (not shown for yourself).
class MemberTile extends StatelessWidget {
  final Member member;
  final VoidCallback? onRemove;

  const MemberTile({super.key, required this.member, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = member.email.isEmpty ? '?' : member.email[0].toUpperCase();
    final palette = [cs.primary, cs.tertiary, cs.secondary];
    final color = palette[member.email.hashCode.abs() % palette.length];

    return ListTile(
      minTileHeight: 68,
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(40),
        foregroundColor: color,
        child: Text(
          initial,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(member.email, overflow: TextOverflow.ellipsis)),
          if (member.isMe) ...[
            const SizedBox(width: Gap.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                'You',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: cs.onPrimaryContainer),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text('Added ${Fmt.day(member.addedAt)}'),
      trailing: onRemove == null
          ? null
          : IconButton(
              tooltip: 'Remove access',
              onPressed: onRemove,
              icon: Icon(Icons.person_remove_rounded, color: cs.error),
            ),
    );
  }
}
