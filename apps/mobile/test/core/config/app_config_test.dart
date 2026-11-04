import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/app.dart';
import 'package:supplybiz_mobile/core/config/app_config.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/core/router/routing_controller.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../features/auth/auth_fixture.dart';

class MemoryConfigCache implements ConfigCache {
  AppConfig? value;
  @override
  Future<AppConfig?> read(String origin) async => value;
  @override
  Future<void> write(String origin, AppConfig config) async {
    value = config;
  }
}

class TestAppInfo extends AndroidAppInfo {
  int opens = 0;
  @override
  Future<String> version() async => '0.1.0';
  @override
  Future<bool> openStore() async {
    opens++;
    return false;
  }
}

class ConfigFixture implements HttpClientAdapter {
  bool offline = false;
  String minimum = '0.1.0';
  final calls = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    calls.add(options);
    if (offline) {
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    }
    return ResponseBody.fromString(
        jsonEncode({
          'minVersionAndroid': minimum,
          'flags': {'operationalNotice': true}
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() async {
    for (final delegate in SbLocalizations.delegates) {
      await delegate.load(const Locale('en'));
    }
  });
  test('FR-408 numeric comparison, strict parsing and flags default off', () {
    expect(isOlderVersion('0.9.9', '0.10.0'), isTrue);
    expect(isOlderVersion('1.0.0', '0.99.0'), isFalse);
    expect(isOlderVersion('0.1.0', '0.1.0'), isFalse);
    for (final value in ['', '01.0.0', '1.0', '1.0.0-beta', '9999999.0.0']) {
      expect(() => isOlderVersion(value, '0.1.0'), throwsFormatException);
    }
    expect(AppConfig('0.1.0', {}).enabled('unknown'), isFalse);
    expect(
        () => AppConfig.fromJson({
              'minVersionAndroid': '0.1.0',
              'flags': {'test': 'true'}
            }),
        throwsA(isA<TypeError>()));
  });
  test(
      'FR-408 live policy persists, offline cache retains force-update; no-cache fails closed',
      () async {
    final api = ConfigFixture()..minimum = '0.2.0';
    final cache = MemoryConfigCache();
    ProviderContainer container() => ProviderContainer(overrides: [
          authConfigProvider.overrideWithValue(testAuthConfig),
          configCacheProvider.overrideWithValue(cache),
          configAdapterProvider.overrideWithValue(api),
          androidAppInfoProvider.overrideWithValue(TestAppInfo())
        ]);
    var scope = container();
    await scope.read(configProvider.notifier).load();
    expect(scope.read(configProvider).forceUpdate, isTrue);
    expect(
        scope.read(configProvider).value!.enabled('operationalNotice'), isTrue);
    expect(api.calls.single.uri.path, '/api/v1/config');
    expect(api.calls.single.headers.containsKey('Authorization'), isFalse);
    scope.dispose();
    api.offline = true;
    scope = container();
    await scope.read(configProvider.notifier).load();
    expect(scope.read(configProvider).forceUpdate, isTrue);
    expect(scope.read(configProvider).offline, isTrue);
    scope.dispose();
    cache.value = null;
    scope = container();
    await scope.read(configProvider.notifier).load();
    expect(scope.read(configProvider).ready, isFalse);
    scope.dispose();
  });
  test(
      'FR-408 HTTP 426 holds a gate even with a cached supported policy and offline refresh',
      () async {
    final api = ConfigFixture();
    final scope = ProviderContainer(overrides: [
      authConfigProvider.overrideWithValue(testAuthConfig),
      configCacheProvider.overrideWithValue(MemoryConfigCache()),
      configAdapterProvider.overrideWithValue(api),
      androidAppInfoProvider.overrideWithValue(TestAppInfo())
    ]);
    addTearDown(scope.dispose);
    await scope.read(configProvider.notifier).load();
    api.offline = true;
    await scope.read(configProvider.notifier).requireUpdate();
    expect(scope.read(configProvider).forceUpdate, isTrue);
    api.offline = false;
    await scope.read(configProvider.notifier).load();
    expect(scope.read(configProvider).forceUpdate, isFalse);
  });
  testWidgets(
      'FR-408 S-COM-06 blocks session/logout/deep links; store failure, Android semantics and 200% scale',
      (tester) async {
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();
    final api = ConfigFixture()..minimum = '0.2.0';
    final info = TestAppInfo();
    final routing = RoutingController();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authConfigProvider.overrideWithValue(testAuthConfig),
          authStorageProvider.overrideWithValue(MemoryAuthStorage()),
          authAdapterProvider.overrideWithValue(AuthFixture()),
          configCacheProvider.overrideWithValue(MemoryConfigCache()),
          configAdapterProvider.overrideWithValue(api),
          androidAppInfoProvider.overrideWithValue(info)
        ],
        child: SupplyBizApp(
            environment: AppEnvironment.dev,
            routingController: routing,
            enableAuth: true,
            enableConfig: true)));
    await tester.pumpAndSettle();
    expect(find.text('Update Supply Biz to continue.'), findsOneWidget);
    expect(routing.access.forceUpdate, isTrue);
    routing.openLink('supplybiz://o/11111111-1111-4111-8111-111111111111');
    await tester.pumpAndSettle();
    expect(find.text('Update Supply Biz to continue.'), findsOneWidget);
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(info.opens, 1);
    expect(
        find.textContaining('The store could not be opened'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(tester.takeException(), isNull);
    api.minimum = '0.1.0';
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(routing.access.forceUpdate, isFalse);
    await tester.pumpWidget(const SizedBox());
    routing.dispose();
    semantics.dispose();
  });
  testWidgets('TC-407 active app refreshes policy within five minutes',
      (tester) async {
    final api = ConfigFixture();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authConfigProvider.overrideWithValue(testAuthConfig),
          configCacheProvider.overrideWithValue(MemoryConfigCache()),
          configAdapterProvider.overrideWithValue(api),
          androidAppInfoProvider.overrideWithValue(TestAppInfo())
        ],
        child: const SupplyBizApp(
            environment: AppEnvironment.dev, enableConfig: true)));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    api.minimum = '0.2.0';
    await tester.pump(const Duration(minutes: 4));
    await tester.pumpAndSettle();
    expect(find.text('Update Supply Biz to continue.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('FR-408 no-cache offline startup offers retry and recovers',
      (tester) async {
    final api = ConfigFixture()..offline = true;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authConfigProvider.overrideWithValue(testAuthConfig),
          configCacheProvider.overrideWithValue(MemoryConfigCache()),
          configAdapterProvider.overrideWithValue(api),
          androidAppInfoProvider.overrideWithValue(TestAppInfo())
        ],
        child: const SupplyBizApp(
            environment: AppEnvironment.dev, enableConfig: true)));
    await tester.pumpAndSettle();
    expect(find.textContaining('App configuration is unavailable'),
        findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    api.offline = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
