// T-083 simulated HTTP only; does not assert actual vendor ledger writes.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:supplybiz_mobile/features/khata/upi_device.dart';

const khataVendor = '11111111-1111-4111-8111-111111111111';
const khataContact = '22222222-2222-4222-8222-222222222222';
const khataEntry = '33333333-3333-4333-8333-333333333333';

class TestUpi extends UpiDevice {
  final opened = <Uri>[];
  bool handled = true;
  Future<void> Function()? duringOpen;
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    await duringOpen?.call();
    return handled;
  }
}

class CustomerKhataFixture implements HttpClientAdapter {
  final calls = <RequestOptions>[], writes = <RequestOptions>[];
  final replay = <String, Map<String, dynamic>>{};
  final rows = <Map<String, dynamic>>[
    {
      'id': khataVendor,
      'name': 'Synthetic vendor',
      'kind': 'VENDOR',
      'balancePaise': '-10000',
      'status': 'PAYABLE'
    },
    {
      'id': khataContact,
      'name': 'Synthetic contact',
      'kind': 'PERSONAL',
      'balancePaise': '20000',
      'status': 'RECEIVABLE'
    },
  ];
  final contact = <String, dynamic>{
    'id': khataContact,
    'version': 1,
    'name': 'Synthetic contact',
    'mobile': null,
    'balancePaise': '20000'
  };
  final personal = <Map<String, dynamic>>[
    {
      'id': khataEntry,
      'version': 1,
      'contactId': khataContact,
      'direction': 'GAVE',
      'amountPaise': '20000',
      'date': '2026-11-18',
      'note': 'Synthetic entry'
    }
  ];
  final claims = <Map<String, dynamic>>[];
  String? vpa = 'synthetic@bank';
  String due = '10000', maxClaim = '10000';
  bool offline = false, loseResponse = false;
  int entryTotal = 1, commits = 0;
  int? denial, rejection;
  String rejectionCode = 'VERSION_CONFLICT';
  void Function()? afterCommit;
  Map<String, dynamic> get account => {
        'vendorCustomerId': khataVendor,
        'duePaise': due,
        'maxClaimPaise': maxClaim,
        'canClaim': true
      };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    ResponseBody json(Object value, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(value), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (offline) {
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    if (denial != null) return json({'code': 'FORBIDDEN'}, denial!);
    final path = o.uri.path,
        offset = int.parse('${o.queryParameters['offset'] ?? 0}'),
        limit = int.parse('${o.queryParameters['limit'] ?? 50}'),
        month = o.queryParameters['month'] ?? '2026-11';
    if (o.method == 'GET') {
      if (path.endsWith('/summary')) {
        return json({
          'items': rows.skip(offset).take(limit).toList(),
          'total': rows.length,
          'totalReceivablePaise': '9007199254740993',
          'totalPayablePaise': '10000',
          'netBalancePaise': '9007199254730993',
          'serverTime': '2026-11-18T04:00:00Z',
          'businessDate': '2026-11-18'
        });
      }
      if (path.endsWith('/settlement-options')) {
        return json({
          'vendorId': khataVendor,
          'payeeName': 'Synthetic vendor',
          'upiId': vpa,
          'upiAvailable': vpa != null,
          'cashAvailable': true,
          'duePaise': due,
          'accounts': [account]
        });
      }
      if (path.endsWith('/claims')) {
        final items = claims
            .where((c) => c['status'] == o.queryParameters['status'])
            .toList();
        return json({
          'items': items.skip(offset).take(limit).toList(),
          'total': items.length
        });
      }
      if (path.endsWith('/entries') && path.contains('/vendors/')) {
        return json({
          'vendorId': khataVendor,
          'vendorName': 'Synthetic vendor',
          'month': month,
          'duePaise': due,
          'openingDuePaise': '-500',
          'closingDuePaise': due,
          'monthDebitPaise': '10500',
          'monthCreditPaise': '0',
          'monthPaidPaise': '1000',
          'accounts': [account],
          'items': [
            for (var i = offset; i < entryTotal && i < offset + limit; i++)
              {
                'id':
                    '${i.toString().padLeft(8, '0')}-4444-4444-8444-444444444444',
                'vendorCustomerId': khataVendor,
                'type': 'DEBIT',
                'amountPaise': '10500',
                'entryDate': '$month-18',
                'refType': 'SALE',
                'refId': khataEntry,
                'reversesEntryId': null,
                'note': 'Synthetic sale',
                'productSummary': 'Milk: 2 packs',
                'paymentStatus': 'PENDING'
              }
          ],
          'total': entryTotal,
          'serverTime': '2026-11-18T04:00:00Z',
          'businessDate': '2026-11-18'
        });
      }
      if (path.endsWith('/personal-entries')) {
        return json({
          'items': personal.skip(offset).take(limit).toList(),
          'total': personal.length
        });
      }
      if (path.endsWith('/personal-contacts/$khataContact')) {
        return json(contact);
      }
      return json({'code': 'NOT_FOUND'}, 404);
    }
    writes.add(o);
    if (rejection != null) return json({'code': rejectionCode}, rejection!);
    final key = o.headers['Idempotency-Key'] as String;
    if (replay[key] != null) return json(replay[key]!, 201);
    final body = Map<String, dynamic>.from(jsonDecode(o.data as String) as Map);
    final ack = <String, dynamic>{
      'id': khataEntry,
      'version': 1,
      'deleted': o.method == 'DELETE'
    };
    if (path.endsWith('/claims')) {
      ack['status'] = 'PENDING';
      claims.add({
        'id': khataEntry,
        'vendorId': khataVendor,
        ...body,
        'upiTxnRef': null,
        'status': 'PENDING',
        'version': 1,
        'createdAt': '2026-11-18T04:00:00Z',
        'decidedAt': null,
        'rejectReason': null
      });
    }
    if (path.contains('/personal-contacts/') && o.method == 'PATCH') {
      contact.addAll(body);
      if (body['clearMobile'] == true) contact['mobile'] = null;
      contact['version'] = (contact['version'] as int) + 1;
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
