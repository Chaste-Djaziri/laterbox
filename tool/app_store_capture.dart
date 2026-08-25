import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/theme/app_theme.dart';
import 'package:laterbox/features/capture/presentation/capture_sheet.dart';
import 'package:laterbox/features/detail/presentation/item_detail_screen.dart';
import 'package:laterbox/features/inbox/presentation/inbox_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  final database = AppDatabase(NativeDatabase.memory());
  await _seedDatabase(database);
  runApp(_CaptureApp(database: database));
}

class _CaptureApp extends StatelessWidget {
  const _CaptureApp({required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        guestModeProvider.overrideWith((ref) => true),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LaterBox App Store Capture',
        theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
        home: const _CaptureSequence(),
      ),
    );
  }
}

class _CaptureSequence extends StatefulWidget {
  const _CaptureSequence();

  @override
  State<_CaptureSequence> createState() => _CaptureSequenceState();
}

class _CaptureSequenceState extends State<_CaptureSequence> {
  Timer? _timer;
  int _screen = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('APP_STORE_CAPTURE_READY:inbox');
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _screen = (_screen + 1) % 3);
      debugPrint(
        'APP_STORE_CAPTURE_READY:${switch (_screen) {
          0 => 'inbox',
          1 => 'capture',
          _ => 'reader',
        }}',
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_screen) {
      0 => const InboxScreen(),
      1 => const Scaffold(body: SafeArea(child: CaptureSheet())),
      _ => const ItemDetailScreen(itemId: 'spatial-design'),
    };
  }
}

Future<void> _seedDatabase(AppDatabase database) async {
  final now = DateTime.utc(2026, 8, 25, 9, 30);
  final entries = [
    (
      id: 'spatial-design',
      url: 'https://developer.apple.com/design/human-interface-guidelines/',
      title: 'Designing focused experiences for every Apple device',
      description: 'A practical guide to hierarchy, clarity, accessibility, and thoughtful interactions across Apple platforms.',
      domain: 'developer.apple.com',
      type: 'article',
      favorite: true,
    ),
    (
      id: 'flutter-performance',
      url: 'https://docs.flutter.dev/perf/best-practices',
      title: 'Flutter performance best practices worth remembering',
      description: 'Build smooth interfaces with efficient rendering, smaller rebuilds, and responsive layouts.',
      domain: 'docs.flutter.dev',
      type: 'article',
      favorite: false,
    ),
    (
      id: 'product-video',
      url: 'https://www.youtube.com/watch?v=aqz-KE-bpKQ',
      title: 'A beautiful product story told in five minutes',
      description: 'Saved to revisit the pacing, visual hierarchy, and narrative structure.',
      domain: 'youtube.com',
      type: 'video',
      favorite: false,
    ),
    (
      id: 'reading-note',
      url: null,
      title: 'Ideas for a calmer reading workflow',
      description: 'Keep the inbox intentional. Archive after reading and collect only what deserves a second look.',
      domain: 'LaterBox note',
      type: 'note',
      favorite: true,
    ),
  ];

  for (var index = 0; index < entries.length; index++) {
    final entry = entries[index];
    final timestamp = now.subtract(Duration(minutes: index * 18));
    await database.saveItem(
      ItemsCompanion.insert(
        id: entry.id,
        url: Value(entry.url),
        title: Value(entry.title),
        textContent: entry.url == null
            ? Value(entry.description)
            : const Value.absent(),
        type: Value(entry.type),
        favorite: Value(entry.favorite),
        syncStatus: const Value('synced'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    if (entry.url != null) {
      await database.upsertMetadata(
        ItemMetadataCompanion.insert(
          itemId: entry.id,
          domain: Value(entry.domain),
          siteName: Value(entry.domain),
          title: Value(entry.title),
          description: Value(entry.description),
          status: const Value('enriched'),
          contentType: Value(entry.type),
          classificationSource: const Value('demo'),
          classificationConfidence: const Value(0.98),
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }
  }
}
