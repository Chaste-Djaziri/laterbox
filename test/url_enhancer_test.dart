import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/enrichment/data/local_metadata_data_source.dart';
import 'package:laterbox/features/enrichment/domain/url_enhancer.dart';
import 'package:laterbox/features/enrichment/domain/url_utils.dart';

void main() {
  group('decodeHtmlEntities and cleanMetaText', () {
    test('decodes decimal numeric entities such as &#064; to @', () {
      expect(decodeHtmlEntities('&#064;'), '@');
      expect(decodeHtmlEntities('user&#064;example.com'), 'user@example.com');
      expect(decodeHtmlEntities('Chaste Djaziri (&#064;chaste_djaziri)'), 'Chaste Djaziri (@chaste_djaziri)');
    });

    test('decodes hexadecimal numeric entities such as &#x2022; to bullet •', () {
      expect(decodeHtmlEntities('&#x2022;'), '•');
      expect(decodeHtmlEntities('Item 1 &#x2022; Item 2'), 'Item 1 • Item 2');
    });

    test('decodes combined Instagram title with both &#064; and &#x2022;', () {
      const raw = 'Chaste Djaziri (&#064;chaste_djaziri) &#x2022; Instagram photos and videos';
      expect(cleanMetaText(raw), 'Chaste Djaziri (@chaste_djaziri) • Instagram photos and videos');
    });

    test('decodes named entities and normalizes excess whitespace', () {
      const raw = '  &quot;Breaking&quot; &amp; &lt;News&gt; &mdash; &copy; 2026 \n\t ';
      expect(cleanMetaText(raw), '"Breaking" & <News> — © 2026');
    });
  });

  group('UrlEnhancer.parseHtmlMetadata', () {
    test('extracts og:title, og:image, og:site_name, and og:description', () {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <meta property="og:title" content="Chaste Djaziri (&quot;@chaste_djaziri&quot;) &bull; Instagram" />
  <meta property="og:image" content="https://instagram.com/p/123/cover.jpg" />
  <meta property="og:site_name" content="Instagram" />
  <meta property="og:description" content="Photos and videos by Chaste" />
</head>
<body></body>
</html>
''';
      final uri = Uri.parse('https://www.instagram.com/chaste_djaziri');
      final metadata = UrlEnhancer.parseHtmlMetadata(html, uri);

      expect(metadata.title, 'Chaste Djaziri ("@chaste_djaziri") • Instagram');
      expect(metadata.previewImageUrl, 'https://instagram.com/p/123/cover.jpg');
      expect(metadata.siteName, 'Instagram');
      expect(metadata.domain, 'instagram.com');
      expect(metadata.description, 'Photos and videos by Chaste');
    });

    test('resolves relative previewImageUrl against base URI', () {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <title>Article Title</title>
  <meta name="twitter:image" content="/images/hero.png" />
</head>
<body></body>
</html>
''';
      final uri = Uri.parse('https://example.org/blog/post-1');
      final metadata = UrlEnhancer.parseHtmlMetadata(html, uri);

      expect(metadata.title, 'Article Title');
      expect(metadata.previewImageUrl, 'https://example.org/images/hero.png');
      expect(metadata.domain, 'example.org');
    });
  });

  group('UrlEnhancer.enhance', () {
    late AppDatabase database;
    late LocalMetadataDataSource localDataSource;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      localDataSource = LocalMetadataDataSource(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('returns local cached metadata when available', () async {
      final now = DateTime.now();
      await database.into(database.itemMetadata).insert(
            ItemMetadataCompanion.insert(
              itemId: 'cached-item-id',
              status: const Value('enriched'),
              domain: const Value('github.com'),
              title: const Value('GitHub - LaterBox'),
              previewImageUrl: const Value('https://github.com/og.png'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database.into(database.items).insert(
            ItemsCompanion.insert(
              id: 'cached-item-id',
              url: const Value('https://github.com/laterbox'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final enhancer = UrlEnhancer(
        local: localDataSource,
        httpClient: MockClient((_) async => http.Response('', 404)),
      );

      final result = await enhancer.enhance('https://github.com/laterbox');
      expect(result, isNotNull);
      expect(result!.title, 'GitHub - LaterBox');
      expect(result.previewImageUrl, 'https://github.com/og.png');
    });

    test('falls back to direct HTTP open graph fetch when cache is empty', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('example.com')) {
          return http.Response(
            '''
<!DOCTYPE html>
<html>
<head>
  <meta property="og:title" content="Example Domain Showcase" />
  <meta property="og:image" content="https://example.com/social.jpg" />
</head>
</html>
''',
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final enhancer = UrlEnhancer(
        local: localDataSource,
        httpClient: mockClient,
      );

      final result = await enhancer.enhance('https://example.com/page');
      expect(result, isNotNull);
      expect(result!.title, 'Example Domain Showcase');
      expect(result.previewImageUrl, 'https://example.com/social.jpg');
      expect(result.domain, 'example.com');
    });

    test('fetches YouTube thumbnail and oEmbed directly for YouTube links', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('youtube.com/oembed')) {
          return http.Response(
            '{"title":"Awesome Flutter Demo","author_name":"Flutter Dev","thumbnail_url":"https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final enhancer = UrlEnhancer(
        local: localDataSource,
        httpClient: mockClient,
      );

      final result = await enhancer.enhance('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(result, isNotNull);
      expect(result!.title, 'Awesome Flutter Demo');
      expect(result.previewImageUrl, 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg');
      expect(result.domain, 'youtube.com');
    });
  });
}
