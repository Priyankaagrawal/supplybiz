import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import 'core/config/app_environment.dart';
import 'core/l10n/l10n.dart';

class SupplyBizApp extends StatelessWidget {
  const SupplyBizApp({required this.environment, super.key});

  final AppEnvironment environment;

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
      builder: (context, child) => Theme(
        data: sbLightTheme(Localizations.localeOf(context)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(context.l10n.appName)),
          body: Center(
            child: Text(switch (environment) {
              AppEnvironment.dev => context.l10n.developmentEnvironment,
              AppEnvironment.staging => context.l10n.stagingEnvironment,
              AppEnvironment.prod => context.l10n.productionEnvironment,
            }),
          ),
        ),
      ),
    );
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
