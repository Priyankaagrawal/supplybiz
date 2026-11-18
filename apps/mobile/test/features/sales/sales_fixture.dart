// Simulated API only; T-079 records separate native financial evidence.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../products/catalog_fixture.dart' show productJson, syntheticProductId;
import '../customers/customer_fixture.dart' show customerJson;

class SalesFixture implements HttpClientAdapter {
  final products = <Map<String, dynamic>>[productJson()],
      customers = <Map<String, dynamic>>[customerJson()];
  final calls = <RequestOptions>[], writes = <RequestOptions>[];
  final replays = <String, Map<String, dynamic>>{};
  int commits = 0;
  bool offline = false, loseResponse = false;
  int? denial, rejection;
  String rejectionCode = 'INSUFFICIENT_STOCK';
  Completer<void>? gate, committed, release;
  void Function()? afterCommit;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    if (o.method == 'POST') writes.add(o);
    ResponseBody json(Object body, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(body), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (offline) {
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    if (denial != null) return json({'code': 'VENDOR_ROLE_REQUIRED'}, denial!);
    if (o.method == 'GET') {
      await gate?.future;
      final offset = int.parse('${o.queryParameters['offset'] ?? 0}'),
          limit = int.parse('${o.queryParameters['limit'] ?? 50}'),
          rows = o.uri.path.endsWith('/products') ? products : customers;
      return json({
        'items': rows.skip(offset).take(limit).toList(),
        'total': rows.length,
        'activeCount': customers.length,
        'customerLimit': 1000
      });
    }
    if (rejection != null) return json({'code': rejectionCode}, rejection!);
    final key = o.headers['Idempotency-Key'] as String;
    if (replays[key] != null) return json(replays[key]!);
    final body = Map<String, dynamic>.from(jsonDecode(o.data as String) as Map),
        items = body['items'] as List;
    final total = items.fold<BigInt>(
            BigInt.zero,
            (n, i) =>
                n +
                BigInt.parse(i['ratePaise'] as String) *
                    BigInt.from(i['qty'] as int)),
        paid = BigInt.parse(body['paidPaise'] as String);
    final record = <String, dynamic>{
      'id':
          '22222222-2222-4222-8222-${(commits + 1).toString().padLeft(12, '0')}',
      'saleNo': 'SALE${commits + 1}',
      'vendorCustomerId': body['vendorCustomerId'],
      'totalPaise': total.toString(),
      'paidPaise': paid.toString(),
      'balancePaise': (total - paid).toString(),
      'paymentStatus': total == paid ? 'PAID' : 'UNPAID',
      'paymentMethod': body['paymentMethod'],
      'businessDate': '2026-11-18',
      'createdAt': '2026-11-18T04:00:00Z',
      'clientCreatedAt': body['clientCreatedAt'],
      'items': [
        for (final i in items)
          {
            'productId': i['productId'],
            'name':
                products.where((p) => p['id'] == i['productId']).first['name'],
            'unitValue': '1',
            'unitType': 'L',
            'qty': i['qty'],
            'ratePaise': i['ratePaise'],
            'amountPaise': (BigInt.parse(i['ratePaise'] as String) *
                    BigInt.from(i['qty'] as int))
                .toString()
          }
      ]
    };
    for (final i in items) {
      final p = products.where((p) => p['id'] == i['productId']).first;
      p['stockQty'] = (p['stockQty'] as int) - (i['qty'] as int);
    }
    commits++;
    replays[key] = record;
    afterCommit?.call();
    committed?.complete();
    if (release != null) await release!.future;
    if (loseResponse) {
      loseResponse = false;
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    return json(record, 201);
  }
}

List<Map<String, dynamic>> saleItems({int qty = 1, String rate = '6010'}) => [
      {'productId': syntheticProductId, 'qty': qty, 'ratePaise': rate}
    ];
