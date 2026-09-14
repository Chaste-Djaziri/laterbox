/// Normalizes a URL for stable cache keys: lowercases the scheme and host and
/// keeps the path and query verbatim so distinct query strings (for example
/// YouTube `watch?v=` URLs) remain distinct. Tracking-parameter stripping
/// (utm/fbclid/gclid) is intentionally deferred to a later phase.
String normalizeUrl(String raw) {
  final trimmed = raw.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return trimmed;
  return Uri(
    scheme: uri.scheme.toLowerCase(),
    host: uri.host.toLowerCase(),
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    query: uri.hasQuery ? uri.query : null,
    fragment: uri.hasFragment ? uri.fragment : null,
  ).toString();
}

/// Extracts a display domain (minus a leading "www.") from a URL, or null.
String? extractDomain(String? raw) {
  if (raw == null) return null;
  final uri = Uri.tryParse(raw);
  final host = uri?.host;
  if (host == null || host.isEmpty) return null;
  return host.startsWith('www.') ? host.substring(4) : host;
}

/// Extracts all HTTP and HTTPS URLs from arbitrary text.
List<String> extractUrls(String text) {
  if (text.isEmpty) return const [];
  final regex = RegExp(
    r'https?:\/\/[^\s<>"\)\]\}]+',
    caseSensitive: false,
  );
  final matches = regex.allMatches(text);
  final urls = <String>[];
  for (final match in matches) {
    var url = match.group(0)!;
    while (url.isNotEmpty && RegExp(r'[\.,;:!\?\)\]\}]$').hasMatch(url)) {
      url = url.substring(0, url.length - 1);
    }
    if (url.isNotEmpty && !urls.contains(url)) {
      urls.add(url);
    }
  }
  return urls;
}

/// Fully decodes HTML entities in text, including decimal numeric entities
/// (e.g. `&#064;` -> `@`), hex numeric entities (e.g. `&#x2022;` -> `•`),
/// and standard named entities (`&quot;`, `&amp;`, `&bull;`, etc.).
String decodeHtmlEntities(String input) {
  if (!input.contains('&')) return input;

  var current = input;
  for (var pass = 0; pass < 3; pass++) {
    final prev = current;

    // 1. Decimal numeric entities: &#064;, &#64;, &#8226;, etc.
    current = current.replaceAllMapped(RegExp(r'&#([0-9]{1,7});'), (match) {
      try {
        final code = int.parse(match.group(1)!);
        if (code > 0 && code <= 0x10FFFF) {
          return String.fromCharCode(code);
        }
      } catch (_) {}
      return match.group(0)!;
    });

    // 2. Hexadecimal numeric entities: &#x2022;, &#x40;, &#x0026;, etc.
    current = current.replaceAllMapped(
      RegExp(r'&#[xX]([0-9a-fA-F]{1,6});'),
      (match) {
        try {
          final code = int.parse(match.group(1)!, radix: 16);
          if (code > 0 && code <= 0x10FFFF) {
            return String.fromCharCode(code);
          }
        } catch (_) {}
        return match.group(0)!;
      },
    );

    // 3. Named entities
    current = current
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&bull;', '•')
        .replaceAll('&middot;', '·')
        .replaceAll('&sdot;', '⋅')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '…')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™')
        .replaceAll('&laquo;', '«')
        .replaceAll('&raquo;', '»')
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rsquo;', '’')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&prime;', '′')
        .replaceAll('&Prime;', '″');

    if (current == prev) break;
  }

  return current;
}

/// Cleans and formats metadata text: decodes HTML entities (like &#064; -> @,
/// &#x2022; -> •), strips superfluous newlines/tabs, and normalizes spaces.
String? cleanMetaText(String? input) {
  if (input == null) return null;
  final decoded = decodeHtmlEntities(input);
  final normalized = decoded
      .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
  return normalized.isEmpty ? null : normalized;
}