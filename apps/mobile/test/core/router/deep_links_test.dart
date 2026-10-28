import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/router/deep_links.dart';
import 'package:supplybiz_mobile/core/router/guards.dart';

void main() {
  const id = '11111111-1111-4111-8111-111111111111';
  final parser = DeepLinkParser(trustedHosts: {'links.example.test'});
  test('T-013 validates documented relative/custom/approved-HTTPS entry points',
      () {
    expect(
        parser.parse('/o/$id')?.location(AppRole.vendor), '/vendor/orders/$id');
    expect(parser.parse('supplybiz://o/$id')?.location(AppRole.customer),
        '/customer/orders/$id');
    expect(parser.parse('supplybiz:///s/$id')?.location(AppRole.customer),
        '/customer/orders/subscriptions/$id');
    expect(parser.parse('/s/$id')?.location(AppRole.vendor),
        '/vendor/customers/subscriptions/$id');
    expect(parser.parse('https://links.example.test/v/$id')?.requiredRole,
        AppRole.customer);
    expect(parser.parse('/khata/$id')?.location(AppRole.customer),
        '/customer/khata/$id');
  });
  test(
      'T-013 rejects malformed IDs, foreign origins, redirect parameters and referrals',
      () {
    for (final raw in [
      '/o/not-an-id',
      '/o/$id/extra',
      '/o/%2F$id',
      '/o/%ZZ',
      'https://evil.example/o/$id',
      'http://links.example.test/o/$id',
      'https://user@links.example.test/o/$id',
      'https://links.example.test:444/o/$id',
      '//links.example.test/o/$id',
      'supplybiz://evil/o/$id',
      '/o/$id?next=https://evil.example',
      '/o/$id#fragment',
      '/invite/FAKE',
      '/unknown/$id',
      'o/$id',
    ]) {
      expect(parser.parse(raw), isNull, reason: raw);
    }
    expect(DeepLinkParser().parse('https://links.example.test/o/$id'), isNull);
    expect(parser.parse('x' * 2049), isNull);
  });
}
