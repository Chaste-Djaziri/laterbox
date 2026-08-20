import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/desktop/clipboard_capture_service.dart';
import 'package:laterbox/core/desktop/desktop_actions.dart';
import 'package:laterbox/core/desktop/desktop_providers.dart';
import 'package:laterbox/core/desktop/desktop_service.dart';
import 'package:laterbox/core/desktop/quick_capture_controller.dart';
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
    expect(desktop.hideCalls, 1);
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