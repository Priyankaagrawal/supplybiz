// T-100 generated transport only; native SQL/financial evidence is separate.
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';

class ReportsAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    final range = {
      'from': '2026-01-01',
      'to': '2026-03-05',
      'serverTime': '2026-11-19T01:00:00Z',
      'businessDate': '2026-11-19'
    };
    final Map<String, dynamic> body;
    if (o.path.endsWith('/summary')) {
      body = {
        ...range,
        'totalSalesPaise': '9007199254740993',
        'totalOrders': 5,
        'deliveredOrders': 3,
        'cancelledOrders': 1,
        'milkSoldLitres': '123456789012345.123456',
        'milkSoldUnmeasuredLines': 1,
        'totalEarningsPaise': '-9007199254740993',
        'pendingPaymentsPaise': '5000',
        'activeCustomers': 2,
        'productSalesPaise': '9007199254740843',
        'deliveryChargesPaise': '150',
        'discountPaise': '0',
        'unitemizedSalesPaise': '0'
      };
    } else if (o.path.endsWith('/sales-daily')) {
      body = {
        ...range,
        'bucket': 'WEEK',
        'items': [
          {
            'from': '2026-01-01',
            'to': '2026-01-04',
            'salesPaise': '9007199254740993'
          }
        ]
      };
    } else {
      body = {
        ...range,
        'total': 2,
        'totalProductSalesPaise': '9007199254740843',
        'items': [
          {
            'productId': '11111111-1111-4111-8111-111111111111',
            'name': 'Synthetic frozen name',
            'unitValue': '500',
            'unitType': 'ML',
            'quantityPacks': '9007199254740993',
            'salesPaise': '9007199254740843'
          }
        ]
      };
    }
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }
}

void main() {
  test(
      'T-100 report client preserves signed receipt/large paise, exact milk and packs, calendar range, buckets and pagination',
      () async {
    final f = ReportsAdapter(),
        dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = f;
    addTearDown(() => dio.close(force: true));
    final api = VendorReportsApi(dio);
    final s = (await api.reportsControllerSummary(
            from: '2026-01-01', to: '2026-03-05'))
        .data!;
    expect(s.totalSalesPaise, '9007199254740993');
    expect(s.totalEarningsPaise, '-9007199254740993');
    expect(s.milkSoldLitres, '123456789012345.123456');
    expect(s.milkSoldUnmeasuredLines, 1);
    expect(s.from, DateTime(2026, 1, 1));
    expect(f.calls.last.queryParameters,
        {'from': '2026-01-01', 'to': '2026-03-05'});
    final d =
        (await api.reportsControllerDaily(from: '2026-01-01', to: '2026-03-05'))
            .data!;
    expect(d.bucket.value, 'WEEK');
    expect(d.items.single.to, DateTime(2026, 1, 4));
    expect(d.items.single.salesPaise, s.totalSalesPaise);
    final p = (await api.reportsControllerProducts(
            from: '2026-01-01', to: '2026-03-05', limit: 1, offset: 1))
        .data!;
    expect(p.items.single.quantityPacks, '9007199254740993');
    expect(p.totalProductSalesPaise, s.productSalesPaise);
    expect(p.total, 2);
    expect(f.calls.last.queryParameters,
        {'from': '2026-01-01', 'to': '2026-03-05', 'limit': 1, 'offset': 1});
    await api.reportsControllerSummary();
    expect(f.calls.last.queryParameters, isEmpty);
    expect(f.calls.every((c) => c.method == 'GET'), isTrue);
  });
}
