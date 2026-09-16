import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/features/home/presentation/desktop_sidebar.dart';

void main() {
  testWidgets('DesktopSidebar renders web-style sidebar items, brand, and actions', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    int? tappedIndex;
    bool captureOpened = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guestModeProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DesktopSidebar(
              selectedIndex: 1,
              onDestinationSelected: (index) => tappedIndex = index,
              onOpenCapture: () => captureOpened = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify brand header
    expect(find.text('laterbox'), findsOneWidget);

    // Verify Save Item button
    expect(find.text('Save Item'), findsOneWidget);

    // Verify nav items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Someday'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Guide'), findsOneWidget);
    expect(find.text('Apps'), findsOneWidget);
    expect(find.text('Plans'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify guest mode account card
    expect(find.text('Guest Mode'), findsOneWidget);
    expect(find.text('Sign In / Sync'), findsOneWidget);

    // Tap Save Item
    await tester.tap(find.text('Save Item'));
    await tester.pumpAndSettle();
    expect(captureOpened, isTrue);

    // Tap a destination tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(tappedIndex, equals(5));

    // Collapse sidebar
    final collapseButton = find.byTooltip('Collapse sidebar');
    expect(collapseButton, findsOneWidget);
    await tester.tap(collapseButton);
    await tester.pumpAndSettle();

    // Text labels are hidden when collapsed
    expect(find.text('laterbox'), findsNothing);
    expect(find.text('Save Item'), findsNothing);

    // Expand button is present
    final expandButton = find.byTooltip('Expand sidebar');
    expect(expandButton, findsOneWidget);
    await tester.tap(expandButton);
    await tester.pumpAndSettle();

    // Text labels are visible again
    expect(find.text('laterbox'), findsOneWidget);
    expect(find.text('Save Item'), findsOneWidget);
  });
}
