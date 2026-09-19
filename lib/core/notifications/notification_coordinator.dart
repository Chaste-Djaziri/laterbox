import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_provider.dart';
import '../billing/billing_providers.dart';
import '../database/app_database.dart';
import '../database/database_providers.dart';
import '../router/app_router.dart';
import '../supabase/supabase_provider.dart';
import '../sync/sync_providers.dart';
import 'notification_identity.dart';
import 'notification_service.dart';

final notificationCoordinatorProvider =
    ChangeNotifierProvider<NotificationCoordinator>((ref) {
      final coordinator = NotificationCoordinator(
        ref.read(appDatabaseProvider),
        ref.read(supabaseClientProvider),
        open: (id) async {
          await ref.read(syncCoordinatorProvider).syncNow();
          final item = id == null
              ? null
              : await ref.read(appDatabaseProvider).itemById(id);
          final user = ref.read(activeUserIdProvider);
          final available =
              item != null && item.deletedAt == null && item.userId == user;
          ref
              .read(appRouterProvider)
              .go(available ? '/item/${item.id}' : '/inbox');
        },
      );
      void configure() => coordinator.configure(
        ref.read(activeUserIdProvider),
        ref.read(hasProAccessProvider),
      );
      ref.listen(activeUserIdProvider, (_, _) => configure());
      ref.listen(hasProAccessProvider, (_, _) => configure());
      configure();
      return coordinator;
    });

class NotificationCoordinator extends ChangeNotifier
    with WidgetsBindingObserver {
  NotificationCoordinator(this.db, this.client, {required this.open}) {
    WidgetsBinding.instance.addObserver(this);
    _changes = service.changes.stream.listen((_) => refresh());
    _taps = service.taps.stream.listen(_openPayload);
    _messages = service.messages.stream.listen((data) {
      if (enabled &&
          data['user_id'] == _user &&
          (data['kind'] == 'return' ? returns : saves)) {
        _enqueue(() => _present(data));
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }
  final AppDatabase db;
  final SupabaseClient? client;
  final Future<void> Function(String?) open;
  final service = InboxNotificationService.instance;
  String? _user;
  bool _pro = false;
  bool _configured = false;
  bool _disposed = false;
  bool enabled = false;
  bool returns = true;
  bool saves = true;
  bool busy = false;
  String? status;
  String? _registeredUser;
  String? _registeredId;
  String? _registrationSignature;
  List<Item> _items = [];
  final Map<String, String> _scheduled = {};
  Future<void> _queue = Future.value();
  StreamSubscription<dynamic>? _itemsSubscription, _changes, _taps, _messages;
  Timer? _timer;
  String get _key => 'inbox_notifications_${_user ?? "guest"}';

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _enqueue(Future<void> Function() action) {
    _queue = _queue
        .then((_) async {
          if (!_disposed) await action();
        })
        .catchError((Object error) {
          status = 'Notifications could not update. Check device permissions and cloud setup.';
          busy = false;
          _notify();
        });
  }

  void configure(String? user, bool pro) {
    _enqueue(() async {
      final changed = !_configured || user != _user;
      if (!changed && pro == _pro) return;
      if (changed) {
        await _unregister();
        await _itemsSubscription?.cancel();
        await service.initialize();
        await service.cancelAll();
        _scheduled.clear();
        _items = [];
        _user = user;
        _configured = true;
        final prefs = await SharedPreferences.getInstance();
        final saved =
            jsonDecode(prefs.getString(_key) ?? '{}') as Map<String, dynamic>;
        enabled = saved['enabled'] == true;
        returns = saved['returns'] != false;
        saves = saved['saves'] != false;
        _itemsSubscription = db.watchAllItemsWithMetadata(user).listen((rows) {
          _items = rows.map((row) => row.$1).toList();
          refresh();
        });
      }
      _pro = pro;
      await _refresh();
      final launch = service.launchPayload;
      if (launch != null) {
        service.launchPayload = null;
        // Defer navigation until the router and splash screen have mounted.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openPayload(launch),
        );
      }
    });
  }

  Future<void> _unregister() async {
    service.cloudActive = false;
    if (_registeredId != null &&
        client?.auth.currentUser?.id == _registeredUser) {
      await client!
          .from('notification_installations')
          .delete()
          .eq('id', _registeredId!);
    }
    _registeredId = null;
    _registeredUser = null;
    _registrationSignature = null;
  }

  Future<void> update({
    bool? enable,
    bool? scheduledReturns,
    bool? remoteSaves,
  }) async {
    busy = true;
    _notify();
    _enqueue(() async {
      if (enable == true && !await service.permission(request: true)) {
        status = 'Allow LaterBox notifications in device settings.';
        busy = false;
        _notify();
        return;
      }
      enabled = enable ?? enabled;
      returns = scheduledReturns ?? returns;
      saves = remoteSaves ?? saves;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({'enabled': enabled, 'returns': returns, 'saves': saves}),
      );
      await _refresh();
      busy = false;
      _notify();
    });
    await _queue;
  }

  void refresh() => _enqueue(_refresh);
  Future<void> _refresh() async {
    await service.initialize();
    final allowed = enabled && await service.permission();
    if (!allowed) {
      await _unregister();
      await service.cancelAll();
      _scheduled.clear();
      status = enabled
          ? 'Notifications are blocked in device settings.'
          : 'Notifications are off on this device.';
      _notify();
      return;
    }
    var cloud = false;
    if (_user != null && _pro && client != null) {
      final token = await service.token();
      if (service.usesPolling || token != null) {
        // Clear local schedules before enabling any server-owned reminders.
        final id = await NotificationIdentity.installationId();
        final signature = '$_user/$id/$token/$returns/$saves';
        if (_registrationSignature != signature) {
          await service.cancelAll();
          _scheduled.clear();
          await client!.rpc(
            'register_notification_installation',
            params: {
              'installation_id': id,
              'device_platform': service.platform,
              'delivery_transport': service.transport,
              'device_token': token,
              'notifications_enabled': true,
              'returns_enabled': returns,
              'saves_enabled': saves,
            },
          );
          _registeredId = id;
          _registeredUser = _user;
          _registrationSignature = signature;
        }
        cloud = true;
      }
    } else {
      await _unregister();
    }
    service.cloudActive = cloud;
    final prefs = await SharedPreferences.getInstance();
    final handedOff = prefs.getStringList('notification_handed_off') ?? [];
    final now = DateTime.now();
    final candidates =
        _items
            .where(
              (item) =>
                  returns &&
                  item.deletedAt == null &&
                  (item.status == 'inbox' || item.status == 'deferred') &&
                  item.returnAt != null &&
                  item.returnAt!.isAfter(now) &&
                  !(cloud &&
                      (item.lastSyncedAt != null ||
                          handedOff.contains(item.id))),
            )
            .toList()
          ..sort((a, b) => a.returnAt!.compareTo(b.returnAt!));
    // iOS has a finite OS queue. Refill the earliest 60 when the app runs.
    final wanted = {for (final item in candidates.take(60)) item.id: item};
    for (final id in _scheduled.keys.toList()) {
      if (!wanted.containsKey(id)) {
        await service.cancel(id);
        _scheduled.remove(id);
      }
    }
    for (final item in wanted.values) {
      final revision = item.returnAt!.toUtc().toIso8601String();
      if (_scheduled[item.id] == revision) continue;
      await service.schedule(
        item.id,
        item.returnAt!,
        jsonEncode({'item_id': item.id, 'user_id': _user}),
      );
      _scheduled[item.id] = revision;
    }
    if (cloud && service.usesPolling) {
      final events = await client!.rpc(
        'claim_notification_deliveries',
        params: {'p_installation': _registeredId},
      );
      for (final event in events as List) {
        final data = Map<String, dynamic>.from(event as Map);
        await _present(data);
        await client!.rpc(
          'ack_notification_delivery',
          params: {
            'p_event': data['event_id'],
            'p_installation': _registeredId,
            'p_lease': data['lease_id'],
          },
        );
      }
    }
    status = cloud
        ? (service.usesPolling
              ? 'Active while LaterBox is running or in the tray.'
              : 'Cloud delivery and local-only reminders are enabled.')
        : (_pro
              ? 'Local reminders enabled. Cloud push needs provider setup.'
              : 'Local reminders enabled on this device.');
    _notify();
  }

  Future<void> _present(Map<String, dynamic> data) async {
    if (data['user_id'] != _user) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'notification_seen_${_user ?? "guest"}';
    final seen = prefs.getStringList(key) ?? [];
    final event = data['event_id'] as String;
    if (seen.contains(event)) return;
    await service.show(
      event,
      jsonEncode(data),
      returned: data['kind'] == 'return',
    );
    await prefs.setStringList(key, [
      ...seen.skip(seen.length > 499 ? seen.length - 499 : 0),
      event,
    ]);
  }

  void _openPayload(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['user_id'] != _user) {
        unawaited(open(null));
        return;
      }
      unawaited(open(data['item_id'] as String?));
    } catch (_) {
      unawaited(open(null));
    }
  }

  Future<void> test() async {
    try {
      if (!await service.permission(request: true)) {
        status = 'Allow notifications in device settings.';
        _notify();
        return;
      }
      await service.show('test', jsonEncode({'user_id': _user}), test: true);
    } catch (_) {
      status = 'The test notification could not be shown.';
      _notify();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _itemsSubscription?.cancel();
    _changes?.cancel();
    _taps?.cancel();
    _messages?.cancel();
    super.dispose();
  }
}
