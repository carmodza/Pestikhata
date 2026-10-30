import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/auth/data/auth_repository.dart';
import '../data/shop_repository.dart';
import 'firestore_rest.dart';

enum SyncState { synced, pending, offline, local, blocked }

class SyncService {
  SyncService(this.repository, this.auth)
    : _remote = FirestoreRest(auth, repository.shopId);
  final FirestoreRest _remote;
  final ShopRepository repository;
  final AuthRepository auth;
  final _states = StreamController<SyncState>.broadcast();
  Stream<SyncState> get states => _states.stream;
  SyncState current = SyncState.pending;
  StreamSubscription<int>? _pending;
  StreamSubscription<List<ConnectivityResult>>? _network;
  Timer? _timer;
  bool _running = false, _again = false, _closed = false;
  void start() {
    if (auth.session?.demo == true || !auth.configured) {
      _set(SyncState.local);
      return;
    }
    _pending = repository.watchPending().listen((_) => sync());
    _network = Connectivity().onConnectivityChanged.listen((_) => sync());
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => sync());
    unawaited(sync());
  }

  void _set(SyncState state) {
    if (_closed) return;
    current = state;
    _states.add(state);
  }

  Future<void> sync() async {
    if (_closed || auth.session?.demo == true || !auth.configured) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      final interfaces = await Connectivity().checkConnectivity();
      if (interfaces.every((i) => i == ConnectivityResult.none)) {
        _set(SyncState.offline);
        return;
      }
      _set(SyncState.pending);
      await auth.refreshProfile();
      if (_closed || auth.session?.shopId != repository.shopId) {
        return;
      }
      final remote = _remote;
      // Push before pull so LWW conflict losers are resolved explicitly.
      for (final local in await repository.pending()) {
        if (_closed) return;
        final winner = await remote.push(local);
        await repository.mergeRemote(winner);
        await repository.acknowledge(local);
      }
      final changes = await remote.pull(since: await repository.syncCursor());
      for (final record in changes.records) {
        if (_closed) return;
        await repository.mergeRemote(record);
      }
      if (changes.cursor != null) {
        await repository.saveSyncCursor(changes.cursor!);
      }
      _set(
        (await repository.pending()).isEmpty
            ? SyncState.synced
            : SyncState.pending,
      );
    } on ApiFailure catch (error) {
      if (error.status == 401 || error.status == 403) {
        try {
          await auth.refreshProfile();
        } on ApiFailure catch (profileError) {
          if (profileError.status == 401 || profileError.status == 403) {
            await auth.signOut();
          }
        } catch (_) {
          /* Keep the cached session when the network is unavailable. */
        }
      }
      _set(
        error.status == 401 || error.status == 403
            ? SyncState.blocked
            : SyncState.pending,
      );
    } catch (_) {
      _set(SyncState.offline);
    } finally {
      _running = false;
      if (_again && !_closed) {
        _again = false;
        scheduleMicrotask(sync);
      }
    }
  }

  Future<void> dispose() async {
    _remote.close();
    _closed = true;
    _timer?.cancel();
    await _pending?.cancel();
    await _network?.cancel();
    await _states.close();
  }
}
