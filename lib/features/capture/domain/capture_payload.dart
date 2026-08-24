enum CaptureSource {
  manual,
  androidShare,
  iosShare,
  macosShare,
  browserExtension,
  desktopQuickCapture,
  api,
}

class CapturePayload {
  const CapturePayload({
    this.id,
    this.text,
    this.url,
    this.createdAt,
    this.source = CaptureSource.manual,
  }) : assert(text != null || url != null, 'A capture needs text or a URL.');

  factory CapturePayload.fromValue(
    String value, {
    String? id,
    DateTime? createdAt,
    CaptureSource source = CaptureSource.manual,
  }) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    final isDirectUrl = uri != null && uri.hasScheme && uri.host.isNotEmpty;
    if (isDirectUrl) {
      return CapturePayload(
        id: id,
        url: trimmed,
        text: null,
        createdAt: createdAt,
        source: source,
      );
    }

    // Check if the text contains an embedded URL and selected text/quote
    final urlRegex = RegExp(r'(https?://[^\s]+)');
    final match = urlRegex.firstMatch(trimmed);
    if (match != null) {
      final matchedUrl = match.group(0)!;
      final remainingText = trimmed
          .replaceFirst(matchedUrl, '')
          .trim()
          .replaceAll(RegExp(r'^["“”\s]+|["“”\s]+$'), '');
      if (remainingText.isNotEmpty) {
        final snippet = remainingText.length > 120
            ? remainingText.substring(0, 120).trim()
            : remainingText;
        final encodedSnippet = Uri.encodeComponent(snippet);
        final String finalUrl;
        if (matchedUrl.contains(':~:text=')) {
          finalUrl = matchedUrl;
        } else if (matchedUrl.contains('#')) {
          finalUrl = '$matchedUrl:~:text=$encodedSnippet';
        } else {
          finalUrl = '$matchedUrl#:~:text=$encodedSnippet';
        }
        return CapturePayload(
          id: id,
          url: finalUrl,
          text: remainingText,
          createdAt: createdAt,
          source: source,
        );
      } else {
        return CapturePayload(
          id: id,
          url: matchedUrl,
          text: null,
          createdAt: createdAt,
          source: source,
        );
      }
    }

    return CapturePayload(
      id: id,
      url: null,
      text: trimmed,
      createdAt: createdAt,
      source: source,
    );
  }

  final String? id;
  final String? text;
  final String? url;
  final DateTime? createdAt;
  final CaptureSource source;

  String get value => url ?? text ?? '';
}
