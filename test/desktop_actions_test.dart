import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/desktop/clipboard_capture_service.dart';
import 'package:laterbox/core/desktop/desktop_actions.dart';
import 'package:laterbox/core/desktop/desktop_capture_context_resolver.dart';
import 'package:laterbox/core/desktop/desktop_providers.dart';
import 'package:laterbox/core/desktop/desktop_service.dart';
import 'package:laterbox/core/desktop/quick_capture_controller.dart';
import 'package:laterbox/core/desktop/selection_capture_service.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/capture/domain/capture_service.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/inbox/data/item_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('openQuickCapture activates the controller then shows the window',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _FakeDesktopService();
    final container = _container(desktop, database: database);
    addTearDown(container.dispose);

    await container.read(desktopActionsProvider).openQuickCapture();

    expect(container.read(quickCaptureControllerProvider).isActive, isTrue);
    expect(desktop.showCalls, 1);
    expect(desktop.hideCalls, 0);
  });

  test('openLaterBox closes capture state and shows the main window', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _FakeDesktopService();
    final container = _container(desktop, database: database);
    addTearDown(container.dispose);

    final controller = container.read(quickCaptureControllerProvider);
    await controller.open();
    expect(controller.isActive, isTrue);

    await container.read(desktopActionsProvider).openLaterBox();

    expect(controller.isActive, isFalse);
    expect(desktop.showMainCalls, 1);
    expect(desktop.hideCalls, 0);
  });

  test('openQuickCapture prefills from a text selection and records the app',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _FakeDesktopService();
    final container = _container(
      desktop,
      database: database,
      resolver: DesktopCaptureContextResolver(
        selectionService: _FakeSelectionService(
          selection: 'selected paragraph',
          appName: 'Safari',
        ),
        clipboardService: _FakeClipboardService('https://clipboard.example'),
      ),
    );
    addTearDown(container.dispose);

    await container.read(desktopActionsProvider).openQuickCapture();

    final controller = container.read(quickCaptureControllerProvider);
    expect(controller.isActive, isTrue);
    expect(controller.prefillText, 'selected paragraph');
    expect(controller.sourceApplication, 'Safari');
  });

  test('openQuickCapture falls back to the clipboard URL without a selection',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _FakeDesktopService();
    final container = _container(
      desktop,
      database: database,
      resolver: DesktopCaptureContextResolver(
        selectionService: const _FakeSelectionService(),
        clipboardService: _FakeClipboardService('https://clipboard.example'),
      ),
    );
    addTearDown(container.dispose);

    await container.read(desktopActionsProvider).openQuickCapture();

    final controller = container.read(quickCaptureControllerProvider);
    expect(controller.isActive, isTrue);
    expect(controller.prefillText, 'https://clipboard.example');
    expect(controller.sourceApplication, isNull);
  });

  test('finishQuickCapture restores the pre-capture window', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _FakeDesktopService();
    final container = _container(desktop, database: database);
    addTearDown(container.dispose);

    await container.read(desktopActionsProvider).finishQuickCapture();

    expect(desktop.finishCalls, 1);
  });

  test('openQuickCapture rethrows when showing the window fails', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _ThrowingDesktopService();
    final container = _container(desktop, database: database);
    addTearDown(container.dispose);

    await expectLater(
      container.read(desktopActionsProvider).openQuickCapture(),
      throwsException,
    );
  });
}

ProviderContainer _container(
  DesktopService desktop, {
  required AppDatabase database,
  DesktopCaptureContextResolver? resolver,
}) {
  return ProviderContainer(overrides: [
    desktopServiceProvider.overrideWithValue(desktop),
    quickCaptureControllerProvider.overrideWith(
      (ref) => QuickCaptureController(
        desktopService: desktop,
        clipboardService: const ClipboardCaptureService(),
        captureService: _captureService(database),
      ),
    ),
    if (resolver != null)
      desktopCaptureContextResolverProvider.overrideWithValue(resolver),
  ]);
}

CaptureService _captureService(AppDatabase database) {
  final local = LocalItemDataSource(database);
  final repository = ItemRepository(local, userId: null, onSaved: () async {});
  return CaptureService(repository);
}

class _FakeDesktopService extends DesktopService {
  int showCalls = 0;
  int hideCalls = 0;
  int showMainCalls = 0;
  int finishCalls = 0;
  final List<void Function()> blurListeners = [];
  final List<void Function()> closeListeners = [];

  @override
  Future<void> showQuickCapture() async {
    showCalls++;
  }

  @override
  Future<void> showMainWindow() async {
    showMainCalls++;
  }

  @override
  Future<void> hideMainWindow() async {
    hideCalls++;
  }

  @override
  Future<void> finishQuickCapture() async {
    finishCalls++;
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

class _ThrowingDesktopService extends _FakeDesktopService {
  @override
  Future<void> showQuickCapture() async {
    throw Exception('boom');
  }
}

class _FakeSelectionService extends SelectionCaptureService {
  const _FakeSelectionService({this.selection, this.appName});

  final String? selection;
  final String? appName;

  @override
  Future<String?> readSelectedText() async => selection;

  @override
  Future<String?> readFrontmostApplication() async => appName;
}

class _FakeClipboardService extends ClipboardCaptureService {
  _FakeClipboardService(this.text);

  final String? text;

  @override
  Future<String?> readText() async => text;
}