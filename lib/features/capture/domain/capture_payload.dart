enum CaptureSource { manual, androidShare, iosShare }

class CapturePayload {
  const CapturePayload({this.text, this.url, this.source = CaptureSource.manual})
    : assert(text != null || url != null, 'A capture needs text or a URL.');

  factory CapturePayload.fromValue(
    String value, {
    CaptureSource source = CaptureSource.manual,
  }) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    final isUrl = uri != null && uri.hasScheme && uri.host.isNotEmpty;
    return CapturePayload(
      url: isUrl ? trimmed : null,
      text: isUrl ? null : trimmed,
      source: source,
    );
  }

  final String? text;
  final String? url;
  final CaptureSource source;

  String get value => url ?? text ?? '';
}