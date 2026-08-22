import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/features/download/presentation/download_screen.dart';

void main() {
  testWidgets('renders DownloadScreen with Windows spotlight, roadmap, and web alternatives',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DownloadScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('laterbox'), findsWidgets);
    expect(find.text('Get laterbox for your device'), findsOneWidget);
    expect(find.text('Laterbox for Windows'), findsOneWidget);
    expect(find.text('AVAILABLE NOW'), findsOneWidget);
    expect(find.text('Download Installer (.exe) • 12 MB'), findsOneWidget);
    expect(find.text('Download Portable (.zip) • 14 MB'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('More platforms coming soon'), findsOneWidget);
    expect(find.text('macOS'), findsOneWidget);
    expect(find.text('Linux'), findsOneWidget);
    expect(find.text('iOS'), findsOneWidget);
    expect(find.text('Android'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('Available right now on Web & Extensions'), findsOneWidget);
    expect(find.text('How to install Laterbox on Windows'), findsOneWidget);
    expect(find.text('Frequently Asked Questions'), findsOneWidget);
  });
}
