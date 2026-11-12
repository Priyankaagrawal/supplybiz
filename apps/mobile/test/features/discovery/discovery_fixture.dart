import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../products/catalog_fixture.dart' show productJson;
import '../home/home_fixture.dart' show homeCategoryId;

const vendorId = '55555555-5555-4555-8555-555555555555';
const otherVendorId = '77777777-7777-4777-8777-777777777777';
const discoveryProductId = '11111111-1111-4111-8111-111111111111';
Map<String, dynamic> vendorJson({bool favorite = false}) => {
      'id': vendorId,
      'businessName': 'Synthetic discovery vendor',
      'categoryId': homeCategoryId,
      'shopPhotoMediaId': null,
      'badges': ['Verified'],
      'distanceMeters': 500,
      'completedOrders30Days': 4,
      'favorite': favorite,
    };

/// Simulated HTTP transport; never evidence of live API/DB eligibility checks.
class DiscoveryFixture implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  final keys = <String>{};
  bool favorite = false, loseResponse = false, offline = false;
  int? denial;
  int commits = 0;
  Completer<void>? gate;
  final reached = Completer<void>();
  Map<String, dynamic> product = productJson()..['moq'] = 2;
  ResponseBody reply(Object body, [int status = 200]) =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions r, Stream<Uint8List>? stream, Future<void>? cancel) async {
    calls.add(r);
    if (!reached.isCompleted) reached.complete();
    if (gate != null) await gate!.future;
    if (offline) {
      throw DioException(
          requestOptions: r, type: DioExceptionType.connectionError);
    }
    if (denial != null) {
      return reply({'code': 'CUSTOMER_ROLE_REQUIRED'}, denial!);
    }
    final path = r.uri.path;
    if (r.method == 'PUT' || r.method == 'DELETE') {
      final key = r.headers['Idempotency-Key'] as String;
      if (keys.add(key)) {
        favorite = r.method == 'PUT';
        commits++;
      }
      if (loseResponse) {
        loseResponse = false;
        throw DioException(
            requestOptions: r, type: DioExceptionType.connectionError);
      }
      return reply({'vendorId': vendorId, 'favorite': favorite});
    }
    if (path.endsWith('/content')) return reply({'code': 'NOT_FOUND'}, 404);
    if (path.endsWith('/products') ||
        path.endsWith('/products/$discoveryProductId')) {
      return reply({
        'items': [product],
        'total': 1
      });
    }
    if (path.endsWith('/vendors/$vendorId')) {
      return reply({
        ...vendorJson(favorite: favorite),
        'address': 'Synthetic street',
        'city': 'Synthetic city',
        'state': 'Synthetic state',
        'pincode': '560001',
        'deliveryChargePaise': 1000,
        'minOrderPaise': 20000,
        'openingHours': null,
        'holidays': [
          {'date': '2026-12-01', 'reason': 'Synthetic holiday'}
        ]
      });
    }
    if (path.endsWith('/vendors') || path.endsWith('/favorites')) {
      return reply({
        'items': path.endsWith('/favorites') && !favorite
            ? []
            : [vendorJson(favorite: favorite)],
        'nextCursor':
            r.queryParameters['cursor'] == null ? 'synthetic-cursor' : null
      });
    }
    throw StateError('Unexpected simulated request ${r.method} $path');
  }
}
