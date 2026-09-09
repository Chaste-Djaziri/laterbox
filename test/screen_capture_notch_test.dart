import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/desktop/desktop_notch_service.dart';
import 'package:laterbox/core/desktop/screen_capture_context.dart';
import 'package:laterbox/core/desktop/screen_watcher_service.dart';
import 'package:laterbox/core/desktop/selection_capture_service.dart';
import 'package:laterbox/features/capture/domain/capture_payload.dart';
import 'package:laterbox/features/capture/domain/capture_service.dart';

class _FakeCaptureService implements CaptureService {
  final List<CapturePayload> saved = [];

  @override
  Future<void> save(CapturePayload payload) async {
    saved.add(payload);
  }

  Future<List<CapturePayload>> getPending() async => saved;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSelectionCaptureService extends SelectionCaptureService {
  _FakeSelectionCaptureService({this.contextToReturn});

  ScreenCaptureContext? contextToReturn;
  bool lastNotchStyle = false;

  @override
  Future<bool> setNotchWindowStyle(bool isNotch) async {
    lastNotchStyle = isNotch;
    return true;
  }

  @override
  Future<ScreenCaptureContext?> readScreenContext() async => contextToReturn;

  @override
  Future<Map<String, dynamic>?> getScreenGeometry() async => {
        'screenWidth': 1728.0,
        'screenHeight': 1117.0,
        'notchHeight': 38.0,
        'hasNotch': true,
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const windowManagerChannel = MethodChannel('window_manager');
  const macosCompanionChannel = MethodChannel('laterbox/macos_companion');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowManagerChannel, (call) async {
      switch (call.method) {
        case 'getBounds':
          return {'x': 100.0, 'y': 100.0, 'width': 1100.0, 'height': 720.0};
        case 'isMaximized':
          return false;
        case 'isMinimized':
          return false;
        case 'isMaximizable':
          return true;
        default:
          return true;
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(macosCompanionChannel, (call) async => true);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowManagerChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(macosCompanionChannel, null);
  });
  group('ScreenCaptureContext', () {
    test('parses dictionary with active tab, selection and highlight URL', () {
      final context = ScreenCaptureContext.fromMap({
        'application': 'Safari',
        'url': 'https://flutter.dev/docs',
        'title': 'Flutter Documentation',
        'selectedText': 'Build apps for any screen',
        'highlightUrl': 'https://flutter.dev/docs#:~:text=Build%20apps',
      });

      expect(context.application, 'Safari');
      expect(context.frontmostApp, 'Safari');
      expect(context.url, 'https://flutter.dev/docs');
      expect(context.activeUrl, 'https://flutter.dev/docs');
      expect(context.title, 'Flutter Documentation');
      expect(context.activeTitle, 'Flutter Documentation');
      expect(context.selectedText, 'Build apps for any screen');
      expect(context.highlightUrl, 'https://flutter.dev/docs#:~:text=Build%20apps');
      expect(context.hasUrl, isTrue);
      expect(context.hasSelection, isTrue);
      expect(context.hasHighlightUrl, isTrue);
      expect(context.targetUrl, 'https://flutter.dev/docs#:~:text=Build%20apps');
    });
  });

  group('SelectionCaptureService text fragment formatting', () {
    test('formats short exact phrase fragment', () {
      final url = SelectionCaptureService.formatTextFragmentUrl(
        'https://example.com/article',
        'apple banana cherry',
      );
      expect(url, 'https://example.com/article#:~:text=apple%20banana%20cherry');
    });

    test('formats range start,end for long sentences (>10 words)', () {
      final longQuote =
          'One two three four five six seven eight nine ten eleven twelve thirteen';
      final url = SelectionCaptureService.formatTextFragmentUrl(
        'https://example.com/article',
        longQuote,
      );
      expect(url, contains('#:~:text=One%20two%20three,eleven%20twelve%20thirteen'));
    });

    test('preserves existing text fragment unchanged', () {
      const existing = 'https://example.com/article#:~:text=already%20highlighted';
      final url = SelectionCaptureService.formatTextFragmentUrl(
        existing,
        'new quote',
      );
      expect(url, existing);
    });
  });

  group('ScreenWatcherService', () {
    late _FakeCaptureService fakeCapture;
    late _FakeSelectionCaptureService fakeSelection;
    late ScreenWatcherService watcher;

    setUp(() {
      fakeCapture = _FakeCaptureService();
      fakeSelection = _FakeSelectionCaptureService(
        contextToReturn: const ScreenCaptureContext(
          application: 'Arc',
          url: 'https://news.ycombinator.com',
          title: 'Hacker News',
          selectedText: 'Show HN: LaterBox',
          highlightUrl: 'https://news.ycombinator.com#:~:text=LaterBox',
        ),
      );
      watcher = ScreenWatcherService(
        selectionService: fakeSelection,
        captureService: fakeCapture,
      );
    });

    test('pollNow updates currentContext', () async {
      await watcher.pollNow();
      expect(watcher.currentContext, isNotNull);
      expect(watcher.currentContext?.frontmostApp, 'Arc');
      expect(watcher.hasActiveLink, isTrue);
      expect(watcher.hasSelectedText, isTrue);
    });

    test('saveActiveLink captures frontmost browser link with metadata', () async {
      await watcher.pollNow();
      final saved = await watcher.saveActiveLink(note: 'Check later');
      expect(saved, isTrue);
      expect(fakeCapture.saved, hasLength(1));
      final payload = fakeCapture.saved.first;
      expect(payload.url, contains('https://news.ycombinator.com'));
      expect(payload.source, CaptureSource.desktopQuickCapture);
    });

    test('saveSelectedWordReference preserves snippet and text fragment URL', () async {
      await watcher.pollNow();
      final saved = await watcher.saveSelectedWordReference();
      expect(saved, isTrue);
      expect(fakeCapture.saved, hasLength(1));
      final payload = fakeCapture.saved.first;
      expect(payload.text, contains('Show HN: LaterBox'));
      expect(payload.url, contains('#:~:text=LaterBox'));
      expect(payload.source, CaptureSource.desktopQuickCapture);
    });
  });

  group('DesktopNotchService mode transitions', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('initializes in fullWindow mode and toggles island/pill states', () async {
      final fakeSelection = _FakeSelectionCaptureService();
      final notch = DesktopNotchService(fakeSelection);
      expect(notch.mode, NotchDisplayMode.fullWindow);
      expect(notch.isDockedToNotch, isFalse);

      await notch.dockToNotch(expandIsland: false);
      expect(notch.isDockedToNotch, isTrue);

      await notch.expandIsland();
      expect(notch.isIslandExpanded, isTrue);

      await notch.collapseToPill();
      expect(notch.mode, NotchDisplayMode.notchPill);

      await notch.expandToFullWindow();
      expect(notch.mode, NotchDisplayMode.fullWindow);
      expect(notch.isDockedToNotch, isFalse);
    });
  });
}
