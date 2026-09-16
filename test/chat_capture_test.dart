import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/app.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/enrichment/enrichment_providers.dart';
import 'package:laterbox/core/router/app_router.dart';
import 'package:laterbox/features/attachments/data/attachment_file_picker.dart';
import 'package:laterbox/features/attachments/presentation/attachment_providers.dart';
import 'package:laterbox/features/capture/presentation/capture_sheet.dart';
import 'package:laterbox/features/enrichment/data/local_metadata_data_source.dart';
import 'package:laterbox/features/enrichment/domain/item_metadata.dart';
import 'package:laterbox/features/enrichment/domain/url_enhancer.dart';

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

    // Verify modal is dismissed and the unscheduled capture waits outside Inbox
    expect(find.text('Type your message...'), findsNothing);
    expect(find.text('Remember to check out the new design'), findsNothing);
    final stored = (await tester.runAsync(() => database.watchAllItemsWithMetadata(null).first))!;
    expect(stored.single.$1.textContent, 'Remember to check out the new design');
    expect(stored.single.$1.returnAt, isNull);

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

  testWidgets(
    'chat composer has borderless input, green send button, and resizes for >2 lines',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CaptureSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify TextField has borderless decoration
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.border, InputBorder.none);
      expect(textField.decoration?.focusedBorder, InputBorder.none);
      expect(textField.decoration?.enabledBorder, InputBorder.none);

      // 2. Verify initial single-line size
      final initialSize = tester.getSize(find.byType(AnimatedContainer));
      expect(initialSize.height, lessThanOrEqualTo(70));

      // 3. Enter text with more than 2 lines
      await tester.enterText(
        find.byType(TextField),
        'Line 1: Project kickoff\nLine 2: Review requirements\nLine 3: Plan delivery',
      );
      await tester.pumpAndSettle();

      // 4. Verify container height expanded to accommodate multiline text
      final expandedSize = tester.getSize(find.byType(AnimatedContainer));
      expect(expandedSize.height, greaterThan(initialSize.height));
    },
  );

  testWidgets(
    'continuous typing across multiline expansion keeps EditableText element mounted and focused',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CaptureSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialElement = tester.element(find.byType(EditableText));
      final focusNode =
          tester.widget<EditableText>(find.byType(EditableText)).focusNode;
      expect(focusNode.hasFocus, isTrue);

      // Type line 1
      await tester.enterText(find.byType(TextField), 'First line');
      await tester.pump();
      expect(tester.element(find.byType(EditableText)), same(initialElement));

      // Type across resize threshold (> 2 lines)
      await tester.enterText(
        find.byType(TextField),
        'First line\nSecond line\nThird line continuing to type smoothly',
      );
      // Pump mid-animation (100ms) to ensure smooth interpolation
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.element(find.byType(EditableText)), same(initialElement));
      expect(focusNode.hasFocus, isTrue);

      await tester.pumpAndSettle();
      expect(tester.element(find.byType(EditableText)), same(initialElement));
      expect(focusNode.hasFocus, isTrue);

      // Continue typing more content without interruption
      await tester.enterText(
        find.byType(TextField),
        'First line\nSecond line\nThird line continuing to type smoothly and effortlessly',
      );
      await tester.pump();
      expect(tester.element(find.byType(EditableText)), same(initialElement));
      expect(focusNode.hasFocus, isTrue);
    },
  );

  testWidgets(
    'on send, message renders as green chat bubble on empty dimmed overlay before closing',
    (tester) async {
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

      await tester.tap(find.byTooltip('Save something'));
      await tester.pumpAndSettle();

      const message = "Let's meet up for dinner after work!";
      await tester.enterText(find.byType(TextField).last, message);
      await tester.pump();

      // Tap Save button
      await tester.tap(find.text('Save'));

      // Advance animation into the display hold phase (350ms)
      await tester.pump(const Duration(milliseconds: 350));

      // 1. Sent chat bubble is now prominently visible on the dimmed overlay
      expect(find.byKey(const ValueKey('sent_chat_bubble')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sent_chat_bubble')),
          matching: find.text(message),
        ),
        findsOneWidget,
      );

      // Verify the bubble uses the green styling matching the reference design
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('sent_chat_bubble')),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(
        (customPaint.painter! as SentChatBubblePainter).color,
        const Color(0xFF34C759),
      );

      // 2. Settle the animation to completion
      await tester.pumpAndSettle();

      // Bubble and sheet are dismissed; an unscheduled capture waits in Someday.
      expect(find.byKey(const ValueKey('sent_chat_bubble')), findsNothing);
      expect(find.text(message), findsNothing);
      final stored = (await tester.runAsync(() => database.watchAllItemsWithMetadata(null).first))!;
      expect(stored.single.$1.textContent, message);
      expect(stored.single.$1.status, 'deferred');
      expect(stored.single.$1.returnAt, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await database.close();
    },
  );

  testWidgets(
    'URL preview card formats entities (&#064; -> @, &#x2022; -> •) and allows dismissal',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final fakeEnhancer = _FakeUrlEnhancer(LocalMetadataDataSource(database));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guestModeProvider.overrideWith((ref) => true),
            appDatabaseProvider.overrideWithValue(database),
            initialLocationProvider.overrideWithValue('/inbox'),
            urlEnhancerProvider.overrideWithValue(fakeEnhancer),
          ],
          child: const LaterBoxApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Save something'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).last,
        'https://instagram.com/chaste_djaziri',
      );
      // Wait for debounce and async enhancement
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify preview card appears with decoded title (no &#064; or &#x2022;)
      expect(
        find.text(
          'Chaste Djaziri (@chaste_djaziri) • Instagram photos and videos',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Chaste Djaziri (&#064;chaste_djaziri) &#x2022; Instagram photos and videos',
        ),
        findsNothing,
      );
      expect(find.text('instagram.com'), findsOneWidget);

      // Dismiss the preview card via (X) button
      await tester.tap(
        find.byKey(
          const ValueKey(
            'dismiss_url_https://instagram.com/chaste_djaziri',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify card was dismissed
      expect(
        find.text(
          'Chaste Djaziri (@chaste_djaziri) • Instagram photos and videos',
        ),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await database.close();
    },
  );
}

class _FakeUrlEnhancer extends UrlEnhancer {
  _FakeUrlEnhancer(LocalMetadataDataSource local) : super(local: local);

  @override
  Future<EnrichedMetadata?> enhance(String rawUrl) async {
    return const EnrichedMetadata(
      title:
          'Chaste Djaziri (&#064;chaste_djaziri) &#x2022; Instagram photos and videos',
      domain: 'instagram.com',
      previewImageUrl: 'https://example.com/chaste.jpg',
    );
  }
}

class _FakePicker implements AttachmentFilePicker {
  const _FakePicker(this.files);

  final List<PickedAttachmentFile> files;

  @override
  Future<List<PickedAttachmentFile>> pickFiles({
    AttachmentPickerSource source = AttachmentPickerSource.files,
  }) async => files;
}
