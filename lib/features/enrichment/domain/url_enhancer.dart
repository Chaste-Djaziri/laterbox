import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/local_metadata_data_source.dart';
import '../data/remote_metadata_data_source.dart';
import 'item_metadata.dart';
import 'url_utils.dart';

/// Service that enhances URLs with social graph, OpenGraph tags, title,
/// domain, and cover preview images.
class UrlEnhancer {
  UrlEnhancer({
    required this.local,
    this.remote,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final LocalMetadataDataSource local;
  final RemoteMetadataDataSource? remote;
  final http.Client _httpClient;

  /// Enhances a URL by checking local cache first, remote edge function second,
  /// and direct open graph scraping as fallback.
  Future<EnrichedMetadata?> enhance(String rawUrl) async {
    final normalized = normalizeUrl(rawUrl);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;

    // 1. Check local cache in SQLite
    final cached = await local.enrichedForUrl(normalized);
    if (cached != null &&
        (cached.title != null || cached.previewImageUrl != null)) {
      return EnrichedMetadata.fromDrift(cached);
    }

    // 2. Try remote Supabase Edge Function (enrich-url) if available
    final remoteDataSource = remote;
    if (remoteDataSource != null) {
      try {
        final metadata = await remoteDataSource.fetch(normalized);
        if (metadata.title != null || metadata.previewImageUrl != null) {
          return metadata;
        }
      } catch (_) {
        // Fallback to direct client-side open graph fetch
      }
    }

    // 3. Fallback: direct Open Graph and oEmbed scraping
    return _fetchDirect(uri);
  }

  Future<EnrichedMetadata?> _fetchDirect(Uri uri) async {
    final domain = extractDomain(uri.toString()) ?? uri.host;

    // Fast-path: YouTube video oEmbed & thumbnail
    final ytId = _extractYouTubeId(uri);
    if (ytId != null) {
      final oembed = await _fetchYouTubeOEmbed(uri.toString());
      return EnrichedMetadata(
        domain: 'youtube.com',
        siteName: oembed?['author_name'] ?? 'YouTube',
        title: oembed?['title'] ?? 'YouTube Video',
        faviconUrl:
            'https://www.youtube.com/s/desktop/f1725893/img/favicon_144x144.png',
        previewImageUrl: oembed?['thumbnail_url'] ??
            'https://i.ytimg.com/vi/$ytId/hqdefault.jpg',
      );
    }

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return parseHtmlMetadata(response.body, uri);
      }
    } catch (_) {
      // Ignored
    }

    return EnrichedMetadata(
      domain: domain,
      siteName: domain,
      title: domain,
      faviconUrl: 'https://www.google.com/s2/favicons?domain=$domain&sz=128',
    );
  }

  static String? _extractYouTubeId(Uri url) {
    final host = (extractDomain(url.toString()) ?? url.host).toLowerCase();
    if (host == 'youtube.com' || host == 'm.youtube.com') {
      final v = url.queryParameters['v'];
      if (v != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(v)) return v;
      final match = RegExp(r'/(?:shorts|embed|live|v)/([a-zA-Z0-9_-]{11})')
          .firstMatch(url.path);
      if (match != null) return match.group(1);
    } else if (host == 'youtu.be') {
      final seg = url.pathSegments.isNotEmpty ? url.pathSegments.first : null;
      if (seg != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(seg)) return seg;
    }
    return null;
  }

  Future<Map<String, String>?> _fetchYouTubeOEmbed(String urlStr) async {
    try {
      final oembedUrl = Uri.parse(
        'https://www.youtube.com/oembed?url=${Uri.encodeComponent(urlStr)}&format=json',
      );
      final res =
          await _httpClient.get(oembedUrl).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          return {
            if (data['title'] is String) 'title': data['title'] as String,
            if (data['author_name'] is String)
              'author_name': data['author_name'] as String,
            if (data['thumbnail_url'] is String)
              'thumbnail_url': data['thumbnail_url'] as String,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  static EnrichedMetadata parseHtmlMetadata(String html, Uri uri) {
    final domain = extractDomain(uri.toString()) ?? uri.host;

    String? extractMeta(List<String> patterns) {
      for (final pattern in patterns) {
        final regex = RegExp(pattern, caseSensitive: false);
        final match = regex.firstMatch(html);
        if (match != null) {
          final content = match.group(1)?.trim();
          if (content != null && content.isNotEmpty) {
            return _decodeHtml(content);
          }
        }
      }
      return null;
    }

    final title = extractMeta([
      r'''<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']''',
      r'''<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:title["']''',
      r'''<meta[^>]+name=["']twitter:title["'][^>]+content=["']([^"']+)["']''',
      r'''<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:title["']''',
      r'''<title[^>]*>([^<]+)<\/title>''',
    ]);

    final image = extractMeta([
      r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']''',
      r'''<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']''',
      r'''<meta[^>]+property=["']og:image:secure_url["'][^>]+content=["']([^"']+)["']''',
      r'''<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']''',
      r'''<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image["']''',
      r'''<meta[^>]+name=["']twitter:image:src["'][^>]+content=["']([^"']+)["']''',
    ]);

    final siteName = extractMeta([
      r'''<meta[^>]+property=["']og:site_name["'][^>]+content=["']([^"']+)["']''',
      r'''<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:site_name["']''',
    ]);

    final description = extractMeta([
      r'''<meta[^>]+property=["']og:description["'][^>]+content=["']([^"']+)["']''',
      r'''<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:description["']''',
      r'''<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']''',
      r'''<meta[^>]+content=["']([^"']+)["'][^>]+name=["']description["']''',
    ]);

    String? resolvedImage = image;
    if (resolvedImage != null && resolvedImage.isNotEmpty) {
      if (resolvedImage.startsWith('//')) {
        resolvedImage = '${uri.scheme}:$resolvedImage';
      } else if (resolvedImage.startsWith('/')) {
        resolvedImage = uri.resolve(resolvedImage).toString();
      }
    }

    final favicon = 'https://www.google.com/s2/favicons?domain=$domain&sz=128';

    return EnrichedMetadata(
      domain: domain,
      siteName: siteName ?? domain,
      title: title ?? domain,
      description: description,
      faviconUrl: favicon,
      previewImageUrl: resolvedImage,
    );
  }

  static String _decodeHtml(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}
