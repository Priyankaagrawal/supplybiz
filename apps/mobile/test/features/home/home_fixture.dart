import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../addresses/address_fixture.dart' show addressJson;

const homeOrderId = '11111111-1111-4111-8111-111111111111';
const homeCategoryId = '22222222-2222-4222-8222-222222222222';
Map<String, dynamic> homeJson(
        {String day = '2026-11-12',
        String status = 'ACCEPTED',
        bool second = false}) =>
    {
      'serverTime': '${day}T04:30:00Z',
      'businessDate': day,
      'categories': [
        {
          'id': homeCategoryId,
          'code': 'MILK',
          'name': 'Milk and Dairy',
          'icon': 'milk',
          'status': 'ENABLED',
          'available': true,
          'productTypes': ['MILK']
        },
        {
          'id': '33333333-3333-4333-8333-333333333333',
          'code': 'TIFFIN',
          'name': 'Tiffin',
          'icon': null,
          'status': 'COMING_SOON',
          'available': false,
          'productTypes': []
        },
      ],
      'deliveries': [
        {
          'id': second ? '44444444-4444-4444-8444-444444444444' : homeOrderId,
          'orderNo': second ? 'SYN-2' : 'SYN-1',
          'vendorId': '55555555-5555-4555-8555-555555555555',
          'vendorName': 'Synthetic milk vendor',
          'source': 'APP',
          'status': status,
          'deliveryDate': day,
          'timeSlot': '07:00-08:00',
          'items': [
            {
              'productId': '66666666-6666-4666-8666-666666666666',
              'name': 'Synthetic milk',
              'qty': 2
            }
          ]
        }
      ],
      'nextCursor': second ? null : homeOrderId,
    };

class HomeFixture implements HttpClientAdapter {
  final started = Completer<void>();
  final calls = <RequestOptions>[];
  bool offline = false,
      deny = false,
      emptySearch = false,
      emptyHome = false,
      invalidCursor = false;
  String day = '2026-11-12', status = 'ACCEPTED';
  List<Map<String, dynamic>> addresses = [addressJson()];
  Completer<void>? gate;
  ResponseBody reply(Object body, [int code = 200]) =>
      ResponseBody.fromString(jsonEncode(body), code, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    calls.add(options);
    if (!started.isCompleted) started.complete();
    if (gate != null) await gate!.future;
    if (offline) {
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    }
    if (deny) return reply({'code': 'CUSTOMER_ROLE_REQUIRED'}, 403);
    switch (options.uri.path) {
      case '/api/v1/customer/home':
        if (invalidCursor && options.queryParameters['cursor'] != null) {
          return reply({'code': 'INVALID_CURSOR'}, 400);
        }
        final result = homeJson(
            day: day,
            status: status,
            second: options.queryParameters['cursor'] != null);
        if (emptyHome) {
          result['deliveries'] = [];
          result['nextCursor'] = null;
        }
        return reply(result);
      case '/api/v1/customer/addresses':
        return reply({'items': addresses});
      case '/api/v1/customer/search':
        return reply({
          'items': emptySearch
              ? []
              : [
                  {
                    'id': '55555555-5555-4555-8555-555555555555',
                    'businessName': 'Synthetic search vendor',
                    'categoryId': homeCategoryId,
                    'shopPhotoMediaId': null,
                    'badges': [],
                    'distanceMeters': 500,
                    'completedOrders30Days': 0,
                    'favorite': false
                  }
                ],
          'nextCursor': null
        });
      case '/api/v1/notifications':
        return reply({'items': [], 'total': 0, 'unreadCount': 2});
      case '/api/v1/me/notification-prefs':
        return reply({
          'orders': true,
          'payments': true,
          'delivery': true,
          'system': true
        });
      default:
        return reply({'code': 'NOT_FOUND'}, 404);
    }
  }

  @override
  void close({bool force = false}) {}
}
