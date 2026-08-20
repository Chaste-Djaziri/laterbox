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
            const _FakePicker(['/tmp/proposal.pdf', '/tmp/screenshot.png']),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CaptureSheet())),
      ),
    );

    await tester.tap(find.text('Choose files'));
    await tester.pump();

    expect(find.text('proposal.pdf'), findsOneWidget);
    expect(find.text('screenshot.png'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove proposal.pdf'));
    await tester.pump();

    expect(find.text('proposal.pdf'), findsNothing);
    expect(find.text('screenshot.png'), findsOneWidget);
  });
}

class _FakePicker implements AttachmentFilePicker {
  const _FakePicker(this.paths);

  final List<String> paths;

  @override
  Future<List<String>> pickFiles() async => paths;
}
