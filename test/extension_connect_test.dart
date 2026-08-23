import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/core/auth/auth_state.dart';
import 'package:laterbox/features/extension/presentation/extension_connect_screen.dart';

void main() {
  testWidgets('ExtensionConnectScreen enables connect button for valid https://laterbox.dev redirect URI',
      (tester) async {
    const requestId = '72eda98ce57a438aa4f92f99a0c6fb0b';
    const requestSecret = 'SBRCb4ElXO7LGplEzOSn2_PZXkCSzLIJaGBrmWOScns';
    const redirectUri = 'https://laterbox.dev/extension/connected';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const LaterBoxAuthState(
                userId: 'user_123',
                email: 'chastedjaziri@gmail.com',
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ExtensionConnectScreen(
            requestId: requestId,
            requestSecret: requestSecret,
            redirectUri: redirectUri,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Connect browser extension'), findsOneWidget);
    expect(find.text('Connect this browser extension to chastedjaziri@gmail.com.'), findsOneWidget);
    expect(find.text('This connection request is invalid or expired.'), findsNothing);

    final connectButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Connect'),
    );
    expect(connectButton.onPressed, isNotNull);
  });
}
