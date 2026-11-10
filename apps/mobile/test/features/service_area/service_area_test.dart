import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/app_failure.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/storage/device_location.dart';
import 'package:supplybiz_mobile/features/service_area/service_area_controller.dart';
import 'package:supplybiz_mobile/features/service_area/service_area_page.dart';

import '../onboarding/onboarding_test.dart'
    show MemoryDrafts, OnboardingFixture, TestSession;

class AreaApi extends OnboardingFixture {
  int failures = 0;
  bool forbid = false;
  int? radius;
  List<String> pincodes = [];
  @override
  Map<String, dynamic> get profile {
    final result = super.profile;
    result['shopPhotoMediaId'] = '11111111-1111-4111-8111-111111111111';
    (result['settings'] as Map<String, dynamic>)
      ..['serviceRadiusKm'] = radius
      ..['pincodes'] = pincodes;
    return result;
  }

  final writes = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    if (options.method == 'PUT') {
      writes.add(options);
      if (failures-- > 0) {
        throw DioException(
            requestOptions: options, type: DioExceptionType.connectionError);
      }
      if (forbid) {
        return ResponseBody.fromString(
            jsonEncode({'code': 'REVERIFICATION_REQUIRED'}), 409,
            headers: {
              Headers.contentTypeHeader: ['application/json']
            });
      }
      if (options.uri.path.endsWith('/service-area')) {
        final body = jsonDecode(options.data as String) as Map<String, dynamic>;
        radius = body['serviceRadiusKm'] as int?;
        pincodes = (body['pincodes'] as List<dynamic>).cast<String>();
      }
    }
    return super.fetch(options, stream, cancel);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'TC-028 radius/pincode boundaries, duplicates, invalid and empty coverage',
      () {
    for (final radius in ['1', '20', '']) {
      expect(validCoverage(radius, '110001, 560001'), isTrue);
    }
    expect(validCoverage('1', ''), isTrue);
    for (final radius in ['0', '21', '1.5', 'NaN']) {
      expect(validCoverage(radius, '110001'), isFalse);
    }
    for (final codes in ['', '000001', '11000', '110001,110001', 'abcdef']) {
      expect(validCoverage('', codes), isFalse);
    }
  });

  test(
      'TC-028 interrupted coverage retry retains encrypted key across controller recreation; changed request gets new key',
      () async {
    final api = AreaApi()..step = 4;
    final drafts = MemoryDrafts();
    ServiceAreaController make() => ServiceAreaController(
        NetworkClient(
            baseUrl: 'https://api.example.test',
            session: TestSession(),
            adapter: api,
            delay: (_) async {}),
        drafts,
        'test-user:area');
    var model = make();
    await model.load();
    api.failures = 20;
    await model.saveCoverage(5, ['110001']);
    expect(model.failure, isA<NetworkFailure>());
    final key = api.writes.first.headers['Idempotency-Key'];
    expect(key, isNotEmpty);
    model.dispose();
    model = make();
    await model.load();
    expect(model.pendingFields, {'radius': '5', 'pincodes': '110001'});
    api.failures = 0;
    await model.saveCoverage(5, ['110001']);
    expect(model.saved, isTrue);
    expect(api.writes.last.headers['Idempotency-Key'], key);
    await model.saveCoverage(6, ['110001']);
    expect(api.writes.last.headers['Idempotency-Key'], isNot(key));
    expect(jsonDecode(api.writes.last.data as String), {
      'serviceRadiusKm': 6,
      'pincodes': ['110001']
    });
    expect(drafts.rows['test-user:area'], isEmpty);
    await model.load();
    expect(model.profile?.settings.serviceRadiusKm, 6);
    expect(model.profile?.settings.pincodes, ['110001']);
    model.dispose();
  });

  test(
      'TC-028 location preserves business and owned photo; server re-verification denial is surfaced',
      () async {
    final api = AreaApi()..step = 4;
    final model = ServiceAreaController(
        NetworkClient(
            baseUrl: 'https://api.example.test',
            session: TestSession(),
            adapter: api),
        MemoryDrafts(),
        'owner');
    await model.load();
    api.forbid = true;
    await model.saveLocation(
        address: 'Synthetic new address',
        city: 'Test city',
        state: 'Test state',
        pincode: '110001',
        latitude: 28.7,
        longitude: 77.3);
    expect(model.failure, isA<ConflictFailure>());
    expect(model.failure?.code, 'REVERIFICATION_REQUIRED');
    expect(model.saved, isFalse);
    final body = jsonDecode(api.writes.single.data as String) as Map;
    expect(body['businessName'], 'Synthetic shop');
    expect(body['latitude'], 28.7);
    expect(body['shopPhotoMediaId'], '11111111-1111-4111-8111-111111111111');
    expect(body.containsKey('vendorId'), isFalse);
    model.dispose();
  });

  testWidgets(
      'TC-028 form at 200% text: GPS denial keeps manual fields; invalid coverage cannot mutate',
      (tester) async {
    final api = AreaApi()..step = 4;
    final model = ServiceAreaController(
        NetworkClient(
            baseUrl: 'https://api.example.test',
            session: TestSession(),
            adapter: api),
        MemoryDrafts(),
        'owner');
    await tester.runAsync(model.load);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceLocation.channel,
            (_) async => throw PlatformException(code: 'LOCATION_DENIED'));
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DeviceLocation.channel, null);
    });
    await tester.pumpWidget(ProviderScope(
        overrides: [serviceAreaProvider.overrideWith((ref) => model)],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!),
            home: const ServiceAreaPage())));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Use current location'));
    await tester.tap(find.text('Use current location'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Location unavailable'), findsOneWidget);
    await tester.ensureVisible(find.text('Save coverage'));
    await tester.tap(find.text('Save coverage'));
    await tester.pumpAndSettle();
    expect(api.writes, isEmpty);
    expect(find.textContaining('Use a radius from'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
