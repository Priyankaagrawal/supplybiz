import 'guards.dart';

enum DeepLinkKind { order, vendor, subscription, khata }

class DeepLinkTarget {
  const DeepLinkTarget(this.kind, this.id);
  final DeepLinkKind kind;
  final String id;

  AppRole? get requiredRole => switch (kind) {
        DeepLinkKind.vendor || DeepLinkKind.khata => AppRole.customer,
        _ => null,
      };

  String location(AppRole role) => switch (kind) {
        DeepLinkKind.order => '/${role.name}/orders/$id',
        DeepLinkKind.subscription => role == AppRole.vendor
            ? '/vendor/customers/subscriptions/$id'
            : '/customer/orders/subscriptions/$id',
        DeepLinkKind.vendor => '/customer/home/vendors/$id',
        DeepLinkKind.khata => '/customer/khata/$id',
      };
}

/// Q-33: HTTPS hosts must be explicitly configured, never inferred from a link.
/// Q-14: referral attribution is not enabled; invite/unknown links resolve Home.
class DeepLinkParser {
  DeepLinkParser({Set<String> trustedHosts = const {}})
      : trustedHosts =
            Set.unmodifiable(trustedHosts.map((host) => host.toLowerCase()));

  final Set<String> trustedHosts;
  static final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  DeepLinkTarget? parse(String raw) {
    if (raw.length > 2048) return null;
    try {
      final uri = Uri.parse(raw);
      if (uri.hasQuery ||
          uri.hasFragment ||
          uri.userInfo.isNotEmpty ||
          uri.hasPort) {
        return null;
      }
      List<String> parts;
      if (uri.scheme == 'https' &&
          trustedHosts.contains(uri.host.toLowerCase())) {
        parts = uri.pathSegments;
      } else if (uri.scheme == 'supplybiz') {
        parts = [if (uri.host.isNotEmpty) uri.host, ...uri.pathSegments];
      } else if (!uri.hasScheme &&
          !uri.hasAuthority &&
          raw.startsWith('/') &&
          !raw.startsWith('//')) {
        parts = uri.pathSegments;
      } else {
        return null;
      }
      if (parts.length != 2 || !uuid.hasMatch(parts[1])) return null;
      final kind = switch (parts[0]) {
        'o' => DeepLinkKind.order,
        'v' => DeepLinkKind.vendor,
        's' => DeepLinkKind.subscription,
        'khata' => DeepLinkKind.khata,
        _ => null,
      };
      return kind == null ? null : DeepLinkTarget(kind, parts[1]);
    } on FormatException {
      return null;
    }
  }
}
