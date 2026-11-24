import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/config/app_environment.dart';
import 'core/diagnostics/basic_diagnostics.dart';
import 'core/storage/app_storage.dart';
import 'core/utils/dates.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  final diagnostics = BasicDiagnostics(environment);
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      diagnostics.install();

      try {
        await diagnostics.identifyBuild();
        environment.validateCompileTimeConfig(nativeFlavor: appFlavor);
        await initializeDateFormatters();
        await AppStorage.instance.initialize();
        if (environment.firebaseEnabled) {
          try {
            await Firebase.initializeApp();
          } catch (_, stackTrace) {
            Error.throwWithStackTrace(
              StateError(
                'Firebase initialization failed for the ${environment.name} '
                'flavor. Verify its native Firebase configuration.',
              ),
              stackTrace,
            );
          }
        }
        runApp(SupplyBizApp(
            environment: environment, enableAuth: true, enableConfig: true));
        diagnostics.selfTest(
            requested: const bool.fromEnvironment('DIAGNOSTICS_SELF_TEST'));
      } catch (error) {
        // Error payloads can contain tokens, URLs or provider details.
        diagnostics.record(DiagnosticSource.startup, error);
        runApp(const StartupFailureApp());
      }
    },
    (error, _) {
      diagnostics.record(DiagnosticSource.zone, error);
    },
  );
}
