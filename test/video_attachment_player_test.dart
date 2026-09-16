import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/attachments/presentation/video_attachment_player.dart';

void main() {
  final now = DateTime.utc(2026, 9, 17, 0, 0, 0);

  final video1 = Attachment(
    id: 'vid-1',
    itemId: 'item-1',
    originalFileName: 'product_walkthrough.mp4',
    mimeType: 'video/mp4',
    byteSize: 15 * 1024 * 1024,
    fileExtension: 'mp4',
    sha256: 'a' * 64,
    createdAt: now,
    updatedAt: now,
  );

  final video2 = Attachment(
    id: 'vid-2',
    itemId: 'item-1',
    originalFileName: 'design_review.mov',
    mimeType: 'video/quicktime',
    byteSize: 32 * 1024 * 1024,
    fileExtension: 'mov',
    sha256: 'b' * 64,
    createdAt: now,
    updatedAt: now,
  );

  final imageDoc = Attachment(
    id: 'img-1',
    itemId: 'item-1',
    originalFileName: 'screenshot.png',
    mimeType: 'image/png',
    byteSize: 500 * 1024,
    fileExtension: 'png',
    sha256: 'c' * 64,
    createdAt: now,
    updatedAt: now,
  );

  group('isVideoAttachment', () {
    test('identifies video files and mime types correctly', () {
      expect(isVideoAttachment(video1), isTrue);
      expect(isVideoAttachment(video2), isTrue);
      expect(isVideoAttachment(imageDoc), isFalse);
    });
  });

  group('VideoAttachmentPlayer single video', () {
    testWidgets('renders custom play button, progress scrubber, and timestamp', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoAttachmentPlayer(
              videoAttachments: [video1],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify file name display
      expect(find.text('product_walkthrough.mp4'), findsAtLeastNWidgets(1));

      // Verify custom center play button
      expect(find.byKey(const ValueKey('videoPlayerCenterPlayButton')), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsAtLeastNWidgets(1));

      // Verify bottom controls and play/pause icon toggle
      expect(find.byKey(const ValueKey('videoPlayerPlayPauseToggle')), findsOneWidget);
      expect(find.byKey(const ValueKey('videoPlayerMuteToggle')), findsOneWidget);

      // Verify single video does NOT show queue button or skip buttons
      expect(find.byKey(const ValueKey('videoPlayerQueueButton')), findsNothing);
      expect(find.byKey(const ValueKey('videoPlayerSkipPrevious')), findsNothing);
      expect(find.byKey(const ValueKey('videoPlayerSkipNext')), findsNothing);

      // Tap center play button to toggle playback
      await tester.tap(find.byKey(const ValueKey('videoPlayerCenterPlayButton')));
      await tester.pump();

      // Center button now reflects pause icon
      expect(find.byIcon(Icons.pause_rounded), findsAtLeastNWidgets(1));
    });
  });

  group('VideoAttachmentPlayer queue mode', () {
    testWidgets(
      'renders queue indicator, skip buttons, and toggles queue drawer to select video',
      (tester) async {
        int? reportedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoAttachmentPlayer(
                videoAttachments: [video1, video2],
                onIndexChanged: (idx) => reportedIndex = idx,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify queue count indicator and queue button
        expect(find.text('1 of 2'), findsOneWidget);
        expect(find.byKey(const ValueKey('videoPlayerQueueButton')), findsOneWidget);
        expect(find.text('Queue (2)'), findsOneWidget);

        // Verify skip buttons
        expect(find.byKey(const ValueKey('videoPlayerSkipPrevious')), findsOneWidget);
        expect(find.byKey(const ValueKey('videoPlayerSkipNext')), findsOneWidget);

        // Open queue drawer
        await tester.tap(find.byKey(const ValueKey('videoPlayerQueueButton')));
        await tester.pumpAndSettle();

        // Queue drawer should be visible with both items
        expect(find.text('Queue Mode'), findsOneWidget);
        expect(find.text('Auto-advance on'), findsOneWidget);
        expect(find.byKey(const ValueKey('videoQueueItem_0')), findsOneWidget);
        expect(find.byKey(const ValueKey('videoQueueItem_1')), findsOneWidget);
        expect(find.text('Now Playing · 15.0 MB'), findsOneWidget);
        expect(find.text('32.0 MB'), findsOneWidget);

        // Tap second video in queue
        await tester.tap(find.byKey(const ValueKey('videoQueueItem_1')));
        await tester.pumpAndSettle();

        // Queue drawer closes and active video updates
        expect(reportedIndex, equals(1));
        expect(find.text('2 of 2'), findsOneWidget);
        expect(find.text('design_review.mov'), findsAtLeastNWidgets(1));

        // Skip previous should go back to video 1
        await tester.tap(find.byKey(const ValueKey('videoPlayerSkipPrevious')));
        await tester.pumpAndSettle();
        expect(reportedIndex, equals(0));
        expect(find.text('1 of 2'), findsOneWidget);
        expect(find.text('product_walkthrough.mp4'), findsAtLeastNWidgets(1));
      },
    );
  });
}
