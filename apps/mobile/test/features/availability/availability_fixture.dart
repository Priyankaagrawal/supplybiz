// T-077: simulated transport; no financial/provider verification claim.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

const availabilityHolidayId = '11111111-1111-4111-8111-111111111111';
Map<String, dynamic> availabilityState() => {
      'version': 1,
      'acceptingToday': true,
      'deliveryPaused': false,
      'deliveryPausedUntil': null,
      'canResume': true,
      'canReduceActivity': true,
      'serverTime': '2026-11-18T04:00:00Z',
      'businessDate': '2026-11-18'
    };
Map<String, dynamic> availabilityHoliday(
        {String id = availabilityHolidayId, String date = '2026-11-19'}) =>
    {'id': id, 'date': date, 'reason': 'Synthetic holiday'};

class AvailabilityFixture implements HttpClientAdapter {
  final state = availabilityState(),
      rows = <Map<String, dynamic>>[availabilityHoliday()];
  final calls = <RequestOptions>[], writes = <RequestOptions>[];
  final replays = <String, Object>{};
  bool offline = false, loseResponse = false;
  int commits = 0, affectedOrders = 3;
  int? denial, rejection;
  String rejectionCode = 'VERSION_CONFLICT';
  Completer<void>? gate;
  void Function()? afterCommit;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(o);
    ResponseBody json(Object data, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(data), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (offline) {
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    if (denial != null) return json({'code': 'VENDOR_ROLE_REQUIRED'}, denial!);
    if (o.method == 'GET') {
      await gate?.future;
      if (o.uri.path.endsWith('/impact')) {
        return json({
          'affectedOrders': affectedOrders,
          'serverTime': state['serverTime'],
          'businessDate': state['businessDate']
        });
      }
      if (o.uri.path.endsWith('/holidays')) {
        final offset = int.parse('${o.queryParameters['offset'] ?? 0}'),
            limit = int.parse('${o.queryParameters['limit'] ?? 50}');
        return json({
          'items': rows.skip(offset).take(limit).toList(),
          'total': rows.length,
          'serverTime': state['serverTime'],
          'businessDate': state['businessDate']
        });
      }
      return json(state);
    }
    writes.add(o);
    if (rejection != null) return json({'code': rejectionCode}, rejection!);
    final key = o.headers['Idempotency-Key'] as String;
    if (replays.containsKey(key)) return json(replays[key]!);
    final raw = o.data,
        body = raw == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(
                raw is String ? jsonDecode(raw) as Map : raw as Map);
    Object result;
    if (o.method == 'PATCH') {
      state.addAll(body);
      state['version'] = (state['version'] as int) + 1;
      if (body.containsKey('deliveryPaused')) {
        state['deliveryPausedUntil'] = null;
      }
      result = {
        'availability': Map<String, dynamic>.from(state),
        'cancelledOrders': body['deliveryPaused'] == true ? affectedOrders : 0
      };
    } else if (o.method == 'POST') {
      final record = {'id': availabilityHolidayId, ...body};
      rows.add(record);
      result = {'holiday': record, 'cancelledOrders': affectedOrders};
    } else {
      final id = o.uri.path.split('/').last;
      rows.removeWhere((r) => r['id'] == id);
      result = {'id': id, 'deleted': true};
    }
    commits++;
    replays[key] = result;
    afterCommit?.call();
    if (loseResponse) {
      loseResponse = false;
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    return json(result, o.method == 'POST' ? 201 : 200);
  }
}
