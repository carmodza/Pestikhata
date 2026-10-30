import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../features/auth/data/auth_repository.dart';
import 'database/app_database.dart';
import 'data/shop_repository.dart';
import 'sync/sync_service.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final authProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError(),
);
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => unawaited(db.close()));
  return db;
});
final sessionProvider = StreamProvider<AppSession?>((ref) async* {
  final auth = ref.watch(authProvider);
  yield auth.session;
  yield* auth.changes;
});
final activeSessionProvider = Provider<AppSession?>(
  (ref) => ref.watch(sessionProvider).value ?? ref.watch(authProvider).session,
);
final repositoryProvider = Provider.autoDispose<ShopRepository>((ref) {
  final session = ref.watch(activeSessionProvider)!;
  final prefs = ref.watch(preferencesProvider);
  var device = prefs.getString('device_id');
  if (device == null) {
    device = const Uuid().v4();
    unawaited(prefs.setString('device_id', device));
  }
  return ShopRepository(
    ref.watch(databaseProvider),
    session.shopId,
    device,
    session.role,
    session.userId,
  );
});
final snapshotProvider = StreamProvider.autoDispose<ShopSnapshot>(
  (ref) => ref.watch(repositoryProvider).watch(),
);
final pendingProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(repositoryProvider).watchPending(),
);
final syncServiceProvider = Provider.autoDispose<SyncService>((ref) {
  final sync = SyncService(
    ref.watch(repositoryProvider),
    ref.watch(authProvider),
  );
  sync.start();
  ref.onDispose(() => unawaited(sync.dispose()));
  return sync;
});
final syncStateProvider = StreamProvider.autoDispose<SyncState>((ref) async* {
  final sync = ref.watch(syncServiceProvider);
  yield sync.current;
  yield* sync.states;
});

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.language = 'en',
  });
  final ThemeMode themeMode;
  final String language;
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final prefs = ref.watch(preferencesProvider);
    return SettingsState(
      themeMode: ThemeMode.values.byName(prefs.getString('theme') ?? 'system'),
      language: prefs.getString('language') ?? 'en',
    );
  }

  Future<void> theme(ThemeMode value) async {
    state = SettingsState(themeMode: value, language: state.language);
    await ref.read(preferencesProvider).setString('theme', value.name);
  }

  Future<void> language(String value) async {
    state = SettingsState(themeMode: state.themeMode, language: value);
    await ref.read(preferencesProvider).setString('language', value);
  }
}

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
