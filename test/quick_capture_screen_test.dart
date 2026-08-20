import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/desktop/clipboard_capture_service.dart';
import 'package:laterbox/core/desktop/desktop_capture_context.dart';
import 'package:laterbox/core/desktop/desktop_providers.dart';
import 'package:laterbox/core/desktop/desktop_service.dart';
import 'package:laterbox/core/desktop/quick_capture_controller.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/capture/domain/capture_service.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/inbox/data/item_repository.dart';
import 'package:laterbox/features/quick_capture/presentation/quick_capture_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the capture field without a Material error', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _FakeDesktopService();
    final container = ProviderContainer(overrides: [
      desktopServiceProvider.overrideWithValue(desktop),
      quickCaptureControllerProvider.overrideWith(
        (ref) => QuickCaptureController(
          desktopService: desktop,
          clipboardService: const _FakeClipboardService(),
          captureService: _captureService(database),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await container.read(quickCaptureControllerProvider).open();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Material(child: QuickCaptureScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('fits the capture window content height with a source chip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(620, 240);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _FakeDesktopService();
    final container = ProviderContainer(overrides: [
      desktopServiceProvider.overrideWithValue(desktop),
      quickCaptureControllerProvider.overrideWith(
        (ref) => QuickCaptureController(
          desktopService: desktop,
          clipboardService: const _FakeClipboardService(),
          captureService: _captureService(database),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await container.read(quickCaptureControllerProvider).open(
      context: const DesktopCaptureContext(
        type: DesktopCaptureContextType.selection,
        value: 'selected text',
        sourceApplication: 'Safari',
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Material(child: QuickCaptureScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Selected from Safari'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}

CaptureService _captureService(AppDatabase database) {
  final local = LocalItemDataSource(database);
  final repository = ItemRepository(local, userId: null, onSaved: () async {});
  return CaptureService(repository);
}

class _FakeDesktopService extends DesktopService {
  @override
  Future<void> showQuickCapture() async {}

  @override
  Future<void> hideMainWindow() async {}

  @override
  Future<void> restoreMainWindow() async {}

  @override
  Future<void> showMainWindow() async {}

  @override
  void addWindowBlurListener(void Function() onBlur) {}

  @override
  void addWindowCloseListener(void Function() onClose) {}
}

class _FakeClipboardService extends ClipboardCaptureService {
  const _FakeClipboardService();

  @override
  Future<String?> readText() async => null;
}