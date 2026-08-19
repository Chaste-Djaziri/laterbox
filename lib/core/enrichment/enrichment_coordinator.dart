import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/app_database.dart';
import '../../features/enrichment/data/enrichment_repository.dart';
import '../../features/enrichment/domain/enrichment_result.dart';
import '../../features/enrichment/domain/enrichment_service.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/laterbox_item.dart';

/// Watches for URL items that need enrichment, drains the queue with a single
/// in-flight job per item, and schedules retries on a backoff ladder.
class EnrichmentCoordinator {
  EnrichmentCoordinator({
    required this.service,
    required this.repository,
    Duration? Function(int completedAttempts)? retryDelayResolver,
  }) : _retryDelayResolver = retryDelayResolver ?? _defaultRetryDelay;

  final EnrichmentService service;
  final EnrichmentRepository repository;
  final Duration? Function(int completedAttempts) _retryDelayResolver;

  final Set<String> _inFlight = {};
  final Map<String, Timer> _retryTimers = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _networkAvailable = true;
  bool _disposed = false;
  bool _processing = false;

  void start({
    required Stream<List<LaterBoxItem>> items,
    required Stream<List<ConnectivityResult>> connectivityChanges,
    Stream<AuthState>? authChanges,
  }) {
    _subscriptions.add(items.listen((_) => unawaited(_processQueue())));
    _subscriptions.add(connectivityChanges.listen((results) {
      _networkAvailable = !results.contains(ConnectivityResult.none);
      if (_networkAvailable) unawaited(_processQueue());
    }));
    if (authChanges != null) {
      _subscriptions.add(authChanges.listen((_) => unawaited(_processQueue())));
    }
    unawaited(_recoverStuck());
  }

  Future<void> _recoverStuck() async {
    if (_disposed) return;
    await repository.resetStuckEnriching();
    await _processQueue();
  }

  Future<void> _processQueue() async {
    if (_disposed || !_networkAvailable || _processing) return;
    _processing = true;
    try {
      final candidates = await repository.itemsToEnrich();
      for (final candidate in candidates) {
        final id = candidate.item.id;
        if (_inFlight.contains(id) || _retryTimers.containsKey(id)) continue;
        if (candidate.metadata?.status == 'enriching') continue;
        _inFlight.add(id);
        unawaited(_enrich(candidate));
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _enrich(EnrichmentCandidate candidate) async {
    try {
      final result = await service.enrich(_toItem(candidate.item));
      if (result is EnrichmentFailed && result.retryable) {
        final delay = _retryDelayResolver(result.attemptCount);
        if (delay != null) _scheduleRetry(candidate.item.id, delay);
      }
    } finally {
      _inFlight.remove(candidate.item.id);
    }
  }

  void _scheduleRetry(String itemId, Duration delay) {
    _retryTimers[itemId]?.cancel();
    _retryTimers[itemId] = Timer(delay, () {
      _retryTimers.remove(itemId);
      unawaited(_processQueue());
    });
  }

  static LaterBoxItem _toItem(Item item) {
    return LaterBoxItem(
      id: item.id,
      url: item.url,
      title: item.title,
      text: item.textContent,
      type: item.type,
      favorite: item.favorite,
      status: ItemStatus.fromDatabase(item.status),
      createdAt: item.createdAt,
    );
  }

  static Duration? _defaultRetryDelay(int completedAttempts) {
    return switch (completedAttempts) {
      1 => const Duration(seconds: 30),
      2 => const Duration(minutes: 5),
      3 => const Duration(minutes: 30),
      _ => null,
    };
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }
}