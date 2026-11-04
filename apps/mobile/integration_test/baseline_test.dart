import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_mobile/app.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/utils/dates.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Day 1 Android shell, native storage and host API readiness',
      (tester) async {
    AppEnvironment.dev.validateCompileTimeConfig();
    await initializeDateFormatters();
    await AppStorage.instance.initialize();
    addTearDown(AppStorage.instance.close);
    final client = Dio(BaseOptions(
      baseUrl: AppEnvironment.dev.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    addTearDown(client.close);
    final response = await client.get<Map<String, dynamic>>('/health/ready');
    expect(response.data?['status'], 'UP');
    expect(response.data?['checks']['database']['status'], 'up');
    expect(response.data?['checks']['storage']['status'], 'up');
    await tester
        .pumpWidget(const SupplyBizApp(environment: AppEnvironment.dev));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Development environment'), findsOneWidget);
    expect(find.byType(StartupFailureApp), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
