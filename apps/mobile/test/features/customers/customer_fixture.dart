import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

const syntheticCustomerId = '11111111-1111-4111-8111-111111111111';
Map<String, dynamic> customerJson(
        {String id = syntheticCustomerId,
        String name = 'Synthetic Customer',
        String status = 'ACTIVE'}) =>
    {
      'id': id,
      'name': name,
      'mobile': '+919000000000',
      'email': 'synthetic@example.invalid',
      'address': 'Synthetic address',
      'preferredPayment': 'CASH',
      'status': status,
      'userId': null,
      'linkStatus': 'UNLINKED',
    };

/// Simulated HTTP only. Native API/DB evidence belongs to T-028/manual checks.
class CustomerFixture implements HttpClientAdapter {
  final entries = <Map<String, dynamic>>[customerJson()];
  final subscribed = <String>{};
  final calls = <RequestOptions>[], writes = <RequestOptions>[];
  final replays = <String, Map<String, dynamic>>{};
  bool offline = false, failAfterCommit = false;
  int? denial, rejectStatus;
  String rejectCode = 'DUPLICATE';
  int commits = 0, limit = 50;
  Completer<void>? listGate;
  final listReached = Completer<void>();
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    calls.add(options);
    ResponseBody response(Map<String, dynamic> body, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(body), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (offline) {
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    }
    if (denial != null) {
      return response({'code': 'VENDOR_ROLE_REQUIRED'}, denial!);
    }
    if (options.method == 'GET') {
      if (!listReached.isCompleted) listReached.complete();
      await listGate?.future;
      final filtered = options.queryParameters['filter'] == 'SUBSCRIPTION'
          ? entries.where((c) => subscribed.contains(c['id'])).toList()
          : entries;
      final offset = int.parse('${options.queryParameters['offset'] ?? 0}'),
          count = int.parse('${options.queryParameters['limit'] ?? 50}');
      return response({
        'items': filtered.skip(offset).take(count).toList(),
        'total': filtered.length,
        'activeCount': entries.where((c) => c['status'] == 'ACTIVE').length,
        'customerLimit': limit
      });
    }
    writes.add(options);
    if (rejectStatus != null) {
      return response({'code': rejectCode}, rejectStatus!);
    }
    final key = options.headers['Idempotency-Key'] as String;
    if (replays.containsKey(key)) {
      return response(replays[key]!, options.method == 'POST' ? 201 : 200);
    }
    final raw = options.data;
    final body = Map<String, dynamic>.from(
        raw is String ? jsonDecode(raw) as Map : raw as Map);
    Map<String, dynamic> result;
    if (options.method == 'POST') {
      result = {...customerJson(id: const Uuid().v4()), ...body};
      final number = result['mobile'] as String;
      if (!number.startsWith('+91')) result['mobile'] = '+91$number';
      entries.add(result);
    } else {
      final id = options.uri.path.split('/').last;
      final matches = entries.where((c) => c['id'] == id);
      if (matches.isEmpty) return response({'code': 'CUSTOMER_NOT_FOUND'}, 404);
      matches.first.addAll(body);
      result = Map.of(matches.first);
    }
    commits++;
    replays[key] = Map.of(result);
    if (failAfterCommit) {
      failAfterCommit = false;
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    }
    return response(result, options.method == 'POST' ? 201 : 200);
  }
}
