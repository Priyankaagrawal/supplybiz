import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_environment.dart';
import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/router/routing_controller.dart';
import 'core/router/route_widgets.dart';
import 'core/router/guards.dart';
import 'features/auth/auth_pages.dart';
import 'features/auth/session_controller.dart';

class SupplyBizApp extends StatefulWidget {
  const SupplyBizApp(
      {required this.environment,
      this.routingController,
      this.enableAuth = false,
      super.key});

  final AppEnvironment environment;
  final RoutingController? routingController;
  final bool enableAuth;

  @override
  State<SupplyBizApp> createState() => _SupplyBizAppState();
}

class _SupplyBizAppState extends State<SupplyBizApp> {
  late final RoutingController _controller =
      widget.routingController ?? RoutingController();
  late final GoRouter _router = createAppRouter(_controller);

  @override
  void dispose() {
    _router.dispose();
    if (widget.routingController == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
        overrides: [authEnabledProvider.overrideWithValue(widget.enableAuth)],
        child: _SessionBridge(
            controller: _controller,
            enabled: widget.enableAuth,
            child: AppRoutingScope(
                controller: _controller,
                environment: widget.environment,
                child: MaterialApp.router(
                  routerConfig: _router,
                  onGenerateTitle: (context) => context.l10n.appName,
                  theme: sbLightTheme(const Locale('en')),
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    ...SbLocalizations.delegates,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => Theme(
                    data: sbLightTheme(Localizations.localeOf(context)),
                    child: child!,
                  ),
                ))));
  }
}

class _SessionBridge extends ConsumerStatefulWidget {
  const _SessionBridge(
      {required this.controller, required this.enabled, required this.child});
  final RoutingController controller;
  final bool enabled;
  final Widget child;
  @override
  ConsumerState<_SessionBridge> createState() => _SessionBridgeState();
}

class _SessionBridgeState extends ConsumerState<_SessionBridge>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enabled) {
      Future.microtask(() => ref.read(sessionProvider.notifier).restore());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.enabled && state == AppLifecycleState.resumed) {
      // Resume verifies the live session; offline failures retain a retryable session.
      ref.read(sessionProvider.notifier).revalidate();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enabled) {
      ref.listen(sessionProvider, (previous, next) {
        final role = next.user?.activeRole?.value;
        widget.controller.update(RouteAccess(
            initialized: next.ready,
            signedIn: next.user != null,
            activeRole: role == 'VENDOR'
                ? AppRole.vendor
                : role == 'CUSTOMER'
                    ? AppRole.customer
                    : null));
      });
    }
    return widget.child;
  }
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      theme: sbLightTheme(const Locale('en')),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...SbLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
          builder: (context) => Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.startupError,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )),
      builder: (context, child) => Theme(
        data: sbLightTheme(Localizations.localeOf(context)),
        child: child!,
      ),
    );
  }
}
