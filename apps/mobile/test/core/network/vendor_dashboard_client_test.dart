// T-030 generated transport only. Real metric correctness is tested on PostgreSQL.
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';

class DashboardAdapter implements HttpClientAdapter {
  RequestOptions? request;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromString(
        jsonEncode({
          'serverTime': '2026-11-19T01:00:00Z',
          'businessDate': '2026-11-19',
          'date': '2026-02-01',
          'shopName': null,
          'city': null,
          'shopPhotoMediaId': null,
          'verified': false,
          'todayOrders': 5,
          'pendingOrders': 2,
          'completedOrders': 3,
          'todaySalesPaise': '9007199254740993',
          'totalEarningsPaise': '18014398509481986',
          'milkStockLitres': '2147483646997852520.353001',
          'milkStockUnmeasuredProducts': 1,
          'activeCustomers': 4
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }
}

void main() {
  test(
      'T-030 generated dashboard preserves selected calendar date, exact money/stock and nullable header',
      () async {
    final f = DashboardAdapter(),
        dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = f;
    addTearDown(() => dio.close(force: true));
    final api = VendorDashboardApi(dio);
    final v =
        (await api.vendorDashboardControllerGet(date: '2026-02-01')).data!;
    expect(f.request!.method, 'GET');
    expect(f.request!.path, '/api/v1/vendor/dashboard');
    expect(f.request!.queryParameters, {'date': '2026-02-01'});
    expect(v.date, DateTime(2026, 2, 1));
    expect(v.todaySalesPaise, '9007199254740993');
    expect(v.totalEarningsPaise, '18014398509481986');
    expect(v.milkStockLitres, '2147483646997852520.353001');
    expect(v.shopName, isNull);
    expect(v.shopPhotoMediaId, isNull);
    expect(v.milkStockUnmeasuredProducts, 1);
    await api.vendorDashboardControllerGet();
    expect(f.request!.queryParameters, isEmpty);
  });
}
