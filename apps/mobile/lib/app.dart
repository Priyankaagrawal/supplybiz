import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_environment.dart';
import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/router/routing_controller.dart';
import 'core/router/route_widgets.dart';

class SupplyBizApp extends StatefulWidget {
  const SupplyBizApp(
      {required this.environment, this.routingController, super.key});

  final AppEnvironment environment;
  final RoutingController? routingController;

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
    return AppRoutingScope(
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
        ));
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
