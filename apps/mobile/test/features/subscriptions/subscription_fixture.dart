// T-076 simulated HTTP only; no live API/DB/provider claim.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../customers/customer_fixture.dart'
    show customerJson, syntheticCustomerId;
import '../products/catalog_fixture.dart' show productJson, syntheticProductId;
import '../onboarding/onboarding_test.dart' show OnboardingFixture;

const subscriptionId = '22222222-2222-4222-8222-222222222222';
Map<String, dynamic> subscriptionJson(
        {String id = subscriptionId, String status = 'ACTIVE'}) =>
    {
      'id': id,
      'version': 1,
      'status': status,
      'effectiveFrom': '2026-11-18',
      'vendorId': syntheticProductId,
      'vendorCustomerId': syntheticCustomerId,
      'productId': syntheticProductId,
      'productName': 'Synthetic Cow Milk',
      'qty': 1,
      'weekdays': [1, 2, 3, 4, 5, 6, 7],
      'timeSlot': 'AM',
      'startDate': '2026-11-18',
      'endDate': null,
      'addressSnapshot': <String, Object>{},
      'paymentMethod': 'CASH',
      'createdBy': 'VENDOR',
      'dailyAmountPaise': '5500',
      'monthlyEstimatePaise': '71500',
      'estimateMonth': '2026-11',
      'revisions': [],
      'pauses': [],
      'skips': [],
    };
Map<String, dynamic> subscriptionSettings() => {
      'version': 1,
      'serverTime': '2026-11-17T04:00:00Z',
      'businessDate': '2026-11-17',
      'autoAcceptSubscriptions': false,
      'effectiveAutoAcceptSubscriptions': false,
      'canAutoAccept': false,
      'canEditSubscriptions': true,
      'canReduceActivity': true,
      'deliveryAvailable': true,
      'deliveryStartTime': null,
      'deliveryEndTime': null,
      'maxDailyOrders': null,
      'dailyMilkCapacityLitres': null,
      'pauseAllSubscriptions': false,
      'summary': {
        'totalSubscriptions': 1,
        'active': 1,
        'paused': 0,
        'pendingApproval': 0,
        'cancelled': 0,
        'rejected': 0,
        'completed': 0,
        'subscriptionCustomers': 1
      },
    };

class SubscriptionFixture implements HttpClientAdapter {
  final controls = subscriptionSettings();
  final rows = <Map<String, dynamic>>[subscriptionJson()];
  final calls = <RequestOptions>[], writes = <RequestOptions>[];
  final replay = <String, Map<String, dynamic>>{};
  bool offline = false, loseResponse = false;
  int commits = 0;
  int? denial, rejection;
  String rejectCode = 'VERSION_CONFLICT';
  Completer<void>? gate;
  void Function()? afterCommit;
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
    if (o.method == 'GET') {
      await gate?.future;
      final offset = int.parse('${o.queryParameters['offset'] ?? 0}'),
          limit = int.parse('${o.queryParameters['limit'] ?? 50}');
      if (o.uri.path.endsWith('/settings')) return json(controls);
      if (o.uri.path.endsWith('/onboarding')) {
        final p = OnboardingFixture().profile;
        (p['settings'] as Map)['timeSlots'] = ['AM', 'PM'];
        return json(p);
      }
      if (o.uri.path.endsWith('/products')) {
        return json({
          'items': [productJson()],
          'total': 1
        });
      }
      if (o.uri.path.endsWith('/customers')) {
        return json({
          'items': [customerJson()],
          'total': 1,
          'activeCount': 1,
          'customerLimit': 50
        });
      }
      return json({
        'serverTime': controls['serverTime'],
        'businessDate': controls['businessDate'],
        'items': rows.skip(offset).take(limit).toList(),
        'total': rows.length
      });
    }
    writes.add(o);
    if (rejection != null) return json({'code': rejectCode}, rejection!);
    final key = o.headers['Idempotency-Key'] as String;
    if (replay[key] != null) return json(replay[key]!);
    final raw = o.data,
        body = Map<String, dynamic>.from(
            raw is String ? jsonDecode(raw) as Map : raw as Map);
    Map<String, dynamic> result;
    if (o.uri.path.endsWith('/settings')) {
      controls.addAll(body);
      controls['version'] = (controls['version'] as int) + 1;
      if (body['clearMaxDailyOrders'] == true) {
        controls['maxDailyOrders'] = null;
      }
      if (body['clearDailyMilkCapacity'] == true) {
        controls['dailyMilkCapacityLitres'] = null;
      }
      if (body['clearDeliveryWindow'] == true) {
        controls['deliveryStartTime'] = null;
        controls['deliveryEndTime'] = null;
      }
      result = Map.of(controls);
    } else {
      final id = o.uri.path.endsWith('/subscriptions')
          ? '33333333-3333-4333-8333-333333333333'
          : o.uri.path.split('/').where((s) => s.length == 36).last;
      if (o.uri.path.endsWith('/subscriptions')) {
        rows.add({...subscriptionJson(id: id), ...body});
      }
      result = {
        'id': id,
        'version': 2,
        'status': 'ACTIVE',
        'effectiveFrom': '2026-11-19'
      };
    }
    commits++;
    replay[key] = result;
    afterCommit?.call();
    if (loseResponse) {
      loseResponse = false;
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    return json(result, o.method == 'POST' ? 201 : 200);
  }
}
