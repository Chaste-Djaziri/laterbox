import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Platform presentation only. Business rules live in NotificationCoordinator.
class InboxNotificationService {
  static final instance = InboxNotificationService();
  final plugin = FlutterLocalNotificationsPlugin();
  static const _apple = MethodChannel('laterbox/notifications');
  final taps = StreamController<String>.broadcast();
  final changes = StreamController<void>.broadcast();
  final messages = StreamController<Map<String, dynamic>>.broadcast();
  Future<void>? _initializing;
  String? launchPayload;
  bool _firebaseReady = false;
  bool cloudActive = false;
  final Map<int, Timer> _timers = {};
  bool get usesPolling => Platform.isLinux || Platform.isWindows;
  String get platform => Platform.operatingSystem;
  String get transport => usesPolling
      ? 'poll'
      : Platform.isAndroid
      ? 'fcm'
      : 'apns';

  static int idFor(String key) {
    final bytes = sha256.convert(utf8.encode(key)).bytes;
    return ((bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3]) &
        0x7fffffff;
  }

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    tzdata.initializeTimeZones();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        linux: LinuxInitializationSettings(defaultActionName: 'Open inbox'),
        windows: WindowsInitializationSettings(
          appName: 'LaterBox',
          appUserModelId: 'MiCorp.LaterBox',
          guid: 'e3bf716a-9671-4c32-9024-c0720215b036',
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) taps.add(response.payload!);
      },
    );
    launchPayload = (await plugin.getNotificationAppLaunchDetails())
        ?.notificationResponse
        ?.payload;
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'laterbox_inbox',
            'Inbox arrivals',
            description: 'Scheduled returns and saves from other devices',
            importance: Importance.high,
          ),
        );
    if (Platform.isIOS || Platform.isMacOS) {
      _apple.setMethodCallHandler((call) async {
        if (call.method == 'tokenChanged') changes.add(null);
        if (call.method == 'notificationTap' && call.arguments is String)
          taps.add(call.arguments as String);
      });
      final pending = await _apple.invokeMethod<String>('initialize');
      launchPayload ??= pending;
    }
    if (Platform.isAndroid &&
        const String.fromEnvironment('FIREBASE_APP_ID').isNotEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
        ),
      );
      _firebaseReady = true;
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (_) => changes.add(null),
      );
      FirebaseMessaging.onMessage.listen(
        (message) => messages.add(message.data),
      );
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => taps.add(jsonEncode(message.data)),
      );
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) launchPayload = jsonEncode(initial.data);
    }
  }

  Future<bool> permission({bool request = false}) async {
    await initialize();
    if (Platform.isAndroid) {
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!;
      return (request
              ? await android.requestNotificationsPermission()
              : await android.areNotificationsEnabled()) ??
          false;
    }
    if (Platform.isIOS) {
      final ios = plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()!;
      return request
          ? await ios.requestPermissions(
                  alert: true,
                  sound: true,
                  badge: false,
                ) ??
                false
          : (await ios.checkPermissions())?.isEnabled ?? false;
    }
    if (Platform.isMacOS) {
      final mac = plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()!;
      return request
          ? await mac.requestPermissions(
                  alert: true,
                  sound: true,
                  badge: false,
                ) ??
                false
          : (await mac.checkPermissions())?.isEnabled ?? false;
    }
    return true; // Desktop notification daemon/user settings own permission.
  }

  Future<String?> token() async {
    await initialize();
    if (usesPolling) return null;
    if (Platform.isAndroid)
      return _firebaseReady ? FirebaseMessaging.instance.getToken() : null;
    return _apple.invokeMethod<String>('register');
  }

  static const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'laterbox_inbox',
      'Inbox arrivals',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    linux: LinuxNotificationDetails(),
    windows: WindowsNotificationDetails(),
  );
  Future<void> show(
    String key,
    String payload, {
    bool test = false,
    bool returned = true,
  }) async {
    await initialize();
    await plugin.show(
      id: idFor(key),
      title: 'LaterBox',
      body: test
          ? 'Notifications are ready on this device.'
          : returned
          ? 'An item is ready in your inbox.'
          : 'An item was added to your inbox.',
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> schedule(String itemId, DateTime due, String payload) async {
    await initialize();
    final id = idFor(itemId);
    if (usesPolling) {
      _timers.remove(id)?.cancel();
      _timers[id] = Timer(
        due.difference(DateTime.now()),
        () => unawaited(show(itemId, payload)),
      );
    } else {
      await plugin.zonedSchedule(
        id: id,
        title: 'LaterBox',
        body: 'An item is ready in your inbox.',
        scheduledDate: tz.TZDateTime.from(due, tz.UTC),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  Future<void> cancel(String itemId) async {
    _timers.remove(idFor(itemId))?.cancel();
    await plugin.cancel(id: idFor(itemId));
  }

  Future<void> cancelAll() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    await plugin.cancelAll();
  }

  /// Called before a local capture is uploaded. This closes the local/push race.
  Future<void> prepareUpload(String itemId) async {
    if (!cloudActive) return;
    await cancel(itemId);
    final prefs = await SharedPreferences.getInstance();
    final handedOff = prefs.getStringList('notification_handed_off') ?? [];
    if (!handedOff.contains(itemId))
      await prefs.setStringList('notification_handed_off', [
        ...handedOff,
        itemId,
      ]);
  }
}
