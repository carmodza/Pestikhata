import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/strings.dart';
import '../domain/models.dart';
import '../providers.dart';
import '../sync/sync_service.dart';
import 'widgets.dart';

Future<void> showEntryDial(BuildContext context) async {
  final kind = await showModalBottomSheet<EntryKind>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface.withValues(alpha: .97),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(ctx.tr('newEntry'), style: ctx.fonts.headlineSmall),
            const SizedBox(height: 16),
            for (final kind in EntryKind.values)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 180 + kind.index * 65),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(60),
                    ),
                    onPressed: () => Navigator.pop(ctx, kind),
                    icon: Icon(
                      [
                        Icons.payments_outlined,
                        Icons.science_outlined,
                        Icons.grass,
                        Icons.local_gas_station_outlined,
                        Icons.receipt_long_outlined,
                      ][kind.index],
                    ),
                    label: Text(ctx.tr(kind.name)),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  if (kind != null && context.mounted) context.push('/entry/${kind.name}');
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final selected = path == '/'
        ? 0
        : path.startsWith('/roznamcha')
        ? 1
        : path.startsWith('/khata')
        ? 3
        : 4;
    final session = ref.watch(activeSessionProvider)!;
    final state = ref.watch(syncStateProvider).value ?? SyncState.pending;
    final pending = ref.watch(pendingProvider).value ?? 0;
    final title = path == '/'
        ? 'appName'
        : path.startsWith('/entry-detail')
        ? 'entryDetails'
        : path.split('/')[1];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.spa_rounded, color: context.colors.primary),
            const SizedBox(width: 10),
            Text(context.tr(title)),
          ],
        ),
        actions: [
          IconButton(
            tooltip:
                '${context.tr(state.name)}${pending > 0 ? ' ($pending)' : ''}',
            icon: Icon(
              switch (state) {
                SyncState.synced => Icons.cloud_done_outlined,
                SyncState.pending => Icons.cloud_upload_outlined,
                SyncState.offline => Icons.cloud_off_outlined,
                SyncState.local => Icons.devices_outlined,
                SyncState.blocked => Icons.cloud_off,
              },
              color: state == SyncState.blocked
                  ? context.colors.error
                  : context.colors.primary,
            ),
            onPressed: () {
              context.toast(
                '${context.tr(state.name)}${pending > 0 ? ' · $pending ${context.tr('pendingWrites')}' : ''}',
              );
              ref.read(syncServiceProvider).sync();
            },
          ),
          if (session.demo)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(label: Text(context.tr('demo'))),
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.primaryContainer.withValues(alpha: .16),
              Colors.transparent,
              context.colors.tertiaryContainer.withValues(alpha: .1),
            ],
          ),
        ),
        child: SafeArea(child: child),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) {
          if (index == 2) {
            showEntryDial(context);
            return;
          }
          context.go(['/', '/roznamcha', '/', '/khata', '/more'][index]);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.tr('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            label: context.tr('roznamcha'),
          ),
          NavigationDestination(
            icon: Icon(
              Icons.add_circle,
              size: 40,
              color: context.colors.primary,
            ),
            label: context.tr('entry'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: context.tr('khata'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_rounded),
            label: context.tr('more'),
          ),
        ],
      ),
    );
  }
}
