/// No-op selection capture for web and mobile.
///
/// Mirrors the call surface of `SelectionCaptureService` (io) so shared code
/// can compile on every platform. Always reports no selection.
class SelectionCaptureService {
  const SelectionCaptureService();

  Future<String?> readSelectedText() async => null;

  Future<String?> readFrontmostApplication() async => null;
}