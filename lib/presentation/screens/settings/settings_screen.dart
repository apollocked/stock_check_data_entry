import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_tokens.dart';
import '../../router/app_routes.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/feedback/app_feedback.dart';
import '../../widgets/motion/entrance.dart';
import 'widgets/settings_group.dart';
import 'widgets/theme_mode_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You will need your email and password to sign back in.',
      confirmLabel: 'Sign out',
      icon: Icons.logout_rounded,
    );
    if (!confirmed) return;
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sections = <Widget>[
      const SectionHeader('Appearance'),
      const ThemeModePicker(),
      const SectionHeader('Store'),
      SettingsGroup(
        children: [
          SettingsTile(
            icon: Icons.tune_rounded,
            title: 'Item fields',
            subtitle: 'Choose what you record for each item',
            onTap: () => context.push(AppRoutes.itemFields),
          ),
        ],
      ),
      const SectionHeader('Account'),
      SettingsGroup(
        children: [
          SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            color: cs.error,
            onTap: () => _signOut(context),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xxl),
        children: [
          for (var i = 0; i < sections.length; i++)
            sections[i].entrance(index: i),
        ],
      ),
    );
  }
}
