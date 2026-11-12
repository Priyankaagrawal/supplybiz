import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const addressId = '11111111-1111-4111-8111-111111111111';
Map<String, dynamic> addressJson(
        {String id = addressId, bool isDefault = true}) =>
    {
      'id': id,
      'label': 'Synthetic home',
      'line1': 'Synthetic flat',
      'line2': 'Synthetic area',
      'landmark': '',
      'city': 'Synthetic city',
      'state': 'Synthetic state',
      'pincode': '560001',
      'latitude': 12.97,
      'longitude': 77.59,
      'isDefault': isDefault,
    };

class AddressFixture implements HttpClientAdapter {
  final rows = <Map<String, dynamic>>[];
  final writes = <RequestOptions>[];
  final replays = <String, Map<String, dynamic>>{};
  bool offline = false, loseResponse = false, offlineAfterWrite = false;
  int? status;
  int sequence = 0;
  ResponseBody response(Object body, [int code = 200]) =>
      ResponseBody.fromString(jsonEncode(body), code, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    if (offline) {
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    }
    if (status != null) {
      return response({
        'code': status == 403 ? 'CUSTOMER_ROLE_REQUIRED' : 'VALIDATION_FAILED'
      }, status!);
    }
    if (options.method == 'GET') return response({'items': rows});
    writes.add(options);
    final key = options.headers['Idempotency-Key'] as String;
    if (replays.containsKey(key)) {
      return response(replays[key]!, options.method == 'POST' ? 201 : 200);
    }
    final body = options.data == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(options.data as String) as Map);
    final id = options.uri.path.split('/').last;
    Map<String, dynamic> result;
    if (options.method == 'DELETE') {
      rows.removeWhere((r) => r['id'] == id);
      if (rows.isNotEmpty && !rows.any((r) => r['isDefault'] == true)) {
        rows.first['isDefault'] = true;
      }
      result = {'id': id, 'deleted': true};
    } else {
      if (options.method == 'POST') {
        result = {
          ...body,
          'id':
              '22222222-2222-4222-8222-${(++sequence).toString().padLeft(12, '0')}'
        };
        result['isDefault'] = rows.isEmpty || body['isDefault'] == true;
        rows.add(result);
      } else {
        result = rows.firstWhere((r) => r['id'] == id)..addAll(body);
      }
      if (result['isDefault'] == true) {
        for (final r in rows) {
          if (r['id'] != result['id']) r['isDefault'] = false;
        }
      }
    }
    replays[key] = Map<String, dynamic>.from(result);
    if (loseResponse) {
      loseResponse = false;
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    }
    if (offlineAfterWrite) offline = true;
    return response(result, options.method == 'POST' ? 201 : 200);
  }

  @override
  void close({bool force = false}) {}
}
