import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../controllers/auth_actions.dart';
import '../../controllers/inventory_controllers.dart';
import '../../router/app_routes.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/feedback/app_feedback.dart';
import '../../widgets/motion/entrance.dart';
import 'widgets/change_password_sheet.dart';
import 'widgets/settings_group.dart';
import 'widgets/store_profile_sheet.dart';
import 'widgets/theme_mode_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You will need your email and password to sign back in.',
      confirmLabel: 'Sign out',
      icon: Icons.logout_rounded,
    );
    if (!confirmed) return;
    try {
      await ref.read(authActionsProvider).signOut();
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final store = ref.watch(storeProvider).value;
    final email = ref.read(authActionsProvider).currentEmail ?? '';

    final sections = <Widget>[
      const SectionHeader('Appearance'),
      const ThemeModePicker(),
      const SectionHeader('Store'),
      SettingsGroup(
        children: [
          SettingsTile(
            icon: Icons.storefront_rounded,
            title: store?.name ?? 'Store profile',
            subtitle: store?.location ?? 'Name and location',
            onTap: store == null
                ? null
                : () => showStoreProfileSheet(context, store),
          ),
          SettingsTile(
            icon: Icons.tune_rounded,
            title: 'Item fields',
            subtitle: 'Choose what you record for each item',
            onTap: () => context.push(AppRoutes.itemFields),
          ),
          SettingsTile(
            icon: Icons.group_rounded,
            title: 'Team',
            subtitle: 'Who can use this store',
            onTap: () => context.push(AppRoutes.team),
          ),
        ],
      ),
      const SectionHeader('Account'),
      SettingsGroup(
        children: [
          SettingsTile(
            icon: Icons.person_rounded,
            title: 'Signed in',
            subtitle: email,
          ),
          SettingsTile(
            icon: Icons.lock_reset_rounded,
            title: 'Change password',
            onTap: () => showChangePasswordSheet(context),
          ),
          SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            color: cs.error,
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Settings')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xxl),
            sliver: SliverList.list(
              children: [
                for (var i = 0; i < sections.length; i++)
                  sections[i].entrance(index: i),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
