import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/features/landing/presentation/landing_screen.dart';

void main() {
  testWidgets('renders LandingScreen with hero, features, and CTAs',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LandingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LaterBox'), findsWidgets);
    expect(
      find.text('Save anything now.\nRead, watch & organize later.'),
      findsOneWidget,
    );
    expect(find.text('Get Started Free'), findsOneWidget);
    expect(find.text('Try Guest Mode'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Everything you need to capture & remember'), findsOneWidget);
    expect(find.text('How LaterBox Works'), findsOneWidget);
    expect(find.text('About LaterBox'), findsOneWidget);
  });
}
