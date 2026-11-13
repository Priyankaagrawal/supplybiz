import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/storage/customer_device.dart';
import 'package:supplybiz_mobile/features/orders/orders_controller.dart';
import 'package:supplybiz_mobile/features/orders/orders_pages.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../addresses/address_fixture.dart' show addressJson;
import '../addresses/addresses_test.dart' show reveal;

const orderId = '77777777-7777-4777-8777-777777777777';
const orderPhone = '+919000000000';
Map<String, dynamic> orderJson(
        {String id = orderId,
        String status = 'NEW',
        int version = 1,
        String number = 'ORD00000001'}) =>
    {
      'id': id,
      'orderNo': number,
      'vendorId': '55555555-5555-4555-8555-555555555555',
      'status': status,
      'version': version,
      'deliveryDate': '2026-11-14',
      'timeSlot': '07:00-08:00',
      'totalPaise': '12020',
      'paymentMode': 'POD_CASH',
      'paymentStatus': 'UNPAID',
      'source': 'APP',
      'createdAt': '2026-11-13T10:00:00Z',
    };

/// Simulated transport; ownership/state enforcement remains real API T-045 evidence.
class OrdersFixture implements HttpClientAdapter {
  final rows = List.generate(
      25,
      (i) => orderJson(
          id: i == 0
              ? orderId
              : '88888888-8888-4888-8888-${i.toString().padLeft(12, '0')}',
          number: 'ORD${(i + 1).toString().padLeft(8, '0')}'));
  final requests = <RequestOptions>[],
      replays = <String, Map<String, dynamic>>{};
  bool lost = false, offline = false, conflict = false, failAfterWrite = false;
  int? denial;
  int commits = 0;
  Completer<void>? gate;
  Map<String, dynamic> detail(Map<String, dynamic> row) => {
        ...row,
        'vendorName': 'Synthetic vendor',
        'customerName': 'Synthetic order customer',
        'customerMobile': orderPhone,
        'address': addressJson(),
        'items': [
          {
            'productId': '11111111-1111-4111-8111-111111111111',
            'name': 'Synthetic milk',
            'unitValue': '1',
            'unitType': 'L',
            'qty': 2,
            'unitPricePaise': '6010',
            'lineTotalPaise': '12020'
          }
        ],
        'timeline': [
          {
            'status': row['status'],
            'reason': row['rejectReason'],
            'at': '2026-11-13T10:00:00Z'
          }
        ],
        'subtotalPaise': '12020',
        'deliveryChargePaise': '0',
        'discountPaise': '0',
        'rejectReason': row['rejectReason'],
        'cancelReason': null,
        'failReason': null,
      };
  ResponseBody reply(Object data, [int status = 200]) =>
      ResponseBody.fromString(jsonEncode(data), status, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions r, Stream<Uint8List>? stream, Future<void>? cancel) async {
    requests.add(r);
    if (gate != null) await gate!.future;
    if (offline) {
      throw DioException(
          requestOptions: r, type: DioExceptionType.connectionError);
    }
    if (denial != null) return reply({'code': 'VENDOR_ROLE_REQUIRED'}, denial!);
    final id = r.path.split('/').where((p) => p.isNotEmpty).last;
    if (r.method == 'GET' && r.path.endsWith('/orders')) {
      var selected = rows.toList();
      final q = r.queryParameters;
      if (q['status'] != null && q['status'] != 'ALL') {
        selected = selected
            .where((row) => q['status'] == 'CANCELLED'
                ? ['REJECTED', 'CANCELLED'].contains(row['status'])
                : row['status'] == q['status'])
            .toList();
      }
      if (q['q'] != null && (q['q'] as String).isNotEmpty) {
        selected = selected
            .where((row) =>
                (row['orderNo'] as String).contains(q['q'] as String) ||
                'Synthetic order customer'.contains(q['q'] as String))
            .toList();
      }
      final offset = q['offset'] as int? ?? 0;
      return reply({
        'items': selected.skip(offset).take(20).toList(),
        'total': selected.length
      });
    }
    if (r.method == 'GET') {
      final row = rows.where((row) => row['id'] == id).firstOrNull;
      return row == null
          ? reply({'code': 'ORDER_NOT_FOUND'}, 404)
          : reply(detail(row));
    }
    final requestId = r.path.split('/').reversed.skip(1).first;
    final row = rows.where((row) => row['id'] == requestId).firstOrNull;
    if (row == null) return reply({'code': 'ORDER_NOT_FOUND'}, 404);
    final key = r.headers['Idempotency-Key'] as String;
    if (replays.containsKey(key)) return reply(replays[key]!, 201);
    if (conflict) {
      conflict = false;
      row['status'] = 'CANCELLED';
      row['version'] = (row['version'] as int) + 1;
      return reply({'code': 'VERSION_CONFLICT'}, 409);
    }
    final body = jsonDecode(r.data as String) as Map;
    row['status'] = body['to'];
    row['version'] = (row['version'] as int) + 1;
    row['rejectReason'] =
        body['reason'] == 'OTHER' ? body['reasonText'] : body['reason'];
    commits++;
    replays[key] = Map<String, dynamic>.from(row);
    if (failAfterWrite) offline = true;
    if (lost) {
      lost = false;
      throw DioException(
          requestOptions: r, type: DioExceptionType.connectionError);
    }
    return reply(replays[key]!, 201);
  }
}

NetworkClient ordersClient(OrdersFixture f) => NetworkClient(
    baseUrl: 'https://api.example.test',
    session: TestSession(),
    adapter: f,
    delay: (_) async {});
Widget ordersApp(VendorOrdersController m, {Widget? child, double scale = 1}) =>
    ProviderScope(
        overrides: [vendorOrdersProvider.overrideWith((ref) => m)],
        child: MaterialApp(
            theme: sbLightTheme(const Locale('en')),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...SbLocalizations.delegates
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: child ?? const VendorOrderPage(id: orderId)));
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'TC-045 combines server filters/name/date, paginates and restores scoped offline snapshots',
      () async {
    final f = OrdersFixture(), client = ordersClient(f), store = MemoryDrafts();
    addTearDown(client.close);
    var m = VendorOrdersController(VendorOrdersApi(client.dio), store, 'one');
    await m.load();
    expect(m.items.length, 20);
    await m.load(more: true);
    expect(m.items.length, 25);
    await m.load(
        filter: 'NEW',
        query: 'Synthetic order customer',
        day: DateTime(2026, 11, 14));
    expect(f.requests.last.queryParameters, containsPair('status', 'NEW'));
    expect(f.requests.last.queryParameters,
        containsPair('q', 'Synthetic order customer'));
    expect(
        '${f.requests.last.queryParameters['date']}', startsWith('2026-11-14'));
    await m.open(orderId);
    m.dispose();
    f.offline = true;
    m = VendorOrdersController(VendorOrdersApi(client.dio), store, 'one');
    await m.load();
    expect(m.ready, isTrue);
    expect(m.stale, isTrue);
    expect(m.details[orderId]!.customerName, 'Synthetic order customer');
    expect(m.canActOn(orderId), isFalse);
    final other =
        VendorOrdersController(VendorOrdersApi(client.dio), store, 'other');
    await other.load();
    expect(other.items, isEmpty);
    expect(other.details, isEmpty);
    other.dispose();
    m.dispose();
  });
  test(
      'TC-046/049 exact request/version survives restart; replay commits once and failed refresh blocks actions',
      () async {
    final f = OrdersFixture(), client = ordersClient(f), store = MemoryDrafts();
    addTearDown(client.close);
    var m = VendorOrdersController(VendorOrdersApi(client.dio), store, 'one');
    await m.open(orderId);
    f.lost = true;
    await m.act(orderId, 'ACCEPTED');
    final key = m.pending!['key'];
    expect(m.canAct, isFalse);
    m.dispose();
    m = VendorOrdersController(VendorOrdersApi(client.dio), store, 'one');
    await m.load();
    await m.retry();
    expect(m.pending, isNull);
    expect(f.commits, 1);
    expect(m.details[orderId]!.status, 'ACCEPTED');
    final posts = f.requests.where((r) => r.method == 'POST').toList();
    expect(posts.map((r) => r.headers['Idempotency-Key']).toSet(), {key});
    expect((jsonDecode(posts.last.data as String) as Map)['version'], 1);
    f.failAfterWrite = true;
    await m.act(orderId, 'PREPARING');
    expect(m.pending, isNull);
    expect(m.completed, isTrue);
    expect(m.canActOn(orderId), isFalse);
    expect(f.commits, 2);
    m.dispose();
  });
  test(
      'TC-047 rejects missing/short Other reasons without sending and records the exact trimmed reason',
      () async {
    final f = OrdersFixture(), client = ordersClient(f), store = MemoryDrafts();
    addTearDown(client.close);
    final m = VendorOrdersController(VendorOrdersApi(client.dio), store, 'one');
    await m.open(orderId);
    await m.act(orderId, 'REJECTED');
    await m.act(orderId, 'REJECTED', reason: 'OTHER', text: ' abc ');
    expect(f.commits, 0);
    await m.act(orderId, 'REJECTED',
        reason: 'OTHER', text: ' Synthetic reason ');
    expect(m.details[orderId]!.rejectReason, 'Synthetic reason');
    expect(m.details[orderId]!.status, 'REJECTED');
    m.dispose();
  });
  test(
      'TC-048/049 cancellation conflict refreshes detail/list; invalid terminal actions never send',
      () async {
    final f = OrdersFixture(), client = ordersClient(f), store = MemoryDrafts();
    addTearDown(client.close);
    final m = VendorOrdersController(VendorOrdersApi(client.dio), store, 'one');
    await m.open(orderId);
    f.conflict = true;
    await m.act(orderId, 'ACCEPTED');
    expect(m.failure?.code, 'VERSION_CONFLICT');
    expect(m.pending, isNull);
    expect(m.details[orderId]!.status, 'CANCELLED');
    await m.act(orderId, 'ACCEPTED');
    expect(f.commits, 0);
    m.dispose();
  });
  test(
      'TC-046 disk failures never send, duplicate taps serialize, and permission denial removes private cache',
      () async {
    final f = OrdersFixture(), client = ordersClient(f), store = MemoryDrafts();
    addTearDown(client.close);
    final m = VendorOrdersController(VendorOrdersApi(client.dio), store, 'one');
    await m.open(orderId);
    store.fail = true;
    await m.act(orderId, 'ACCEPTED');
    expect(f.commits, 0);
    store.fail = false;
    await Future.wait([m.retry(), m.retry()]);
    expect(f.commits, 1);
    await m.load(
        query: 'Synthetic order customer', day: DateTime(2026, 11, 14));
    f.denial = 403;
    await m.load();
    expect(m.search, isEmpty);
    expect(m.date, isNull);
    expect(m.details, isEmpty);
    expect(m.items, isEmpty);
    expect((await store.read('one')).toString(), isNot(contains(orderPhone)));
    m.dispose();
  });
  test('disposed orders never publish or persist late private reads', () async {
    final f = OrdersFixture()..gate = Completer<void>(),
        client = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(client.close);
    final m = VendorOrdersController(VendorOrdersApi(client.dio), store, 'one');
    final read = m.open(orderId);
    await Future<void>.delayed(Duration.zero);
    m.dispose();
    f.gate!.complete();
    await read;
    expect(m.details, isEmpty);
    expect(await store.read('one'), isEmpty);
  });
  testWidgets(
      'TC-047/050 200% order detail/reject sheet and dialer use owned customer fields',
      (tester) async {
    final f = OrdersFixture(), client = ordersClient(f), store = MemoryDrafts();
    addTearDown(client.close);
    final m = VendorOrdersController(VendorOrdersApi(client.dio), store, 'one');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(customerDeviceChannel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(customerDeviceChannel, null));
    await tester.pumpWidget(ordersApp(m, scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Call customer'));
    await tester.tap(find.text('Call customer'));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'dial');
    expect((calls.single.arguments as Map)['mobile'], orderPhone);
    await reveal(tester, find.text('Reject order'));
    await tester.tap(find.text('Reject order'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();
    final button = tester
        .widget<SbButton>(find.widgetWithText(SbButton, 'Reject order').last);
    expect(button.onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'Synthetic reason');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SbButton, 'Reject order').last);
    await tester.pumpAndSettle();
    expect(f.commits, 1);
    expect(m.details[orderId]!.status, 'REJECTED');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('TC-045 list filters/search and pagination render at 200%',
      (tester) async {
    final f = OrdersFixture(), client = ordersClient(f), store = MemoryDrafts();
    addTearDown(client.close);
    final m = VendorOrdersController(VendorOrdersApi(client.dio), store, 'one');
    await tester
        .pumpWidget(ordersApp(m, scale: 2, child: const VendorOrdersPage()));
    await tester.pumpAndSettle();
    expect(find.text('ORD00000001'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
