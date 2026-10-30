import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/domain/models.dart';
import 'core/presentation/app_shell.dart';
import 'core/presentation/theme.dart';
import 'core/presentation/widgets.dart';
import 'core/providers.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/backup/presentation/backup_screen.dart';
import 'features/catalog/presentation/inventory_screen.dart';
import 'features/catalog/presentation/stock_screen.dart';
import 'features/entry/presentation/entry_screen.dart';
import 'features/entry/presentation/entry_detail_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/khata/presentation/khata_screen.dart';
import 'features/ledger/presentation/roznamcha_screen.dart';
import 'features/rates/presentation/rates_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'l10n/app_localizations.dart';
import 'l10n/strings.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(activeSessionProvider);
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      if (session == null) return path == '/login' ? null : '/login';
      final auth = ref.read(authProvider);
      if (auth.desktopRequest != null && !auth.desktopCompleted) {
        return path == '/desktop-approve' ? null : '/desktop-approve';
      }
      if (!session.hasShop) return path == '/onboarding' ? null : '/onboarding';
      if (path == '/login' || path == '/onboarding') return '/';
      if (session.role != AppRole.owner &&
          [
            '/reports',
            '/backup',
            '/settings',
            '/users',
          ].any((p) => path == p || path.startsWith('$p/'))) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/desktop-approve',
        builder: (_, state) => const DesktopApprovalScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, state) => const HomeScreen()),
          GoRoute(
            path: '/roznamcha',
            builder: (_, state) => const RoznamchaScreen(),
          ),
          GoRoute(
            path: '/khata',
            builder: (_, state) => const KhataScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    PersonScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/more', builder: (_, state) => const MoreScreen()),
          GoRoute(
            path: '/stock',
            builder: (_, state) => StockScreen(
              key: ValueKey(state.uri.queryParameters['view']),
              showGodams: state.uri.queryParameters['view'] == 'godams',
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ProductScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/inventory', redirect: (_, state) => '/stock'),
          GoRoute(
            path: '/inventory/:id',
            redirect: (_, state) => '/stock/${state.pathParameters['id']}',
          ),
          GoRoute(path: '/godam', redirect: (_, state) => '/stock?view=godams'),
          GoRoute(path: '/rates', builder: (_, state) => const RatesScreen()),
          GoRoute(
            path: '/expenses',
            builder: (_, state) => const ReportsScreen(expensesOnly: true),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, state) => const ReportsScreen(),
          ),
          GoRoute(path: '/backup', builder: (_, state) => const BackupScreen()),
          GoRoute(
            path: '/settings',
            builder: (_, state) => const SettingsScreen(),
          ),
          GoRoute(path: '/users', builder: (_, state) => const UsersScreen()),
          GoRoute(
            path: '/entry-detail/:id',
            builder: (_, state) =>
                EntryDetailScreen(id: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/entry/:kind',
        builder: (context, state) {
          final kind = EntryKind.values
              .where((k) => k.name == state.pathParameters['kind'])
              .firstOrNull;
          if (kind == null) {
            return Scaffold(body: EmptyState(message: context.tr('noResults')));
          }
          return EntryScreen(
            kind: kind,
            personId: state.uri.queryParameters['person'],
            receiving: state.uri.queryParameters['receive'] != 'false',
            fromLocation: state.uri.queryParameters['from'],
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/'),
          child: Text(context.tr('home')),
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

class PestiKhataApp extends ConsumerWidget {
  const PestiKhataApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.tr('appName'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: settings.themeMode,
      locale: Locale(settings.language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.ltr, child: child!),
    );
  }
}
