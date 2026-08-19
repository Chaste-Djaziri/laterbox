enum CaptureSource { manual, androidShare, iosShare }

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
    final isUrl = uri != null && uri.hasScheme && uri.host.isNotEmpty;
    return CapturePayload(
      id: id,
      url: isUrl ? trimmed : null,
      text: isUrl ? null : trimmed,
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