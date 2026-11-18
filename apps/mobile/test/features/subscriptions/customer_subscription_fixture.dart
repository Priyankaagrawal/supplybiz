// T-078: simulated HTTP; actual ledger evidence is in native PostgreSQL tests.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../addresses/address_fixture.dart' show addressJson;
import '../products/catalog_fixture.dart' show syntheticProductId;
import 'subscription_fixture.dart'
    show SubscriptionFixture, subscriptionJson, subscriptionId;

class CustomerSubscriptionFixture extends SubscriptionFixture {
  bool published = false;
  int? readDenial;
  int deliveredTotal = 2;
  Map<String, dynamic> get plans => {
        'items': [
          for (final kind in ['CUSTOM', '1000_ML_DAILY'])
            {
              'productId': syntheticProductId,
              'productName': 'Synthetic Cow Milk',
              'kind': kind,
              'qty': 1,
              'dailyAmountPaise': '5500',
              'monthlyEstimatePaise': '71500',
              'mostPopular': null,
            }
        ],
        'timeSlots': ['AM', 'PM'],
        'freeDelivery': true,
        'earliestStartDate': '2026-11-18',
        'estimateMonth': '2026-11'
      };
  Map<String, dynamic> statement(int offset, int limit) => {
        'subscriptionId': subscriptionId,
        'month': '2026-11',
        'total': deliveredTotal,
        'deliveredAmountPaise': '11000',
        'deliveredQty': '2',
        'items': [
          for (var i = offset; i < deliveredTotal && i < offset + limit; i++)
            {
              'orderId': subscriptionId,
              'deliveryDate':
                  '2026-11-${(i % 28 + 1).toString().padLeft(2, '0')}',
              'productName': 'Synthetic frozen milk',
              'qty': 1,
              'amountPaise': '5500',
              'paymentStatus': 'UNPAID'
            }
        ],
        'ledger': {
          'vendorId': syntheticProductId,
          'vendorName': 'Synthetic vendor',
          'month': '2026-11',
          'duePaise': '9007199254740993',
          'openingDuePaise': '9007199254730993',
          'closingDuePaise': '9007199254740993',
          'monthDebitPaise': '11000',
          'monthCreditPaise': '1000',
          'monthPaidPaise': '1000',
          'accounts': [],
          'items': [],
          'total': 0,
          'serverTime': '2026-11-17T04:00:00Z',
          'businessDate': '2026-11-17'
        }
      };
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    ResponseBody json(Object body, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(body), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (o.method == 'GET') {
      if (offline) {
        throw DioException(
            requestOptions: o, type: DioExceptionType.connectionError);
      }
      if (readDenial != null) {
        return json({'code': 'SUBSCRIPTION_NOT_FOUND'}, readDenial!);
      }
      final path = o.uri.path;
      if (path.endsWith('/addresses')) {
        return json({
          'items': [addressJson()]
        });
      }
      if (path.endsWith('/subscription-plans')) return json(plans);
      if (path.endsWith('/settlement-options')) {
        return json({
          'vendorId': syntheticProductId,
          'payeeName': 'Synthetic vendor',
          'upiId': published ? 'synthetic.pay@okbank' : null,
          'upiAvailable': published,
          'cashAvailable': true,
          'duePaise': '1000',
          'accounts': []
        });
      }
      if (path.endsWith('/statement')) {
        calls.add(o);
        return json(statement(int.parse('${o.queryParameters['offset'] ?? 0}'),
            int.parse('${o.queryParameters['limit'] ?? 50}')));
      }
      if (RegExp(r'/customer/subscriptions/[0-9a-f-]{36}$').hasMatch(path)) {
        calls.add(o);
        return json(
            rows.where((r) => r['id'] == path.split('/').last).firstOrNull ??
                subscriptionJson());
      }
    }
    return super.fetch(o, stream, cancel);
  }
}
