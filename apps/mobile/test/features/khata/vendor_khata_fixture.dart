// T-081 simulated transport; native PostgreSQL money evidence is separate.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

const vendorAccountId = '11111111-1111-4111-8111-111111111111';
const vendorClaimId = '22222222-2222-4222-8222-222222222222';
Map<String, dynamic> vendorAccount(
        {String id = vendorAccountId, String due = '10000'}) =>
    {
      'id': id,
      'name': 'Synthetic Khata customer',
      'mobile': '+919000000000',
      'status': 'ACTIVE',
      'archived': false,
      'totalDebitPaise': '10000',
      'totalCreditPaise': '0',
      'totalPaidPaise': '0',
      'duePaise': due
    };

class VendorKhataFixture implements HttpClientAdapter {
  final rows = <Map<String, dynamic>>[vendorAccount()];
  final claims = <Map<String, dynamic>>[
    {
      'id': vendorClaimId,
      'vendorId': vendorAccountId,
      'vendorCustomerId': vendorAccountId,
      'amountPaise': '1000',
      'method': 'CASH',
      'upiTxnRef': null,
      'status': 'PENDING',
      'version': 1,
      'createdAt': '2026-11-18T04:00:00Z',
      'decidedAt': null,
      'rejectReason': null
    }
  ];
  final calls = <RequestOptions>[], writes = <RequestOptions>[];
  final replay = <String, Map<String, dynamic>>{};
  bool offline = false, loseResponse = false, canAdjust = true, canPay = true;
  int commits = 0, entryTotal = 1, collectionTotal = 1;
  int? denial, rejection;
  String rejectionCode = 'VERSION_CONFLICT';
  void Function()? afterCommit;
  Map<String, dynamic> entry(int i, String id) => {
        'id': '${i.toString().padLeft(8, '0')}-3333-4333-8333-333333333333',
        'vendorCustomerId': id,
        'type': 'DEBIT',
        'amountPaise': '10000',
        'entryDate': '2026-11-18',
        'refType': 'OPENING',
        'refId': vendorAccountId,
        'reversesEntryId': null,
        'note': 'Synthetic opening',
        'productSummary': null,
        'paymentStatus': null
      };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    ResponseBody json(Object body, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(body), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (offline) {
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    if (denial != null) return json({'code': 'VENDOR_ROLE_REQUIRED'}, denial!);
    final path = o.uri.path,
        offset = int.parse('${o.queryParameters['offset'] ?? 0}'),
        limit = int.parse('${o.queryParameters['limit'] ?? 50}'),
        month = o.queryParameters['month'] ?? '2026-11';
    if (o.method == 'GET') {
      if (path.endsWith('/khata')) {
        return json({
          'items': rows.skip(offset).take(limit).toList(),
          'total': rows.length,
          'totalReceivablePaise': '9007199254740993',
          'thisMonthReceivedPaise': '1000',
          'canAdjust': canAdjust,
          'canRecordPayment': canPay,
          'serverTime': '2026-11-18T04:00:00Z',
          'businessDate': '2026-11-18'
        });
      }
      if (path.endsWith('/collections')) {
        return json({
          'items': [
            for (var i = offset; i < collectionTotal && i < offset + limit; i++)
              {
                'id':
                    '${i.toString().padLeft(8, '0')}-4444-4444-8444-444444444444',
                'vendorCustomerId': vendorAccountId,
                'customerName': 'Synthetic Khata customer',
                'amountPaise': i.isEven ? '1000' : '-1000',
                'method': 'CASH',
                'entryDate': '2026-11-18',
                'createdAt': '2026-11-18T04:00:00Z',
                'reversal': i.isOdd,
                'source': 'PAYMENT'
              }
          ],
          'total': collectionTotal,
          'month': month
        });
      }
      if (path.endsWith('/payment-claims')) {
        final selected = claims
            .where((c) =>
                c['status'] == (o.queryParameters['status'] ?? 'PENDING'))
            .toList();
        return json({
          'items': selected.skip(offset).take(limit).toList(),
          'total': selected.length
        });
      }
      final id = path.split('/')[5];
      return json({
        'vendorId': vendorAccountId,
        'vendorName': 'Synthetic vendor',
        'month': month,
        'duePaise': rows.first['duePaise'],
        'openingDuePaise': '0',
        'closingDuePaise': rows.first['duePaise'],
        'monthDebitPaise': '10000',
        'monthCreditPaise': '0',
        'monthPaidPaise': '1000',
        'accounts': [
          {
            'vendorCustomerId': id,
            'duePaise': rows.first['duePaise'],
            'maxClaimPaise': '10000',
            'canClaim': true
          }
        ],
        'items': [
          for (var i = offset; i < entryTotal && i < offset + limit; i++)
            entry(i, id)
        ],
        'total': entryTotal,
        'serverTime': '2026-11-18T04:00:00Z',
        'businessDate': '2026-11-18'
      });
    }
    writes.add(o);
    if (rejection != null) return json({'code': rejectionCode}, rejection!);
    final key = o.headers['Idempotency-Key'] as String;
    if (replay[key] != null) return json(replay[key]!, 201);
    final body = Map<String, dynamic>.from(jsonDecode(o.data as String) as Map);
    Map<String, dynamic> ack;
    if (path.endsWith('/payments')) {
      ack = {
        'id': vendorClaimId,
        'vendorCustomerId': body['vendorCustomerId'],
        'orderId': null,
        'amountPaise': body['amountPaise'],
        'method': body['method'],
        'receivedOn': body['receivedOn'],
        'note': body['note'] ?? '',
        'createdAt': '2026-11-18T04:00:00Z'
      };
    } else if (path.endsWith('/confirm') || path.endsWith('/reject')) {
      final c = claims.first;
      c['status'] = path.endsWith('/confirm') ? 'CONFIRMED' : 'REJECTED';
      c['version'] = (c['version'] as int) + 1;
      c['rejectReason'] = body['reason'];
      ack = {'id': c['id'], 'status': c['status'], 'version': c['version']};
    } else {
      ack = {'id': vendorClaimId};
    }
    commits++;
    replay[key] = ack;
    afterCommit?.call();
    if (loseResponse) {
      loseResponse = false;
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    return json(ack, 201);
  }
}
