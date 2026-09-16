import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/features/capture/presentation/ios_clipboard_capture_overlay.dart';
import 'package:laterbox/features/capture/presentation/ios_notch_companion_controller.dart';

void main() {
  group('IosNotchCompanionController', () {
    test('initial state is IosNotchIdle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(iosNotchCompanionProvider);
      expect(state, isA<IosNotchIdle>());
    });

    test('showClipboardPrompt transitions to IosNotchClipboardPrompt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(iosNotchCompanionProvider.notifier);
      notifier.showClipboardPrompt('https://laterbox.dev');

      final state = container.read(iosNotchCompanionProvider);
      expect(state, isA<IosNotchClipboardPrompt>());
      final prompting = state as IosNotchClipboardPrompt;
      expect(prompting.value, 'https://laterbox.dev');
    });

    test('updatePromptReturnAt updates selectedReturnAt and isCustom flag', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(iosNotchCompanionProvider.notifier);
      notifier.showClipboardPrompt('test note');

      final futureDate = DateTime(2026, 9, 20, 14, 0);
      notifier.updatePromptReturnAt(futureDate, isCustom: true);

      final state =
          container.read(iosNotchCompanionProvider) as IosNotchClipboardPrompt;
      expect(state.selectedReturnAt, futureDate);
      expect(state.isCustom, isTrue);

      notifier.updatePromptReturnAt(null);
      final stateInbox =
          container.read(iosNotchCompanionProvider) as IosNotchClipboardPrompt;
      expect(stateInbox.selectedReturnAt, isNull);
      expect(stateInbox.isCustom, isFalse);
    });

    test('showSavedConfirmation transitions to IosNotchSavedConfirmation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(iosNotchCompanionProvider.notifier);
      final returnTime = DateTime(2026, 9, 21, 9, 0);
      notifier.showSavedConfirmation(
        title: 'Apple Keynote',
        subtitle: 'https://apple.com',
        returnAt: returnTime,
      );

      final state = container.read(iosNotchCompanionProvider);
      expect(state, isA<IosNotchSavedConfirmation>());
      final saved = state as IosNotchSavedConfirmation;
      expect(saved.title, 'Apple Keynote');
      expect(saved.subtitle, 'https://apple.com');
      expect(saved.returnAt, returnTime);
    });

    test(
      'showError transitions to IosNotchError and dismiss resets to idle',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(iosNotchCompanionProvider.notifier);
        notifier.showError('App Group container failed');

        final state = container.read(iosNotchCompanionProvider);
        expect(state, isA<IosNotchError>());
        expect((state as IosNotchError).message, 'App Group container failed');

        notifier.dismiss();
        expect(container.read(iosNotchCompanionProvider), isA<IosNotchIdle>());
      },
    );
  });

  group('IosClipboardCaptureOverlay UI rendering', () {
    testWidgets('renders clipboard prompt with when chips and allows selection', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: IosClipboardCaptureOverlay(
                  child: Center(child: Text('Main Content')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Main Content'), findsOneWidget);
        expect(find.text('Save copied item?'), findsNothing);

        // Trigger prompt
        container.read(iosNotchCompanionProvider.notifier).showClipboardPrompt(
              'https://flutter.dev',
            );
        await tester.pumpAndSettle();

        expect(find.text('Save copied item?'), findsOneWidget);
        expect(find.text('flutter.dev'), findsOneWidget);
        expect(find.text('Inbox'), findsOneWidget);
        expect(find.text('Tomorrow'), findsOneWidget);
        expect(find.text('Custom…'), findsOneWidget);
        expect(find.text('Save to LaterBox'), findsOneWidget);
        expect(find.text('Not now'), findsOneWidget);

        // Tap 'Inbox' chip to set returnAt to null
        await tester.tap(find.text('Inbox'));
        await tester.pumpAndSettle();

        final state =
            container.read(iosNotchCompanionProvider) as IosNotchClipboardPrompt;
        expect(state.selectedReturnAt, isNull);

        // Tap 'Not now' to dismiss
        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();
        expect(find.text('Save copied item?'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('renders saved confirmation card', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: IosClipboardCaptureOverlay(
                  child: Center(child: Text('Main Content')),
                ),
              ),
            ),
          ),
        );

        container.read(iosNotchCompanionProvider.notifier).showSavedConfirmation(
              title: 'Saved to LaterBox',
              subtitle: 'https://github.com/flutter/flutter',
              returnAt: DateTime.now().add(const Duration(days: 1)),
            );
        await tester.pumpAndSettle();

        expect(find.text('Saved to LaterBox'), findsOneWidget);
        expect(find.text('https://github.com/flutter/flutter'), findsOneWidget);
        expect(find.textContaining('Tomorrow'), findsOneWidget);

        // Auto-dismisses after timeout
        await tester.pump(const Duration(seconds: 3));
        expect(find.text('Saved to LaterBox'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'renders custom scheduled return time in saved confirmation and prompt',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final container = ProviderContainer();
        addTearDown(container.dispose);

        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: Scaffold(
                  body: IosClipboardCaptureOverlay(
                    child: Center(child: Text('Main Content')),
                  ),
                ),
              ),
            ),
          );

          // Prompt with custom time
          container
              .read(iosNotchCompanionProvider.notifier)
              .showClipboardPrompt(
                'https://laterbox.dev/docs',
              );
          final customDate = DateTime(2026, 10, 15, 14, 30);
          container
              .read(iosNotchCompanionProvider.notifier)
              .updatePromptReturnAt(customDate, isCustom: true);
          await tester.pumpAndSettle();

          expect(find.textContaining('Oct 15 · 2:30 PM'), findsOneWidget);

          // Confirmation with custom time
          container
              .read(iosNotchCompanionProvider.notifier)
              .showSavedConfirmation(
                title: 'Saved to LaterBox',
                subtitle: 'Documentation',
                returnAt: customDate,
              );
          await tester.pumpAndSettle();

          expect(find.text('Saved to LaterBox'), findsOneWidget);
          expect(find.text('Documentation'), findsOneWidget);
          expect(find.textContaining('Oct 15 · 2:30 PM'), findsOneWidget);

          // Let auto-dismiss timer complete
          await tester.pump(const Duration(seconds: 3));
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('renders error card with dismiss button', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: IosClipboardCaptureOverlay(
                  child: Center(child: Text('Main Content')),
                ),
              ),
            ),
          ),
        );

        container.read(iosNotchCompanionProvider.notifier).showError(
              'Failed to read shared file.',
            );
        await tester.pumpAndSettle();

        expect(find.text("Couldn't save item"), findsOneWidget);
        expect(find.text('Failed to read shared file.'), findsOneWidget);

        // Tap close button
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.text("Couldn't save item"), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
