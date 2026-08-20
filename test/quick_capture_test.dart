import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/desktop/clipboard_capture_service.dart';
import 'package:laterbox/core/desktop/desktop_service.dart';
import 'package:laterbox/core/desktop/quick_capture_controller.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/capture/domain/capture_service.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/inbox/data/item_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ClipboardCaptureService.isUrl', () {
    test('accepts absolute URLs with a scheme', () {
      expect(ClipboardCaptureService.isUrl('https://example.com/a'), isTrue);
      expect(ClipboardCaptureService.isUrl('ftp://example.com/file'), isTrue);
      expect(ClipboardCaptureService.isUrl('  http://localhost:8080/x '), isTrue);
    });

    test('rejects plain text, fragments and schemes without a host', () {
      expect(ClipboardCaptureService.isUrl('just a note'), isFalse);
      expect(ClipboardCaptureService.isUrl('example.com'), isFalse);
      expect(ClipboardCaptureService.isUrl('https://'), isFalse);
      expect(ClipboardCaptureService.isUrl(''), isFalse);
    });
  });

  group('QuickCaptureController prefill', () {
    test('prefills a URL copied to the clipboard', () async {
      final controller = _controller(
        clipboardService: _FakeClipboardService('https://example.com/video'),
      );

      await controller.open();

      expect(controller.status, QuickCaptureStatus.active);
      expect(controller.prefillText, 'https://example.com/video');
      controller.dispose();
    });

    test('prefills plain clipboard text', () async {
      final controller = _controller(
        clipboardService: _FakeClipboardService('some random text'),
      );

      await controller.open();

      expect(controller.status, QuickCaptureStatus.active);
      expect(controller.prefillText, 'some random text');
      controller.dispose();
    });

    test('starts empty when the clipboard is empty', () async {
      final controller = _controller(
        clipboardService: _FakeClipboardService(null),
      );

      await controller.open();

      expect(controller.status, QuickCaptureStatus.active);
      expect(controller.prefillText, isNull);
      controller.dispose();
    });

    test('preserves unsaved typed text when the clipboard is unchanged', () async {
      final clipboard = _FakeClipboardService(null);
      final controller = _controller(clipboardService: clipboard);

      await controller.open();
      controller.updateDraft('notes to keep');
      await controller.close();

      await controller.open();
      expect(controller.prefillText, 'notes to keep');
      controller.dispose();
    });
  });

  group('QuickCaptureController flow', () {
    test('saves via the shared capture pipeline and closes', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final desktop = _FakeDesktopService();
      final controller = QuickCaptureController(
        desktopService: desktop,
        clipboardService: const ClipboardCaptureService(),
        captureService: _captureService(database),
      );

      controller.updateDraft('https://example.com/saved');
      await controller.open();
      await controller.save();

      expect(controller.status, QuickCaptureStatus.success);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(controller.status, QuickCaptureStatus.idle);
      expect(desktop.hideCalls, 0);

      final items = await database.watchInboxItems(null).first;
      expect(items.single.url, 'https://example.com/saved');
      expect(items.single.syncStatus, 'pending');
      controller.dispose();
    });

    test('saveValue persists an explicit value via the capture pipeline', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final desktop = _FakeDesktopService();
      final controller = QuickCaptureController(
        desktopService: desktop,
        clipboardService: const ClipboardCaptureService(),
        captureService: _captureService(database),
      );

      await controller.open();
      await controller.saveValue('https://example.com/explicit');

      expect(controller.status, QuickCaptureStatus.success);
      final items = await database.watchInboxItems(null).first;
      expect(items.single.url, 'https://example.com/explicit');
      expect(items.single.syncStatus, 'pending');
      controller.dispose();
    });

    test('blur is ignored while blur-close is disabled (debugging default)',
        () async {
      final desktop = _FakeDesktopService();
      final controller = _controller(desktopService: desktop);

      await controller.open();
      desktop.blurListeners.first.call();

      expect(controller.status, QuickCaptureStatus.active);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(controller.status, QuickCaptureStatus.active);
      expect(desktop.hideCalls, 0);
      controller.dispose();
    });

    test('blur closes the capture window when blur-close is enabled', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final desktop = _FakeDesktopService();
      final controller = QuickCaptureController(
        desktopService: desktop,
        clipboardService: const ClipboardCaptureService(),
        captureService: _captureService(database),
        enableBlurClose: true,
      );

      await controller.open();
      desktop.blurListeners.first.call();

      expect(controller.status, QuickCaptureStatus.active);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(controller.status, QuickCaptureStatus.idle);
      expect(desktop.hideCalls, 0);
      controller.dispose();
    });

    test('blur does not close while a save is in flight', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final desktop = _FakeDesktopService();
      final controller = QuickCaptureController(
        desktopService: desktop,
        clipboardService: const ClipboardCaptureService(),
        captureService: _captureService(database),
        enableBlurClose: true,
      );

      controller.updateDraft('https://example.com/x');
      await controller.open();
      final saving = controller.save();
      desktop.blurListeners.first.call();
      await saving;

      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(controller.status, QuickCaptureStatus.success);
      controller.dispose();
    });
  });
}

QuickCaptureController _controller({
  DesktopService? desktopService,
  ClipboardCaptureService? clipboardService,
}) {
  final database = AppDatabase(NativeDatabase.memory());
  return QuickCaptureController(
    desktopService: desktopService ?? _FakeDesktopService(),
    clipboardService: clipboardService ?? const ClipboardCaptureService(),
    captureService: _captureService(database),
  );
}

CaptureService _captureService(AppDatabase database) {
  final local = LocalItemDataSource(database);
  final repository = ItemRepository(local, userId: null, onSaved: () async {});
  return CaptureService(repository);
}

class _FakeDesktopService extends DesktopService {
  int showCalls = 0;
  int hideCalls = 0;
  final List<void Function()> blurListeners = [];
  final List<void Function()> closeListeners = [];

  @override
  Future<void> showQuickCapture() async {
    showCalls++;
  }

  @override
  Future<void> hideMainWindow() async {
    hideCalls++;
  }

  @override
  Future<void> restoreMainWindow() async {}

  @override
  void addWindowBlurListener(void Function() onBlur) {
    blurListeners.add(onBlur);
  }

  @override
  void addWindowCloseListener(void Function() onClose) {
    closeListeners.add(onClose);
  }
}

class _FakeClipboardService extends ClipboardCaptureService {
  _FakeClipboardService(this.text);

  String? text;

  @override
  Future<String?> readText() async => text;
}