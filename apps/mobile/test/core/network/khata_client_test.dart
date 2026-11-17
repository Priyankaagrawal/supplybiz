// T-082: generated transport checks only; native API/DB evidence is separate.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';

const khataId = '11111111-1111-4111-8111-111111111111';

class KhataAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  Map<String, Object> get account => {
        'vendorCustomerId': khataId,
        'duePaise': '1000',
        'maxClaimPaise': '1000',
        'canClaim': true
      };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    Object body;
    if (o.uri.path.endsWith('/summary')) {
      body = {
        'totalReceivablePaise': '0',
        'totalPayablePaise': '9007199254740993',
        'netBalancePaise': '-9007199254740993',
        'items': [
          {
            'id': khataId,
            'kind': 'VENDOR',
            'name': 'Synthetic vendor',
            'balancePaise': '-9007199254740993',
            'status': 'PAYABLE'
          }
        ],
        'total': 1,
        'serverTime': '2026-11-17T04:00:00Z',
        'businessDate': '2026-11-17'
      };
    } else if (o.uri.path.endsWith('/settlement-options')) {
      body = {
        'vendorId': khataId,
        'payeeName': 'Synthetic vendor',
        'upiId': null,
        'upiAvailable': false,
        'cashAvailable': true,
        'duePaise': '1000',
        'accounts': [account]
      };
    } else if (o.uri.path.endsWith('/payment-details')) {
      body = o.method == 'PATCH'
          ? {'version': 2, 'published': true}
          : {
              'version': 1,
              'published': false,
              'upiId': null,
              'payeeName': 'Synthetic vendor'
            };
    } else if (o.uri.path.endsWith('/claims') ||
        o.uri.path.endsWith('/confirm') ||
        o.uri.path.endsWith('/reject')) {
      body = {
        'id': khataId,
        'status': o.uri.path.endsWith('/confirm')
            ? 'CONFIRMED'
            : o.uri.path.endsWith('/reject')
                ? 'REJECTED'
                : 'PENDING',
        'version': o.uri.path.endsWith('/claims') ? 1 : 2
      };
    } else {
      body = {
        'id': khataId,
        'version': o.method == 'POST' ? 1 : 2,
        'deleted': o.method == 'DELETE'
      };
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
      'T-082 typed personal create/clear/delete preserve exact paise/date, version, nullable clearing and retry keys',
      () async {
    final f = KhataAdapter(),
        dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = f;
    addTearDown(() => dio.close(force: true));
    final api = CustomerKhataApi(dio);
    final input = PersonalEntryInput(
        contactId: khataId,
        direction: PersonalEntryInputDirectionEnum.GAVE,
        amountPaise: '9007199254740993',
        date: '2026-11-17',
        note: 'Synthetic');
    for (var i = 0; i < 2; i++) {
      expect(
          (await api.customerKhataControllerEntryCreate(
                  idempotencyKey: 'synthetic-entry', personalEntryInput: input))
              .data!
              .id,
          khataId);
    }
    expect(f.calls[0].data, f.calls[1].data);
    final wire = jsonDecode(f.calls.last.data as String) as Map;
    expect(wire['amountPaise'], '9007199254740993');
    expect(wire['date'], '2026-11-17');
    expect(wire['direction'], 'GAVE');
    expect(f.calls.last.headers['Idempotency-Key'], 'synthetic-entry');
    await api.customerKhataControllerContactPatch(
        id: khataId,
        idempotencyKey: 'synthetic-clear',
        personalContactPatch:
            PersonalContactPatch(version: 1, clearMobile: true));
    expect(jsonDecode(f.calls.last.data as String),
        {'version': 1, 'clearMobile': true});
    final removed = (await api.customerKhataControllerEntryDelete(
            id: khataId,
            idempotencyKey: 'synthetic-delete',
            khataVersion: KhataVersion(version: 1)))
        .data!;
    expect(removed.deleted, true);
    expect(f.calls.last.method, 'DELETE');
    expect(jsonDecode(f.calls.last.data as String), {'version': 1});
  });
  test(
      'T-082 typed claims/publication and summary preserve status/role paths, signed huge balances and unavailable UPI',
      () async {
    final f = KhataAdapter(),
        dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    dio.httpClientAdapter = f;
    addTearDown(() => dio.close(force: true));
    final customer = CustomerKhataApi(dio), vendor = VendorKhataApi(dio);
    expect(
        (await customer.customerKhataControllerSummary()).data!.netBalancePaise,
        '-9007199254740993');
    final options =
        (await customer.customerKhataControllerOptions(id: khataId)).data!;
    expect(options.upiId, isNull);
    expect(options.upiAvailable, false);
    expect(options.accounts.single.maxClaimPaise, '1000');
    final claim = (await customer.customerKhataControllerClaim(
            id: khataId,
            idempotencyKey: 'synthetic-claim',
            paymentClaimInput: PaymentClaimInput(
                vendorCustomerId: khataId,
                amountPaise: '1000',
                method: PaymentClaimInputMethodEnum.CASH)))
        .data!;
    expect(claim.status, 'PENDING');
    expect(jsonDecode(f.calls.last.data as String),
        {'vendorCustomerId': khataId, 'amountPaise': '1000', 'method': 'CASH'});
    expect(
        (await vendor.vendorKhataControllerConfirm(
                id: khataId,
                idempotencyKey: 'synthetic-confirm',
                khataVersion: KhataVersion(version: 1)))
            .data!
            .status,
        'CONFIRMED');
    expect(f.calls.last.uri.path,
        '/api/v1/vendor/payment-claims/$khataId/confirm');
    await vendor.vendorKhataControllerDetailsPublish(
        idempotencyKey: 'synthetic-publish',
        paymentPublicationInput: PaymentPublicationInput(
            version: 1, publish: true, upiId: 'synthetic.pay@okbank'));
    expect(jsonDecode(f.calls.last.data as String),
        {'version': 1, 'publish': true, 'upiId': 'synthetic.pay@okbank'});
    expect(f.calls.last.uri.path, '/api/v1/vendor/khata/payment-details');
  });
}
