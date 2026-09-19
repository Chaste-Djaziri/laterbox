import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/theme/app_theme.dart';
import 'package:laterbox/features/home/presentation/home_dashboard.dart';
import 'package:laterbox/features/home/presentation/home_shell.dart';
import 'package:laterbox/features/library/presentation/library_providers.dart';
import 'package:laterbox/features/capture/presentation/capture_sheet.dart';
import 'package:laterbox/features/scheduling/presentation/schedule_providers.dart';
import 'package:laterbox/shared/models/laterbox_item.dart';
import 'package:laterbox/shared/models/item_status.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'dashboard fits ${width.toInt()}px in ${dark ? 'dark' : 'light'} theme',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = AppDatabase(NativeDatabase.memory());
          final now = DateTime(2026, 9, 16, 10);
          final items = [
            LaterBoxItem(
              id: 'due',
              title: 'Finish portfolio',
              type: 'task',
              text: 'Finish portfolio',
              status: ItemStatus.deferred,
              createdAt: now,
              returnAt: now.toUtc(),
            ),
            LaterBoxItem(
              id: 'future',
              title: 'Read design trends',
              type: 'link',
              url: 'https://example.com',
              status: ItemStatus.deferred,
              createdAt: now,
              returnAt: now.add(const Duration(days: 1)).toUtc(),
            ),
            LaterBoxItem(
              id: 'someday',
              title: 'An idea for later',
              type: 'note',
              text: 'An idea for later',
              status: ItemStatus.deferred,
              createdAt: now,
            ),
          ];
          final boundary = GlobalKey();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                guestModeProvider.overrideWith((ref) => true),
                appDatabaseProvider.overrideWithValue(db),
                allItemsProvider.overrideWith((ref) => Stream.value(items)),
                scheduleNowProvider.overrideWithValue(() => now),
              ],
              child: MaterialApp(
                theme: dark
                    ? ThemeData.dark(useMaterial3: true)
                    : AppTheme.light,
                home: RepaintBoundary(
                  key: boundary,
                  child: const HomeShell(
                    selectedIndex: 0,
                    child: HomeDashboard(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Good morning.'), findsOneWidget);
          expect(find.text('Ready for you'), findsOneWidget);
          expect(find.text('Finish portfolio'), findsOneWidget);
          if (width >= 900) {
            expect(find.byType(AppBar), findsNothing);
          } else {
            expect(find.text('Home'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          const screenshots = String.fromEnvironment('QA_SCREENSHOTS');
          if (screenshots.isNotEmpty) {
            final image = await tester.runAsync(
              () =>
                  (boundary.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage(),
            );
            final png = await tester.runAsync(
              () => image!.toByteData(format: ui.ImageByteFormat.png),
            );
            await tester.runAsync(
              () => File(
                '$screenshots/dashboard-${width.toInt()}-${dark ? 'dark' : 'light'}.png',
              ).writeAsBytes(png!.buffer.asUint8List()),
            );
            image!.dispose();
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 1));
          await tester.runAsync(db.close);
        },
      );
    }
  }
  testWidgets('capture fits a small phone with its keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            viewInsets: EdgeInsets.only(bottom: 280),
          ),
          child: const Scaffold(body: CaptureSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
