import 'clipboard_capture_service.dart';
import 'desktop_capture_context.dart';
import 'selection_capture_service.dart';

/// Resolves the content to prefill when quick capture opens, in priority
/// order: selected text (when [useSelection] is true) → clipboard URL →
/// clipboard text → empty.
class DesktopCaptureContextResolver {
  DesktopCaptureContextResolver({
    required SelectionCaptureService selectionService,
    required ClipboardCaptureService clipboardService,
  })  : _selectionService = selectionService,
        _clipboardService = clipboardService;

  final SelectionCaptureService _selectionService;
  final ClipboardCaptureService _clipboardService;

  Future<DesktopCaptureContext> resolve({bool useSelection = true}) async {
    if (useSelection) {
      final selection = await _selectionService.readSelectedText();
      if (selection != null && selection.trim().isNotEmpty) {
        final source = await _selectionService.readFrontmostApplication();
        return DesktopCaptureContext(
          type: DesktopCaptureContextType.selection,
          value: selection.trim(),
          sourceApplication: source,
        );
      }
    }

    final clipboard = await _clipboardService.readText();
    final value = clipboard?.trim();
    if (value == null || value.isEmpty) {
      return const DesktopCaptureContext(
        type: DesktopCaptureContextType.empty,
        value: '',
      );
    }
    return DesktopCaptureContext(
      type: ClipboardCaptureService.isUrl(value)
          ? DesktopCaptureContextType.clipboardUrl
          : DesktopCaptureContextType.clipboardText,
      value: value,
    );
  }
}