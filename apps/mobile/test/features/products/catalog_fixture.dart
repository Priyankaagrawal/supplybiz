import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

const syntheticProductId = '11111111-1111-4111-8111-111111111111';
Map<String, dynamic> productJson(
        {String id = syntheticProductId, String name = 'Synthetic Cow Milk'}) =>
    {
      'id': id,
      'name': name,
      'productType': 'MILK',
      'milkType': 'COW',
      'unitValue': 1,
      'unitType': 'L',
      'sellingPricePaise': 6010,
      'subscriptionPricePaise': 5500,
      'stockQty': 12,
      'moq': 1,
      'description': '',
      'imageMediaId': null,
      'isActive': true,
      'version': 1,
    };
final syntheticPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jN1kAAAAASUVORK5CYII=');

/// Simulated transport, not live provider/API/DB verification.
class CatalogFixture implements HttpClientAdapter {
  final entries = <Map<String, dynamic>>[productJson()];
  final calls = <RequestOptions>[], writes = <RequestOptions>[];
  final replay = <String, Map<String, dynamic>>{};
  bool offline = false, failAfterCommit = false, inUse = false;
  int? denial;
  int commits = 0;
  Completer<void>? listGate;
  final listReached = Completer<void>();
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    calls.add(options);
    if (offline) {
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    }
    ResponseBody response(Map<String, dynamic> body, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(body), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (denial != null) {
      return response({'code': 'VENDOR_ROLE_REQUIRED'}, denial!);
    }
    final path = options.uri.path;
    if (path.endsWith('/options')) {
      return response({
        'productTypes': ['MILK', 'PANEER', 'CURD', 'OTHER']
      });
    }
    if (path.endsWith('/content')) {
      return ResponseBody.fromBytes(syntheticPng, 200, headers: {
        Headers.contentTypeHeader: ['image/png']
      });
    }
    if (options.method == 'GET') {
      if (!listReached.isCompleted) listReached.complete();
      await listGate?.future;
      final offset = int.parse('${options.queryParameters['offset'] ?? 0}');
      final limit = int.parse('${options.queryParameters['limit'] ?? 100}');
      return response({
        'items': entries.skip(offset).take(limit).toList(),
        'total': entries.length
      });
    }
    writes.add(options);
    final key = options.headers['Idempotency-Key'] as String;
    if (replay.containsKey(key)) {
      return response(replay[key]!, options.method == 'POST' ? 201 : 200);
    }
    if (path.endsWith('/media')) {
      return response({'mediaId': syntheticProductId, 'status': 'READY'}, 201);
    }
    final raw = options.data;
    final body = raw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
            raw is String ? jsonDecode(raw) as Map : raw as Map);
    Map<String, dynamic> result;
    if (options.method == 'POST' && !path.endsWith('/stock-adjustments')) {
      result = {...productJson(id: const Uuid().v4()), ...body};
      entries.add(result);
      commits++;
    } else {
      final id = path.split('/')[5];
      final item = entries.firstWhere((e) => e['id'] == id);
      if (options.method == 'DELETE') {
        if (inUse) return response({'code': 'PRODUCT_IN_USE'}, 409);
        entries.remove(item);
        result = {'id': id, 'deleted': true};
      } else {
        item.addAll(options.method == 'PATCH'
            ? body
            : {'stockQty': (item['stockQty'] as int) + (body['delta'] as int)});
        item['version'] = (item['version'] as int) + 1;
        result = Map.of(item);
      }
    }
    replay[key] = Map.of(result);
    if (failAfterCommit) {
      failAfterCommit = false;
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    }
    return response(result, options.method == 'POST' ? 201 : 200);
  }
}
