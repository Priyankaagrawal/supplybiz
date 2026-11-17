// T-079: generated client transport only, not live API/DB or offline UI proof.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';

const saleId = '11111111-1111-4111-8111-111111111111';

class SalesAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  final record = <String, dynamic>{
    'id': saleId,
    'saleNo': 'SALE00000001',
    'vendorCustomerId': null,
    'totalPaise': '9007199254740993',
    'paidPaise': '9007199254740993',
    'balancePaise': '0',
    'paymentStatus': 'PAID',
    'paymentMethod': 'OTHER',
    'businessDate': '2026-11-17',
    'createdAt': '2026-11-17T04:00:00Z',
    'clientCreatedAt': null,
    'items': [
      {
        'productId': saleId,
        'name': 'Synthetic milk',
        'unitValue': '1',
        'unitType': 'L',
        'qty': 1,
        'ratePaise': '9007199254740993',
        'amountPaise': '9007199254740993'
      }
    ]
  };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    final body = o.method == 'GET' && o.uri.path.endsWith('/sales')
        ? {
            'items': [record],
            'total': 1,
            'serverTime': '2026-11-17T04:00:00Z',
            'businessDate': '2026-11-17'
          }
        : record;
    return ResponseBody.fromString(
        jsonEncode(body), o.method == 'POST' ? 201 : 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }
}

void main() {
  test(
      'T-079 generated sale request preserves huge paise, explicit Other, stable retry identity, nullable walk-in and date query',
      () async {
    final f = SalesAdapter(),
        dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = f;
    addTearDown(() => dio.close(force: true));
    final api = VendorSalesApi(dio);
    final body = CompleteSaleInput(
        items: [
          SaleLineInput(
              productId: saleId, qty: 1, ratePaise: '9007199254740993')
        ],
        paidPaise: '9007199254740993',
        paymentMethod: CompleteSaleInputPaymentMethodEnum.OTHER,
        clientCreatedAt: DateTime.parse('2000-01-01T00:00:00Z'));
    for (var i = 0; i < 2; i++) {
      final row = (await api.salesControllerComplete(
              idempotencyKey: 'synthetic-stable-sale', completeSaleInput: body))
          .data!;
      expect(row.totalPaise, '9007199254740993');
      expect(row.vendorCustomerId, isNull);
      expect(row.items.single.ratePaise, '9007199254740993');
    }
    expect(f.calls[0].data, f.calls[1].data);
    expect(f.calls.last.headers['Idempotency-Key'], 'synthetic-stable-sale');
    final wire = jsonDecode(f.calls.last.data as String) as Map;
    expect(wire['paidPaise'], '9007199254740993');
    expect(wire['paymentMethod'], 'OTHER');
    expect(wire['clientCreatedAt'], '2000-01-01T00:00:00.000Z');
    expect(wire.containsKey('vendorCustomerId'), isFalse);
    expect(wire.containsKey('totalPaise'), isFalse);
    expect(
        (await api.salesControllerList(date: '2026-11-17', limit: 1, offset: 0))
            .data!
            .items
            .single
            .id,
        saleId);
    expect(f.calls.last.queryParameters['date'], '2026-11-17');
    expect((await api.salesControllerGet(id: saleId)).data!.id, saleId);
    expect(f.calls.last.uri.path, '/api/v1/vendor/sales/$saleId');
  });
}
