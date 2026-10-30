import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';
import '../../demo/data/demo_data.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(activeSessionProvider)!.role == AppRole.owner;
    final links = [
      ('stock', Icons.inventory_2_outlined),
      ('expenses', Icons.receipt_long_outlined),
      ('rates', Icons.price_change_outlined),
      if (owner) ...[
        ('reports', Icons.bar_chart_rounded),
        ('backup', Icons.backup_outlined),
        ('settings', Icons.settings_outlined),
        ('users', Icons.group_outlined),
      ],
    ];
    return PageBody(
      children: [
        Text(
          ref.watch(activeSessionProvider)!.shopName,
          style: context.fonts.headlineSmall,
        ),
        Text(
          context.tr(owner ? 'owner' : 'staff'),
          style: context.fonts.bodyLarge,
        ),
        GlassCard(
          child: Column(
            children: links
                .map(
                  (link) => ListTile(
                    minVerticalPadding: 18,
                    leading: Icon(link.$2, color: context.colors.primary),
                    title: Text(context.tr(link.$1)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/${link.$1}'),
                  ),
                )
                .toList(),
          ),
        ),
        ActionButton(
          label: context.tr('signOut'),
          icon: Icons.logout,
          onPressed: ref.read(authProvider).signOut,
        ),
      ],
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider),
        controller = ref.read(settingsProvider.notifier),
        session = ref.watch(activeSessionProvider)!;
    return PageBody(
      maxWidth: 760,
      children: [
        SectionTitle(context.tr('appearance')),
        SegmentedButton<ThemeMode>(
          segments: ThemeMode.values
              .map(
                (m) => ButtonSegment(value: m, label: Text(context.tr(m.name))),
              )
              .toList(),
          selected: {settings.themeMode},
          onSelectionChanged: (v) => controller.theme(v.first),
        ),
        SectionTitle(context.tr('language')),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'en', label: Text(context.tr('english'))),
            ButtonSegment(value: 'ur', label: Text(context.tr('romanUrdu'))),
          ],
          selected: {settings.language},
          onSelectionChanged: (v) => controller.language(v.first),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('yourShop'), style: context.fonts.titleLarge),
              Text(session.shopName),
              SelectableText('${context.tr('shopId')}: ${session.shopId}'),
              Text('${context.tr('role')}: ${context.tr(session.role.name)}'),
            ],
          ),
        ),
        if (session.demo)
          ShopData(
            builder: (data) => GlassCard(
              child: SwitchListTile.adaptive(
                title: Text(context.tr('seedDemoData')),
                subtitle: Text(context.tr('demoDataHelp')),
                value: data.records.isNotEmpty,
                onChanged: (on) async {
                  try {
                    if (on) {
                      await DemoData.seed(ref.read(repositoryProvider));
                    } else if (await confirmAction(
                      context,
                      context.tr('clearDemoData'),
                    )) {
                      await DemoData.clear(ref.read(repositoryProvider));
                    }
                  } catch (e) {
                    if (context.mounted) context.toast(context.failure(e));
                  }
                },
              ),
            ),
          )
        else
          OutlinedButton.icon(
            icon: const Icon(Icons.science_outlined),
            label: Text(context.tr('openDemo')),
            onPressed: ref.read(authProvider).enterDemo,
          ),
        Text(context.tr('aboutApp'), style: context.fonts.bodySmall),
      ],
    );
  }
}

final membersProvider = StreamProvider<List<Json>>((ref) async* {
  final auth = ref.watch(authProvider),
      session = ref.watch(activeSessionProvider)!,
      prefs = ref.watch(preferencesProvider);
  if (session.demo) {
    yield [
      {'userId': 'demo-owner', 'role': 'owner', 'label': 'Demo Owner'},
    ];
    return;
  }
  final key = 'members_${session.shopId}',
      cached = prefs.getString('members_${session.shopId}');
  if (cached != null) {
    yield (jsonDecode(cached) as List)
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }
  try {
    final result = await auth.call('listMembers', {});
    final members = (result['members'] as List)
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    await prefs.setString(key, jsonEncode(members));
    yield members;
  } catch (_) {
    if (cached == null) rethrow;
  }
});

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageBody(
    maxWidth: 760,
    children: [
      Text(context.tr('usersHelp'), style: context.fonts.bodyLarge),
      ActionButton(
        label: context.tr('inviteStaff'),
        icon: Icons.person_add_alt,
        onPressed: () async {
          final result = await ref.read(authProvider).call('createInvite', {});
          final code = result['code'] as String;
          if (!context.mounted) return;
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(ctx.tr('inviteCode')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(code, style: ctx.fonts.headlineMedium),
                  const SizedBox(height: 12),
                  Text(ctx.tr('inviteHelp')),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (ctx.mounted) ctx.toast(ctx.tr('copied'));
                  },
                  child: Text(ctx.tr('copy')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(ctx.tr('done')),
                ),
              ],
            ),
          );
        },
      ),
      ref
          .watch(membersProvider)
          .when(
            data: (members) => GlassCard(
              child: Column(
                children: members
                    .map(
                      (m) => ListTile(
                        title: Text((m['label'] ?? m['userId']) as String),
                        subtitle: Text(context.tr(m['role'] as String)),
                        trailing: m['role'] == 'owner'
                            ? null
                            : IconButton(
                                tooltip: context.tr('revokeAccess'),
                                icon: const Icon(Icons.person_remove_outlined),
                                onPressed: () async {
                                  if (!await confirmAction(
                                    context,
                                    context.tr('revokeHelp'),
                                  )) {
                                    return;
                                  }
                                  try {
                                    await ref.read(authProvider).call(
                                      'revokeMember',
                                      {'userId': m['userId']},
                                    );
                                    ref.invalidate(membersProvider);
                                  } catch (e) {
                                    if (context.mounted) {
                                      context.toast(context.failure(e));
                                    }
                                  }
                                },
                              ),
                      ),
                    )
                    .toList(),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => EmptyState(message: context.failure(e)),
          ),
    ],
  );
}
