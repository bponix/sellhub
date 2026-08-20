import 'package:flutter_test/flutter_test.dart';
import 'package:sellhub/core/navigation/deep_link_core.dart';
import 'package:sellhub/core/navigation/deep_link_service.dart';
import 'package:sellhub/core/utils/route_names.dart';

void main() {
  group('SellHub DeepLinkService', () {
    test('normalizes raw domains into https urls', () {
      final uri = DeepLinkService.normalizeExternalUri('demo-store.com');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'demo-store.com');
    });

    test('recognizes canonical host and store payload links', () {
      expect(
        DeepLinkService.canHandleUri(
          Uri.parse('https://reseller.store.bponi.com/app?routeName=orders'),
        ),
        isTrue,
      );
      expect(
        DeepLinkService.canHandleUri(
          Uri.parse('https://example.com/app?domain=demo.com&siteId=44'),
        ),
        isTrue,
      );
    });

    test('extracts store payload from query params', () {
      final store = DeepLinkService.extractStoreForTesting(
        Uri.parse(
          'https://reseller.store.bponi.com/app?domain=demo.com&siteId=55&title=Demo&logo=https://cdn.example/logo.png',
        ),
      );

      expect(store, isNotNull);
      expect(store!.siteId, 55);
      expect(store.domain, 'demo.com');
      expect(store.title, 'Demo');
      expect(store.logoUrl, 'https://cdn.example/logo.png');
    });

    test('merges direct query params and nested payload params', () {
      final params = DeepLinkService.payloadParamsForTesting(
        Uri.parse(
          'https://reseller.store.bponi.com/app?routeName=search&keyword=milk&params=%7B%22hid%22%3A%22P-1%22%2C%22category%22%3A%22grocery%22%7D',
        ),
      );

      expect(
        params,
        equals(<String, String>{
          'keyword': 'milk',
          'hid': 'P-1',
          'category': 'grocery',
        }),
      );
    });

    test('enforces route auth policy registry', () {
      expect(
        DeepLinkService.routeAccessForTesting(RouteNames.login),
        DeepLinkRouteAccess.public,
      );
      expect(
        DeepLinkService.routeAccessForTesting(RouteNames.orders),
        DeepLinkRouteAccess.deferUntilLogin,
      );
      expect(
        DeepLinkService.routeAccessForTesting('unknown-route'),
        DeepLinkRouteAccess.reject,
      );
    });

    test('enforces raw path auth policy registry', () {
      expect(
        DeepLinkService.pathAccessForTesting('/${RouteNames.login}'),
        DeepLinkRouteAccess.public,
      );
      expect(
        DeepLinkService.pathAccessForTesting('/${RouteNames.orders}'),
        DeepLinkRouteAccess.deferUntilLogin,
      );
      expect(
        DeepLinkService.pathAccessForTesting('/admin/secret'),
        DeepLinkRouteAccess.reject,
      );
    });

    test('normalizes encoded deep links and rejects unsafe schemes', () {
      final encoded = DeepLinkService.normalizeExternalUri(
        'https%3A%2F%2Freseller.store.bponi.com%2Fapp%3FrouteName%3Dorders',
      );
      final unsafe = DeepLinkService.normalizeExternalUri('javascript:alert(1)');

      expect(encoded, isNotNull);
      expect(encoded!.host, 'reseller.store.bponi.com');
      expect(unsafe, isNull);
    });
  });
}
