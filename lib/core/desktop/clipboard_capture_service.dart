import 'package:flutter/services.dart';

/// Reads the clipboard and classifies capture prefill candidates.
///
/// Works on every platform (including web and mobile); only the pure helpers
/// are used for quick capture prefill decisions.
class ClipboardCaptureService {
  const ClipboardCaptureService();

  /// Reads the current clipboard text, or `null` when it is empty or not text.
  Future<String?> readText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.trim().isEmpty) return null;
      return text;
    } on PlatformException {
      return null;
    }
  }

  /// Whether [value] looks like an absolute URL (scheme://...).
  static bool isUrl(String value) {
    final trimmed = value.trim();
    final schemeEnd = trimmed.indexOf('://');
    if (schemeEnd <= 0) return false;
    final scheme = trimmed.substring(0, schemeEnd);
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*$').hasMatch(scheme)) return false;
    return trimmed.length > schemeEnd + 3;
  }
}