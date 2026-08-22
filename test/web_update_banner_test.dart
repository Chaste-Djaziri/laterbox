import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:laterbox/core/web/web_update_banner.dart';
import 'package:laterbox/core/web/web_update_service.dart';

void main() {
  group('WebUpdateNotifier', () {
    test('detects change in version payload', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('{"build":"100"}', 200);
        } else {
          return http.Response('{"build":"101"}', 200);
        }
      });

      final notifier = WebUpdateNotifier(
        client: mockClient,
        enabled: true,
        autoStart: false,
      );

      // Initial check (baseline)
      await notifier.checkForUpdate(isInitial: true);
      expect(notifier.state.hasUpdate, isFalse);

      // Next check with new payload
      await notifier.checkForUpdate();
      expect(notifier.state.hasUpdate, isTrue);
      expect(notifier.state.shouldShowBanner, isTrue);

      // Dismiss
      notifier.dismiss();
      expect(notifier.state.hasUpdate, isTrue);
      expect(notifier.state.isDismissed, isTrue);
      expect(notifier.state.shouldShowBanner, isFalse);
    });
  });

  group('WebUpdateBannerOverlay Widget', () {
    testWidgets('renders banner when update is available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            webUpdateProvider.overrideWith(
              (ref) => _FakeWebUpdateNotifier(
                const WebUpdateState(hasUpdate: true, isDismissed: false),
              ),
            ),
          ],
          child: const MaterialApp(
            home: WebUpdateBannerOverlay(
              enabled: true,
              child: Scaffold(body: Text('Main Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('Reload & update'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });

    testWidgets('hides banner when dismissed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            webUpdateProvider.overrideWith(
              (ref) => _FakeWebUpdateNotifier(
                const WebUpdateState(hasUpdate: true, isDismissed: true),
              ),
            ),
          ],
          child: const MaterialApp(
            home: WebUpdateBannerOverlay(
              enabled: true,
              child: Scaffold(body: Text('Main Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.text('Update available'), findsNothing);
    });
  });
}

class _FakeWebUpdateNotifier extends WebUpdateNotifier {
  _FakeWebUpdateNotifier(WebUpdateState initialState)
      : super(enabled: false, autoStart: false) {
    state = initialState;
  }
}
