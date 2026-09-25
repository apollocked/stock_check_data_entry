import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/member.dart';
import '../../controllers/auth_controllers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/common/icon_tile.dart';
import '../../widgets/common/surface_card.dart';
import '../../widgets/feedback/app_feedback.dart';
import '../../widgets/motion/entrance.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/skeleton.dart';
import 'widgets/add_member_sheet.dart';
import 'widgets/member_tile.dart';
import 'widgets/settings_group.dart';

/// Who can use the store. Signing up alone gives no access; a member has to
/// add the account here (enforced by the database, see supabase/schema/).
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, Member m) async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove access?',
      message: '${m.email} will no longer see or change the store.',
      confirmLabel: 'Remove',
      destructive: true,
      icon: Icons.person_remove_rounded,
    );
    if (!confirmed) return;
    try {
      await ref.read(accessRepositoryProvider).removeMember(m.userId);
      ref.invalidate(membersProvider);
      if (context.mounted) {
        showAppSnack(context, 'Removed ${m.email}', kind: SnackKind.success);
      }
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final members = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Team')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddMemberSheet(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add member'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(membersProvider);
          await ref.read(membersProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 120),
          children: [
            SurfaceCard(
              color: cs.secondaryContainer.withAlpha(120),
              child: Row(
                children: [
                  IconTile(icon: Icons.shield_rounded, color: cs.secondary),
                  const SizedBox(width: Gap.md),
                  const Expanded(
                    child: Text(
                      'Only people listed here can see or change the store. '
                      'Creating an account is not enough on its own.',
                    ),
                  ),
                ],
              ),
            ).entrance(),
            const SizedBox(height: Gap.lg),
            members.when(
              loading: () => const SkeletonList(
                count: 3,
                itemHeight: 68,
                padding: EdgeInsets.zero,
              ),
              error: (error, _) => SizedBox(
                height: 360,
                child: ErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(membersProvider),
                ),
              ),
              data: (list) => SettingsGroup(
                children: [
                  for (final m in list)
                    MemberTile(
                      member: m,
                      onRemove: m.isMe ? null : () => _remove(context, ref, m),
                    ),
                ],
              ).entrance(index: 1),
            ),
          ],
        ),
      ),
    );
  }
}
