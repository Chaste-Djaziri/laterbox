import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/features/tutorial/presentation/tutorial_screen.dart';

void main() {
  testWidgets('renders TutorialScreen with steps and navigation buttons',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TutorialScreen(),
      ),
    );

    expect(find.byType(TutorialScreen), findsOneWidget);
    expect(find.text('laterbox Guide'), findsOneWidget);
    expect(find.text('Quick Capture Anywhere'), findsOneWidget);

    // Tap Next Feature button
    final nextButton = find.text('Next Feature');
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.text('Smart Metadata & Previews'), findsOneWidget);
  });
}
