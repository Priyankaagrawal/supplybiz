import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/config/app_environment.dart';
import 'core/diagnostics/basic_diagnostics.dart';
import 'core/diagnostics/startup_timing.dart';
import 'core/storage/app_storage.dart';
import 'core/utils/dates.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  final diagnostics = BasicDiagnostics(environment);
  final timing = StartupTiming(environment);
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      timing.mark(StartupPhase.binding);
      diagnostics.install();

      try {
        // Optional version metadata must not hold the first usable screen behind
        // a slow platform channel. Early diagnostics retain "unavailable" until
        // the bounded lookup completes; its errors are handled internally.
        unawaited(diagnostics.identifyBuild());
        timing.mark(StartupPhase.diagnosticsScheduled);
        environment.validateCompileTimeConfig(nativeFlavor: appFlavor);
        await initializeDateFormatters();
        timing.mark(StartupPhase.dateFormats);
        await AppStorage.instance.initialize();
        timing.mark(StartupPhase.storage);
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
        timing.mark(StartupPhase.firebase);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => timing.mark(StartupPhase.firstFrame));
        runApp(SupplyBizApp(
            environment: environment, enableAuth: true, enableConfig: true));
        timing.mark(StartupPhase.runApp);
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
