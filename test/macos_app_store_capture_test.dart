import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/theme/app_theme.dart';
import 'package:laterbox/features/capture/presentation/capture_sheet.dart';
import 'package:laterbox/features/detail/presentation/item_detail_screen.dart';
import 'package:laterbox/features/inbox/presentation/inbox_screen.dart';

const _generateAppStoreMedia = bool.fromEnvironment('GENERATE_APP_STORE_MEDIA');

void main() {
  setUpAll(() async {
    await _loadFont(
      'AppStoreCaptureFont',
      '/System/Library/Fonts/Supplemental/Arial.ttf',
    );
    await _loadFont(
      'MaterialIcons',
      '/Users/chastedjazirihabimanahirwa/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
  });

  testWidgets('renders the macOS App Store inbox screenshot', (tester) async {
    await _pumpScene(tester, const InboxScreen());

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../assets/app_store/macos/01_inbox.png'),
    );
    await _disposeScene(tester);
  }, skip: !_generateAppStoreMedia);

  testWidgets('renders the macOS App Store quick capture screenshot', (
    tester,
  ) async {
    await _pumpScene(
      tester,
      Scaffold(
        body: Stack(
          children: [
            const IgnorePointer(child: InboxScreen()),
            ColoredBox(color: Colors.black.withValues(alpha: 0.44)),
            const CaptureSheet(
              initialText:
                  'https://www.nngroup.com/articles/information-overload/',
            ),
          ],
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../assets/app_store/macos/02_quick_capture.png'),
    );
    await _disposeScene(tester);
  }, skip: !_generateAppStoreMedia);

  testWidgets('renders the macOS App Store reader screenshot', (tester) async {
    await _pumpScene(tester, const ItemDetailScreen(itemId: 'spatial-design'));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../assets/app_store/macos/03_reader.png'),
    );
    await _disposeScene(tester);
  }, skip: !_generateAppStoreMedia);
}

Future<void> _loadFont(String family, String path) async {
  final fontData = await File(path).readAsBytes();
  final fontLoader = FontLoader(family)
    ..addFont(Future.value(fontData.buffer.asByteData()));
  await fontLoader.load();
}

Future<void> _pumpScene(WidgetTester tester, Widget scene) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  await _seedDatabase(database);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        guestModeProvider.overrideWith((ref) => true),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LaterBox',
        theme: _captureTheme,
        home: scene,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 350));
}

final ThemeData _captureTheme = AppTheme.light.copyWith(
  textTheme: AppTheme.light.textTheme.apply(fontFamily: 'AppStoreCaptureFont'),
  primaryTextTheme: AppTheme.light.primaryTextTheme.apply(
    fontFamily: 'AppStoreCaptureFont',
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppTheme.ink,
      foregroundColor: AppTheme.surface,
      minimumSize: const Size(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
        fontFamily: 'AppStoreCaptureFont',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
);

Future<void> _disposeScene(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

Future<void> _seedDatabase(AppDatabase database) async {
  final now = DateTime.utc(2026, 8, 25, 9, 30);
  final entries = [
    (
      id: 'spatial-design',
      url: 'https://www.nngroup.com/articles/information-overload/',
      title: 'A calmer way to manage information overload',
      description: 'Practical ideas for reducing digital clutter, protecting attention, and returning to what matters.',
      domain: 'nngroup.com',
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
