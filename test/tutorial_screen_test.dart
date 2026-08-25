import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/features/tutorial/presentation/tutorial_screen.dart';

void main() {
  testWidgets('shows the macOS shortcut and advances through the guide', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TutorialScreen(platformOverride: TargetPlatform.macOS),
      ),
    );

    expect(find.text('LaterBox guide'), findsOneWidget);
    expect(find.text('Set up LaterBox on your Mac'), findsOneWidget);
    expect(find.text('⌥ Space'), findsOneWidget);
    expect(find.text('Next step'), findsOneWidget);

    await tester.tap(find.text('Next step'));
    await tester.pumpAndSettle();

    expect(find.text('Add the browser extension'), findsOneWidget);
  });

  testWidgets('shows Windows specific capture instructions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TutorialScreen(platformOverride: TargetPlatform.windows),
      ),
    );

    expect(find.text('Set up LaterBox on Windows'), findsOneWidget);
    expect(find.text('Ctrl + Alt + Space'), findsOneWidget);
    expect(find.text('Capture without changing programs'), findsOneWidget);
  });

  testWidgets('shows iPhone and iPad share sheet instructions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TutorialScreen(platformOverride: TargetPlatform.iOS),
      ),
    );

    expect(find.text('Save from your iPhone or iPad'), findsOneWidget);
    expect(find.text('Share → LaterBox'), findsOneWidget);
    expect(find.text('Save with the Share button'), findsOneWidget);
  });

  testWidgets('uses a two pane step navigator on wide desktop windows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: TutorialScreen(platformOverride: TargetPlatform.linux),
      ),
    );

    expect(find.text('YOUR QUICK START'), findsOneWidget);
    expect(find.text('Set up LaterBox on Linux'), findsOneWidget);
    expect(find.text('Alt + Space'), findsOneWidget);
  });
}
