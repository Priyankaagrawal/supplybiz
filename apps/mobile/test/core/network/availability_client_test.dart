// T-074: generated client wire compatibility; simulated transport only.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';

const holidayId = '11111111-1111-4111-8111-111111111111';

class AvailabilityAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  final record = {
    'id': holidayId,
    'date': '2026-11-18',
    'reason': 'Synthetic holiday'
  };
  final state = {
    'version': 2,
    'acceptingToday': false,
    'deliveryPaused': true,
    'deliveryPausedUntil': null,
    'canResume': true,
    'canReduceActivity': true,
    'serverTime': '2026-11-17T04:00:00Z',
    'businessDate': '2026-11-17'
  };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    final Object body;
    if (o.method == 'POST') {
      body = {'holiday': record, 'cancelledOrders': 2};
    } else if (o.method == 'DELETE') {
      body = {'id': holidayId, 'deleted': true};
    } else if (o.method == 'PATCH') {
      body = {'availability': state, 'cancelledOrders': 3};
    } else if (o.uri.path.endsWith('/impact')) {
      body = {
        'affectedOrders': 2,
        'serverTime': state['serverTime'],
        'businessDate': state['businessDate']
      };
    } else if (o.uri.path.endsWith('/holidays')) {
      body = {
        'items': [record],
        'total': 1,
        'serverTime': state['serverTime'],
        'businessDate': state['businessDate']
      };
    } else {
      body = state;
    }
    return ResponseBody.fromString(
        jsonEncode(body), o.method == 'POST' ? 201 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }
}

void main() {
  test(
      'T-074 generated holiday date stays date-only in body/query; replay/version paths and nullable state decode',
      () async {
    final adapter = AvailabilityAdapter(),
        dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    final api = VendorAvailabilityApi(dio);
    expect(
        (await api.availabilityControllerCreate(
                idempotencyKey: 'synthetic-create',
                holidayInput: HolidayInput(
                    date: '2026-11-18', reason: 'Synthetic holiday')))
            .data!
            .cancelledOrders,
        2);
    expect(jsonDecode(adapter.calls.last.data as String),
        {'date': '2026-11-18', 'reason': 'Synthetic holiday'});
    expect(adapter.calls.last.headers['Idempotency-Key'], 'synthetic-create');
    await api.availabilityControllerImpact(date: '2026-11-18');
    expect(adapter.calls.last.queryParameters['date'], '2026-11-18');
    expect((await api.availabilityControllerPauseImpact()).data!.affectedOrders,
        2);
    expect(
        (await api.availabilityControllerList(limit: 1, offset: 0))
            .data!
            .items
            .single
            .id,
        holidayId);
    expect((await api.availabilityControllerGet()).data!.deliveryPausedUntil,
        isNull);
    final patch = (await api.availabilityControllerPatch(
            idempotencyKey: 'synthetic-patch',
            availabilityPatch:
                AvailabilityPatch(version: 1, deliveryPaused: true)))
        .data!;
    expect(patch.availability.version, 2);
    expect(jsonDecode(adapter.calls.last.data as String),
        {'version': 1, 'deliveryPaused': true});
    expect(
        (await api.availabilityControllerDelete(
                idempotencyKey: 'synthetic-delete', id: holidayId))
            .data!
            .deleted,
        true);
    expect(adapter.calls.last.uri.path, '/api/v1/vendor/holidays/$holidayId');
    expect(adapter.calls.last.headers['Idempotency-Key'], 'synthetic-delete');
  });
}
