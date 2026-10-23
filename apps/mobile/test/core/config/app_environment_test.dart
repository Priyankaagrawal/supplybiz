import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';

void main() {
  group('AppEnvironment.validateCompileTimeConfig', () {
    test('accepts a matching flavor and absolute HTTP API URL', () {
      expect(
        () => AppEnvironment.dev.validateCompileTimeConfig(
          configuredName: 'dev',
          configuredApiBaseUrl: 'http://10.0.2.2:3000/api/v1',
        ),
        returnsNormally,
      );
    });

    test('rejects a config for a different flavor', () {
      expect(
        () => AppEnvironment.dev.validateCompileTimeConfig(
          configuredName: 'prod',
          configuredApiBaseUrl: 'https://api.supplybiz.example/api/v1',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a missing or non-HTTP API URL', () {
      expect(
        () => AppEnvironment.dev.validateCompileTimeConfig(
          configuredName: 'dev',
          configuredApiBaseUrl: '/api/v1',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
