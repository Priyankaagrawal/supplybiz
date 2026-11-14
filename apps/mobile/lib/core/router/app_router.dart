import 'package:go_router/go_router.dart';

import 'deep_links.dart';
import 'routes.dart';
import 'routing_controller.dart';
import '../../features/deliveries/deliveries_pages.dart';

GoRouter createAppRouter(RoutingController controller,
        {String? initialLocation}) =>
    GoRouter(
      routes: [
        GoRoute(
            path: '/vendor/deliveries',
            builder: (_, __) => const DeliveriesPage()),
        GoRoute(
            path: '/vendor/sync-queue',
            builder: (_, __) => const DeliveriesPage(queueOnly: true)),
        ...$appRoutes,
      ],
      initialLocation: initialLocation ?? const SplashRoute().location,
      refreshListenable: controller,
      debugLogDiagnostics: false,
      onException: (context, state, router) {
        controller.openLink(state.uri.toString());
        router.go(controller.access.home);
      },
      redirect: (context, state) {
        final id = state.pathParameters['id'];
        final productId = state.pathParameters['productId'];
        final invalidId = (id != null && !DeepLinkParser.uuid.hasMatch(id)) ||
            (productId != null && !DeepLinkParser.uuid.hasMatch(productId));
        final page = state.pathParameters['page'];
        final step = state.pathParameters['step'];
        final kind = state.pathParameters['kind'];
        final unknownLink =
            kind != null && !{'o', 'v', 's', 'khata'}.contains(kind);
        final invalidPage = page != null &&
            !{'update', 'legal', 'notifications', 'settings', 'switch-role'}
                .contains(page);
        final invalidStep = step != null &&
            !{'category', 'business', 'kyc', 'status'}.contains(step);
        return controller.redirect(state.uri,
            unknown: state.error != null ||
                invalidId ||
                invalidPage ||
                invalidStep ||
                unknownLink);
      },
    );
