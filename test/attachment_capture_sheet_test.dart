import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/features/attachments/data/attachment_file_picker.dart';
import 'package:laterbox/features/attachments/presentation/attachment_providers.dart';
import 'package:laterbox/features/capture/presentation/capture_sheet.dart';

void main() {
  testWidgets('picks files directly on desktop without showing source modal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attachmentFilePickerProvider.overrideWithValue(
            const _FakePicker([
              PickedAttachmentFile(
                name: 'proposal.pdf',
                size: 12,
                path: '/tmp/proposal.pdf',
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.macOS),
          home: const Scaffold(body: CaptureSheet()),
        ),
      ),
    );

    await tester.tap(find.text('Choose files'));
    await tester.pumpAndSettle();

    expect(find.text('Choose attachment source'), findsNothing);
    expect(find.text('proposal.pdf'), findsOneWidget);
  });

  testWidgets('shows source picker modal on mobile platform', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attachmentFilePickerProvider.overrideWithValue(
            const _FakePicker([
              PickedAttachmentFile(
                name: 'screenshot.png',
                size: 24,
                path: '/tmp/screenshot.png',
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Scaffold(body: CaptureSheet()),
        ),
      ),
    );

    await tester.tap(find.text('Choose files'));
    await tester.pumpAndSettle();

    expect(find.text('Choose attachment source'), findsOneWidget);
    await tester.tap(find.text('Files'));
    await tester.pumpAndSettle();

    expect(find.text('screenshot.png'), findsOneWidget);
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
