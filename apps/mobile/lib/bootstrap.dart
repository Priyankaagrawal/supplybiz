import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_environment.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };

      try {
        environment.validateCompileTimeConfig();
        if (environment.firebaseEnabled) {
          try {
            await Firebase.initializeApp();
          } catch (error, stackTrace) {
            Error.throwWithStackTrace(
              StateError(
                'Firebase initialization failed for the ${environment.name} '
                'flavor. Verify its native Firebase configuration: $error',
              ),
              stackTrace,
            );
          }
        }
        runApp(SupplyBizApp(environment: environment));
      } catch (error, stackTrace) {
        debugPrint('Application startup failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        runApp(StartupFailureApp(error: error));
      }
    },
    (error, stackTrace) {
      debugPrint('Uncaught application error: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}
