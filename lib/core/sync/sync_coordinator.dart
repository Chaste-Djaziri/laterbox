import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_service.dart';

class SyncCoordinator {
  SyncCoordinator(this._service);

  final SyncService _service;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _retryTimer;
  int _retryAttempt = 0;
  bool _disposed = false;

  void start({
    required Stream<List<ConnectivityResult>> connectivityChanges,
    Stream<AuthState>? authChanges,
  }) {
    _subscriptions.add(
      connectivityChanges.listen((results) {
        if (!results.contains(ConnectivityResult.none)) requestSync();
      }),
    );
    if (authChanges != null) {
      _subscriptions.add(authChanges.listen((_) => requestSync()));
    }
    requestSync();
  }

  void requestSync() {
    if (_disposed) return;
    unawaited(_attemptSync());
  }

  Future<void> syncNow() async {
    if (_disposed) return;
    await _attemptSync();
  }

  Future<void> _attemptSync() async {
    final result = await _service.sync();
    if (_disposed || result.skipped) return;

    if (result.succeeded) {
      _retryAttempt = 0;
      _retryTimer?.cancel();
      return;
    }

    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_retryTimer?.isActive ?? false) return;
    final seconds = (1 << _retryAttempt.clamp(0, 8)) * 2;
    _retryAttempt++;
    _retryTimer = Timer(Duration(seconds: seconds), requestSync);
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }
}
