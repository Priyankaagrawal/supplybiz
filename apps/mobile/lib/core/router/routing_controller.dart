import 'package:flutter/foundation.dart';

import 'deep_links.dart';
import 'guards.dart';

/// Navigation state only; authentication and role mutation belong to T-015.
class RoutingController extends ChangeNotifier {
  RoutingController(
      {RouteAccess access = const RouteAccess(), DeepLinkParser? parser})
      : _access = access,
        parser = parser ?? DeepLinkParser();

  RouteAccess _access;
  RouteAccess get access => _access;
  final DeepLinkParser parser;
  DeepLinkTarget? _pendingLink;
  String? _pendingLocation;
  bool _goHome = false;

  void update(RouteAccess value) {
    // A logout must never replay the previous user's pending navigation.
    if (_access.signedIn && !value.signedIn) _clearPending();
    _access = value;
    notifyListeners();
  }

  void openLink(String raw) {
    _clearPending();
    _pendingLink = parser.parse(raw);
    _goHome = _pendingLink == null;
    notifyListeners();
  }

  void cancelPending() {
    _clearPending();
    _goHome = true;
    notifyListeners();
  }

  void _clearPending() {
    _pendingLink = null;
    _pendingLocation = null;
    _goHome = false;
  }

  String? redirect(Uri uri, {bool unknown = false}) {
    final path = uri.path;
    final parsed = parser.parse(uri.toString());
    if (unknown || (uri.hasScheme && parsed == null)) {
      _clearPending();
      _goHome = true;
    }
    if (parsed != null) _pendingLink = parsed;
    final isAlias = parsed != null ||
        {'o', 'v', 's', 'khata', 'invite'}
            .contains(uri.pathSegments.firstOrNull);
    final role = _access.activeRole ?? AppRole.customer;
    final target = _pendingLink?.location(role) ?? _pendingLocation;
    final desired =
        target ?? ((_goHome || unknown || isAlias) ? _access.home : path);
    final gate = guardRedirect(_access, desired);
    if (gate != null) {
      if (target == null && routeRole(desired) != null && !isAlias) {
        _pendingLocation = desired;
      }
      return gate == path ? null : gate;
    }
    if (target != null || _goHome || unknown || isAlias) {
      _clearPending();
      return desired == path ? null : desired;
    }
    return null;
  }
}
