import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/shared/models/laterbox_item.dart';
import 'package:laterbox/shared/widgets/item_actions.dart';

LaterBoxItem _item({
  String? url,
  String? text,
  TextSelector selector = const TextSelector(),
}) {
  return LaterBoxItem(
    id: 'test-id',
    url: url,
    text: text,
    selector: selector,
    createdAt: DateTime.utc(2026, 8, 20),
  );
}

void main() {
  group('buildTextFragmentUrl', () {
    test('builds a well-formed #:~:text= fragment', () {
      expect(
        buildTextFragmentUrl(
          _item(
            url: 'https://micorp.pro',
            text: 'Smart decisions for bold brands.',
          ),
        ),
        'https://micorp.pro#:~:text=Smart%20decisions%20for%20bold%20brands.',
      );
    });

    test('includes a prefix as context start', () {
      expect(
        buildTextFragmentUrl(
          _item(
            url: 'https://micorp.pro',
            text: 'Smart decisions for bold brands.',
            selector: const TextSelector(before: 'Our team makes'),
          ),
        ),
        'https://micorp.pro#:~:text=Our%20team%20makes-,Smart%20decisions%20for%20bold%20brands.',
      );
    });

    test('includes a suffix as context end', () {
      expect(
        buildTextFragmentUrl(
          _item(
            url: 'https://micorp.pro',
            text: 'Smart decisions for bold brands.',
            selector: const TextSelector(
              before: 'Our team makes',
              after: 'They drive growth',
            ),
          ),
        ),
        'https://micorp.pro#:~:text=Our%20team%20makes-,Smart%20decisions%20for%20bold%20brands.,-They%20drive%20growth',
      );
    });

    test('strips any existing fragment from the source url', () {
      expect(
        buildTextFragmentUrl(
          _item(
            url: 'https://micorp.pro/#old',
            text: 'Smart decisions for bold brands.',
          ),
        ),
        'https://micorp.pro/#:~:text=Smart%20decisions%20for%20bold%20brands.',
      );
    });

    test('keeps query strings intact', () {
      expect(
        buildTextFragmentUrl(
          _item(
            url: 'https://micorp.pro/page?ref=1',
            text: 'Bold brands',
          ),
        ),
        'https://micorp.pro/page?ref=1#:~:text=Bold%20brands',
      );
    });

    test('returns null without a url or text', () {
      expect(buildTextFragmentUrl(_item(url: null, text: 'x')), isNull);
      expect(buildTextFragmentUrl(_item(url: 'https://x.dev', text: '')), isNull);
      expect(buildTextFragmentUrl(_item(url: 'https://x.dev', text: '  ')), isNull);
    });

    test('round-trips through Uri without corrupting the fragment marker', () {
      final built = buildTextFragmentUrl(
        _item(
          url: 'https://micorp.pro',
          text: 'Smart decisions for bold brands.',
        ),
      )!;
      final uri = Uri.parse(built);
      expect(uri.fragment, startsWith(':~:text='));
      expect(
        uri.toString(),
        built,
        reason: 'Uri must not re-encode the #:~:text= marker',
      );
    });
  });
}