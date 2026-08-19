import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/features/enrichment/domain/url_utils.dart';

void main() {
  group('normalizeUrl', () {
    test('lowercases scheme and host but keeps path and query', () {
      expect(
        normalizeUrl('HTTPS://WWW.Example.com/Article/?Ref=1'),
        'https://www.example.com/Article/?Ref=1',
      );
    });

    test('keeps distinct query strings distinct', () {
      expect(
        normalizeUrl('https://youtube.com/watch?v=aaa'),
        'https://youtube.com/watch?v=aaa',
      );
      expect(
        normalizeUrl('https://youtube.com/watch?v=bbb'),
        'https://youtube.com/watch?v=bbb',
      );
    });

    test('preserves ports and trailing slashes', () {
      expect(
        normalizeUrl('https://example.com:8443/path/'),
        'https://example.com:8443/path/',
      );
    });

    test('returns the trimmed input when not parseable as a URL', () {
      expect(normalizeUrl('not a url'), 'not a url');
      expect(normalizeUrl(''), '');
    });
  });

  group('extractDomain', () {
    test('strips www and scheme', () {
      expect(extractDomain('https://www.github.com/flutter'), 'github.com');
      expect(extractDomain('http://Example.com/x'), 'example.com');
    });

    test('returns null for text or malformed input', () {
      expect(extractDomain('hello world'), isNull);
      expect(extractDomain(null), isNull);
      expect(extractDomain(''), isNull);
    });
  });
}