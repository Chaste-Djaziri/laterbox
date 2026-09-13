import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/app.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/router/app_router.dart';
import 'package:laterbox/features/attachments/data/attachment_file_picker.dart';
import 'package:laterbox/features/attachments/presentation/attachment_providers.dart';
import 'package:laterbox/features/capture/presentation/capture_sheet.dart';

void main() {
  testWidgets('chat-style capture composer saves note and closes with animation', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guestModeProvider.overrideWith((ref) => true),
          appDatabaseProvider.overrideWithValue(database),
          initialLocationProvider.overrideWithValue('/inbox'),
        ],
        child: const LaterBoxApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Open capture sheet via FAB
    await tester.tap(find.byTooltip('Save something'));
    await tester.pumpAndSettle();

    // Verify chat composer elements are present
    expect(find.text('Type your message...'), findsOneWidget);
    expect(find.text('Choose files'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Enter a note in the chat composer
    await tester.enterText(
      find.byType(TextField).last,
      'Remember to check out the new design',
    );
    await tester.pump();

    // Tap Save to trigger the send animation and save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify modal is dismissed and item appears in inbox
    expect(find.text('Type your message...'), findsNothing);
    expect(find.text('Remember to check out the new design'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });

  testWidgets('chat composer attaches file and renders chip with remove action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attachmentFilePickerProvider.overrideWithValue(
            const _FakePicker([
              PickedAttachmentFile(
                name: 'document.pdf',
                size: 2048,
                path: '/tmp/document.pdf',
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.macOS),
          home: const Scaffold(
            body: CaptureSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Choose files
    await tester.tap(find.text('Choose files'));
    await tester.pumpAndSettle();

    // Chip should be visible
    expect(find.text('document.pdf'), findsOneWidget);

    // Remove the file chip
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    expect(find.text('document.pdf'), findsNothing);
  });
}

class _FakePicker implements AttachmentFilePicker {
  const _FakePicker(this.files);

  final List<PickedAttachmentFile> files;

  @override
  Future<List<PickedAttachmentFile>> pickFiles({
    AttachmentPickerSource source = AttachmentPickerSource.files,
  }) async => files;
}
