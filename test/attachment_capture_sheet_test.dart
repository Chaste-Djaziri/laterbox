import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/features/attachments/data/attachment_file_picker.dart';
import 'package:laterbox/features/attachments/presentation/attachment_providers.dart';
import 'package:laterbox/features/capture/presentation/capture_sheet.dart';

void main() {
  testWidgets('adds and removes several picked files in the capture sheet', (
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
              PickedAttachmentFile(
                name: 'screenshot.png',
                size: 24,
                path: '/tmp/screenshot.png',
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CaptureSheet())),
      ),
    );

    await tester.tap(find.text('Choose files'));
    await tester.pumpAndSettle();

    expect(find.text('Choose attachment source'), findsOneWidget);
    await tester.tap(find.text('Files'));
    await tester.pumpAndSettle();

    expect(find.text('proposal.pdf'), findsOneWidget);
    expect(find.text('screenshot.png'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove proposal.pdf'));
    await tester.pump();

    expect(find.text('proposal.pdf'), findsNothing);
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
