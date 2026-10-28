import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/config/app_environment.dart';
import 'core/utils/dates.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (_) {
        debugPrint('Supply Biz: framework error.');
      };

      try {
        environment.validateCompileTimeConfig(nativeFlavor: appFlavor);
        await initializeDateFormatters();
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
        runApp(SupplyBizApp(environment: environment));
      } catch (_) {
        // Error payloads can contain tokens, URLs or provider details.
        debugPrint('Supply Biz: application startup failed.');
        runApp(const StartupFailureApp());
      }
    },
    (_, __) {
      debugPrint('Supply Biz: uncaught application error.');
    },
  );
}
