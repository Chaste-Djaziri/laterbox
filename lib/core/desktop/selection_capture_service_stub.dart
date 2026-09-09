import 'screen_capture_context.dart';

/// No-op selection capture for web and mobile.
///
/// Mirrors the call surface of `SelectionCaptureService` (io) so shared code
/// can compile on every platform. Always reports no selection.
class SelectionCaptureService {
  const SelectionCaptureService();

  Future<String?> readSelectedText() async => null;

  Future<String?> readFrontmostApplication() async => null;

  Future<Map<String, String>?> readActiveBrowserTab({String? appName}) async => null;

  Future<ScreenCaptureContext?> readScreenContext() async => null;

  static String formatTextFragmentUrl(String baseUrl, String selectedText) => baseUrl;

  Future<bool> requestAccessibilityPermission() async => false;

  Future<bool> isAccessibilityTrusted() async => false;
}