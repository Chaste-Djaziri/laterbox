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