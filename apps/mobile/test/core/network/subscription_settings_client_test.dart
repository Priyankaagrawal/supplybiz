// T-075: the generated Dart client can express explicit nullable clears.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';

class SettingsAdapter implements HttpClientAdapter {
  RequestOptions? request;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    request = options;
    return ResponseBody.fromString(
        jsonEncode({
          'version': 2,
          'serverTime': '2026-11-16T00:00:00Z',
          'businessDate': '2026-11-16',
          'autoAcceptSubscriptions': false,
          'effectiveAutoAcceptSubscriptions': false,
          'canAutoAccept': false,
          'canEditSubscriptions': true,
          'canReduceActivity': true,
          'deliveryAvailable': true,
          'deliveryStartTime': null,
          'deliveryEndTime': null,
          'maxDailyOrders': null,
          'dailyMilkCapacityLitres': null,
          'pauseAllSubscriptions': false,
          'summary': {
            'totalSubscriptions': 0,
            'active': 0,
            'paused': 0,
            'pendingApproval': 0,
            'cancelled': 0,
            'rejected': 0,
            'completed': 0,
            'subscriptionCustomers': 0
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }
}

void main() {
  test(
      'T-075 typed PATCH sends all clear flags, version and retry key; nullable response decodes',
      () async {
    final adapter = SettingsAdapter(),
        dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    final response = await VendorSubscriptionSettingsApi(dio)
        .subscriptionSettingsControllerPatch(
            idempotencyKey: 'synthetic-settings-key',
            subscriptionSettingsPatch: SubscriptionSettingsPatch(
                version: 1,
                clearDeliveryWindow: true,
                clearMaxDailyOrders: true,
                clearDailyMilkCapacity: true));
    final request = adapter.request!;
    expect(request.uri.path, '/api/v1/vendor/settings');
    expect(request.method, 'PATCH');
    expect(request.headers['Idempotency-Key'], 'synthetic-settings-key');
    expect(jsonDecode(request.data as String), {
      'version': 1,
      'clearDeliveryWindow': true,
      'clearMaxDailyOrders': true,
      'clearDailyMilkCapacity': true,
    });
    expect(response.data!.version, 2);
    expect(response.data!.dailyMilkCapacityLitres, isNull);
    expect(response.data!.deliveryStartTime, isNull);
    expect(response.data!.maxDailyOrders, isNull);
  });
}
