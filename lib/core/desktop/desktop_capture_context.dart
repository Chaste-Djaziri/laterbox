/// What kind of content was captured when `⌥Space` fired.
enum DesktopCaptureContextType { selection, clipboardUrl, clipboardText, empty }

/// The content that should prefill a quick capture, resolved in priority
/// order: selected text → clipboard URL → clipboard text → empty.
class DesktopCaptureContext {
  const DesktopCaptureContext({
    required this.type,
    required this.value,
    this.sourceApplication,
  });

  final DesktopCaptureContextType type;
  final String value;

  /// Frontmost application at capture time (e.g. “Safari”), when known.
  final String? sourceApplication;

  bool get isEmpty => type == DesktopCaptureContextType.empty;
}