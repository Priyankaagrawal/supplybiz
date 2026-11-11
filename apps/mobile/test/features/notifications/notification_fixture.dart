import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import 'package:supplybiz_mobile/features/notifications/push_gateway.dart';

const notificationId = '22222222-2222-4222-8222-222222222222';
const notificationOwner = '11111111-1111-4111-8111-111111111111';
Map<String, dynamic> notificationJson(
        {String id = notificationId,
        String role = 'CUSTOMER',
        String category = 'ORDERS'}) =>
    {
      'id': id,
      'role': role,
      'category': category,
      'type': 'ORDER_ACCEPTED',
      'title': 'Synthetic order update',
      'body': 'An order has changed.',
      'path': '/${role.toLowerCase()}/orders/$id',
      'readAt': null,
      'createdAt': '2026-11-11T00:00:00.000Z',
    };

class NotificationFixture implements HttpClientAdapter {
  final rows = <Map<String, dynamic>>[notificationJson()];
  final calls = <RequestOptions>[];
  final replays = <String>{};
  Map<String, dynamic> preferences = {
    'orders': true,
    'payments': true,
    'delivery': true,
    'system': true
  };
  bool offline = false, loseResponse = false;
  int? denial;
  Completer<void>? gate;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions request, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    calls.add(request);
    ResponseBody reply(Object body, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(body), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (offline) {
      throw DioException(
          requestOptions: request, type: DioExceptionType.connectionError);
    }
    if (denial != null) return reply({'code': 'FORBIDDEN'}, denial!);
    await gate?.future;
    final path = request.uri.path;
    if (request.method == 'GET' && path.endsWith('/notification-prefs')) {
      return reply(preferences);
    }
    if (request.method == 'GET') {
      final role = request.queryParameters['role'];
      final category = request.queryParameters['category'] ?? 'ALL';
      final owned = rows.where((r) => r['role'] == role).toList();
      final filtered = owned
          .where((r) => category == 'ALL' || category == r['category'])
          .toList();
      final offset = request.queryParameters['offset'] as int? ?? 0;
      return reply({
        'items': filtered.skip(offset).take(100).toList(),
        'total': filtered.length,
        'unreadCount': owned.where((r) => r['readAt'] == null).length
      });
    }
    final key = request.headers['Idempotency-Key'] as String;
    final body = request.data == null
        ? <String, dynamic>{}
        : jsonDecode(request.data as String) as Map<String, dynamic>;
    if (replays.add(key)) {
      if (path.endsWith('/notification-prefs')) {
        preferences = body;
      } else if (path.endsWith('/read')) {
        for (final row in rows) {
          if (row['role'] == body['role'] &&
              (body['all'] == true ||
                  (body['ids'] as List).contains(row['id']))) {
            row['readAt'] = '2026-11-11T01:00:00.000Z';
          }
        }
      } else if (request.method == 'DELETE') {
        rows.removeWhere((r) => r['role'] == request.queryParameters['role']);
      }
    }
    if (loseResponse) {
      loseResponse = false;
      throw DioException(
          requestOptions: request, type: DioExceptionType.connectionError);
    }
    if (path.endsWith('/notification-prefs')) return reply(preferences);
    if (path.endsWith('/current')) {
      return reply(
          {'deviceId': notificationOwner, 'pushEnabled': body['pushEnabled']});
    }
    return reply({'changed': 1});
  }
}

class NotificationSession extends SessionController {
  String role = 'CUSTOMER';
  @override
  AuthState build() => snapshot();
  AuthState snapshot() => AuthState(
      ready: true,
      user: MeResponse.fromJson({
        'id': notificationOwner,
        'mobile': '+919000000000',
        'name': null,
        'language': 'EN',
        'roles': ['CUSTOMER', 'VENDOR'],
        'activeRole': role,
      }));
  @override
  Future<void> selectRole(String value) async {
    role = value;
    state = snapshot();
  }

  void signOut() => state = const AuthState(ready: true);
}

class FakePushGateway implements PushGateway {
  final messages = StreamController<Map<String, dynamic>>.broadcast();
  final taps = StreamController<Map<String, dynamic>>.broadcast();
  final rotations = StreamController<String>.broadcast();
  bool allowed = false;
  int prompts = 0;
  Map<String, dynamic>? cold;
  @override
  bool get available => true;
  @override
  Stream<Map<String, dynamic>> get foreground => messages.stream;
  @override
  Stream<Map<String, dynamic>> get opened => taps.stream;
  @override
  Stream<String> get tokens => rotations.stream;
  @override
  Future<Map<String, dynamic>?> initial() async => cold;
  @override
  Future<bool> permitted({bool request = false}) async {
    if (request) prompts++;
    return allowed;
  }

  @override
  Future<String?> token() async => 'synthetic-fcm';
  Future<void> close() async {
    await messages.close();
    await taps.close();
    await rotations.close();
  }
}
