import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/features/deliveries/deliveries_controller.dart';
import 'package:supplybiz_mobile/features/deliveries/deliveries_pages.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import 'package:ui_kit/ui_kit.dart';
import '../orders/orders_test.dart' show OrdersFixture, ordersClient, orderJson;
import '../onboarding/onboarding_test.dart' show MemoryDrafts;
import '../addresses/addresses_test.dart' show reveal;
import '../notifications/notification_fixture.dart' show NotificationSession;

/// HTTP is simulated; transactional money/ownership evidence remains T-049.
class DeliveriesFixture extends OrdersFixture {
  DeliveriesFixture() {
    rows
      ..clear()
      ..add(orderJson(status: 'ACCEPTED'));
  }
  bool holdResponse = false;
  Completer<void>? committed;
  Completer<void>? release;
  void Function()? afterCommit;
  final sentKeys = <String>[];
  final sentBodies = <Map<String, dynamic>>[];
  @override
  Future<ResponseBody> fetch(
      RequestOptions r, Stream<Uint8List>? s, Future<void>? c) async {
    if (r.path.endsWith('/deliveries')) {
      requests.add(r);
      if (offline) {
        throw DioException(
            requestOptions: r, type: DioExceptionType.connectionError);
      }
      if (denial != null) {
        return reply({'code': 'VENDOR_ROLE_REQUIRED'}, denial!);
      }
      final selected = rows
          .where((r) => [
                'ACCEPTED',
                'PREPARING',
                'OUT_FOR_DELIVERY',
                'DELIVERED',
                'FAILED'
              ].contains(r['status']))
          .toList();
      return reply({
        'serverTime': '2026-11-14T01:00:00Z',
        'businessDate': '2026-11-14',
        'deliveryDate': '2026-11-14',
        'counts': {
          for (final t in [
            'ALL',
            'PENDING',
            'PREPARING',
            'OUT_FOR_DELIVERY',
            'DELIVERED',
            'FAILED'
          ])
            t: selected
                .where((r) =>
                    t == 'ALL' ||
                    r['status'] == (t == 'PENDING' ? 'ACCEPTED' : t))
                .length
        },
        'items': selected
            .skip(r.queryParameters['offset'] as int)
            .take(50)
            .map(detail)
            .toList(),
        'total': selected.length,
      });
    }
    if (r.method == 'POST') {
      sentKeys.add(r.headers['Idempotency-Key'] as String);
      sentBodies
          .add(Map<String, dynamic>.from(jsonDecode(r.data as String) as Map));
      if (!offline &&
          !replays.containsKey(sentKeys.last) &&
          !conflict &&
          rows.first['version'] != sentBodies.last['version']) {
        return reply({'code': 'VERSION_CONFLICT'}, 409);
      }
    }
    final response = await super.fetch(r, s, c);
    if (r.method == 'POST' && response.statusCode < 300) afterCommit?.call();
    if (holdResponse && r.method == 'POST') {
      committed?.complete();
      await release!.future;
    }
    return response;
  }
}

Widget deliveriesApp(DeliveriesController m,
        {bool queue = false, double scale = 1}) =>
    ProviderScope(
        overrides: [deliveriesProvider.overrideWith((ref) => m)],
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
            home: DeliveriesPage(queueOnly: queue)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'T-050 an open stale card uses the base version advanced by another engine',
      () async {
    final f = DeliveriesFixture(),
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    final foreground = DeliveriesController(http.dio, store, 'vendor'),
        background = DeliveriesController(http.dio, store, 'vendor');
    addTearDown(foreground.dispose);
    addTearDown(background.dispose);
    await foreground.load();
    await background.load();
    final staleCard = foreground.rows.single;
    await background.enqueue(background.rows.single, 'OUT_FOR_DELIVERY');
    expect(background.queue, isEmpty);
    await foreground
        .enqueue(staleCard, 'DELIVERED', payment: {'collected': false});
    expect(f.sentBodies.last['version'], 2);
    expect(f.commits, 2);
    expect(foreground.rows.single.status, 'DELIVERED');
  });
  test(
      'T-050 positive advance receipt follows the existing delivery API policy',
      () async {
    final f = DeliveriesFixture()..rows.first['status'] = 'OUT_FOR_DELIVERY',
        http = ordersClient(f);
    addTearDown(http.close);
    final m = DeliveriesController(http.dio, MemoryDrafts(), 'vendor');
    addTearDown(m.dispose);
    await m.load();
    await m.enqueue(m.rows.single, 'DELIVERED',
        payment: {'collected': true, 'method': 'CASH', 'amountPaise': '12021'});
    expect(f.commits, 1);
    expect(f.sentBodies.single['payment']['amountPaise'], '12021');
    expect(m.queue, isEmpty);
  });
  test(
      'T-050 registers a background wakeup before persisting new work and freezes the audit timestamp',
      () async {
    final f = DeliveriesFixture(),
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    var scheduled = 0;
    final m =
        DeliveriesController(http.dio, store, 'vendor', schedule: () async {
      scheduled++;
      final saved = jsonDecode(store.rows['vendor']!['snapshot']!) as Map;
      expect(saved['queue'], isEmpty);
      expect(f.commits, 0);
    });
    addTearDown(m.dispose);
    await m.load();
    f.offline = true;
    await m.enqueue(m.rows.single, 'OUT_FOR_DELIVERY');
    expect(scheduled, 1);
    final a = m.queue.single;
    expect(a.body['clientCreatedAt'], a.createdAt);
    expect(f.sentBodies.single['clientCreatedAt'], a.createdAt);
  });
  test(
      'T-050 stale engine reloads a durable predecessor before appending another action',
      () async {
    final f = DeliveriesFixture(),
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    final first = DeliveriesController(http.dio, store, 'vendor'),
        second = DeliveriesController(http.dio, store, 'vendor');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await first.load();
    await second.load();
    f.offline = true;
    await first.enqueue(first.rows.single, 'OUT_FOR_DELIVERY');
    final key = first.queue.single.key;
    await second.enqueue(second.rows.single, 'DELIVERED',
        payment: {'collected': false});
    expect(second.queue.length, 2);
    expect(second.queue.first.key, key);
    expect(second.queue.map((a) => a.body['version']), [1, 2]);
    final disk = jsonDecode(store.rows['vendor']!['snapshot']!) as Map;
    expect((disk['queue'] as List).length, 2);
  });
  test(
      'TC-085/086/087 server date, tabs, preparing/start and exact payment replay',
      () async {
    final f = DeliveriesFixture(),
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    final m = DeliveriesController(http.dio, store, 'vendor');
    addTearDown(m.dispose);
    await m.load();
    expect(m.date, '2026-11-14');
    expect(m.count('PENDING'), 1);
    await m.enqueue(m.rows.single, 'PREPARING');
    await m.enqueue(m.rows.single, 'OUT_FOR_DELIVERY');
    f.lost = true;
    await m.enqueue(m.rows.single, 'DELIVERED',
        payment: {'collected': true, 'method': 'UPI', 'amountPaise': '12020'});
    expect(m.queue, isNotEmpty);
    final key = m.queue.single.key;
    f.offline = false;
    m.queue.single.nextAt = null;
    await m.flush();
    expect(m.queue, isEmpty);
    expect(f.commits, 3);
    expect(f.sentKeys.last, key);
    expect(f.sentBodies.last['payment']['amountPaise'], '12020');
    expect(m.count('DELIVERED'), 1);
  });
  test(
      'TC-088 offline optimistic FIFO chain then authoritative conflict rolls back dependent updates',
      () async {
    final f = DeliveriesFixture(), http = ordersClient(f);
    addTearDown(http.close);
    final m = DeliveriesController(http.dio, MemoryDrafts(), 'vendor');
    addTearDown(m.dispose);
    await m.load();
    f.offline = true;
    await m.enqueue(m.rows.single, 'OUT_FOR_DELIVERY');
    await m.enqueue(m.rows.single, 'DELIVERED', payment: {'collected': false});
    expect(m.status(m.rows.single), 'DELIVERED');
    expect(m.queue.length, 2);
    expect(m.queue.map((a) => a.body['version']), [1, 2]);
    f.offline = false;
    f.conflict = true;
    m.queue.first.nextAt = null;
    await m.flush();
    expect(m.queue.every((a) => a.rejected), isTrue);
    expect(m.rows, isEmpty);
    expect(f.commits, 0);
    await m.discard(m.queue.first);
    expect(m.queue, isEmpty);
  });
  test(
      'TC-504 cached queue survives SENDING restart with identical key/body, owner isolation',
      () async {
    final f = DeliveriesFixture(),
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    var m = DeliveriesController(http.dio, store, 'vendor');
    await m.load();
    f.offline = true;
    await m.enqueue(m.rows.single, 'OUT_FOR_DELIVERY');
    final a = m.queue.single, savedKey = a.key, savedBody = jsonEncode(a.body);
    final snapshot = jsonDecode(store.rows['vendor']!['snapshot']!) as Map;
    (snapshot['queue'] as List).first['state'] = 'SENDING';
    store.rows['vendor']!['snapshot'] = jsonEncode(snapshot);
    m.dispose();
    m = DeliveriesController(http.dio, store, 'vendor');
    addTearDown(m.dispose);
    await m.load();
    expect(m.queue.single.key, savedKey);
    expect(jsonEncode(m.queue.single.body), savedBody);
    expect(m.status(m.rows.single), 'OUT_FOR_DELIVERY');
    final other = DeliveriesController(http.dio, store, 'other');
    addTearDown(other.dispose);
    await other.load();
    expect(other.queue, isEmpty);
    expect(other.rows, isEmpty);
    f.offline = false;
    m.queue.single.nextAt = null;
    await m.flush();
    expect(f.commits, 1);
    expect(f.sentKeys.last, savedKey);
  });
  test(
      'critical validation, disk failure and non-discardable uncertain payment',
      () async {
    final f = DeliveriesFixture()..rows.first['status'] = 'OUT_FOR_DELIVERY',
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    final m = DeliveriesController(http.dio, store, 'vendor');
    addTearDown(m.dispose);
    await m.load();
    for (final amount in ['0', '9223372036854775808', '12.20', '-1']) {
      await m.enqueue(m.rows.single, 'DELIVERED', payment: {
        'collected': true,
        'method': 'CASH',
        'amountPaise': amount
      });
      expect(m.queue, isEmpty);
    }
    await m.enqueue(m.rows.single, 'FAILED', reason: '  ');
    expect(m.queue, isEmpty);
    store.fail = true;
    await m.enqueue(m.rows.single, 'DELIVERED', payment: {'collected': false});
    expect(f.commits, 0);
    expect(m.queue, isEmpty);
    store.fail = false;
    f.offline = true;
    await m.enqueue(m.rows.single, 'DELIVERED', payment: {'collected': false});
    final a = m.queue.single;
    expect(m.canDiscard(a), isFalse);
    await m.discard(a);
    expect(m.queue.single, a);
  });
  test(
      'six failures stop automatic retries; authorization hides cache and requires explicit retry',
      () async {
    final f = DeliveriesFixture(), http = ordersClient(f);
    addTearDown(http.close);
    final m = DeliveriesController(http.dio, MemoryDrafts(), 'vendor');
    addTearDown(m.dispose);
    await m.load();
    f.offline = true;
    await m.enqueue(m.rows.single, 'OUT_FOR_DELIVERY');
    for (var i = 0; i < 5; i++) {
      m.queue.single.nextAt = null;
      await m.flush();
    }
    expect(m.queue.single.retryable, isTrue);
    final calls = f.sentKeys.length;
    await m.flush();
    expect(f.sentKeys.length, calls);
    f.offline = false;
    f.denial = 403;
    await m.flush(retry: true);
    expect(m.rows, isEmpty);
    expect(m.queue.single.retryable, isTrue);
    f.denial = null;
    await m.flush(retry: true);
    expect(m.queue, isEmpty);
    expect(f.commits, 1);
  });
  test(
      'acknowledged transition with failed local commit stops until exact disk replay',
      () async {
    final f = DeliveriesFixture(),
        http = ordersClient(f),
        store = MemoryDrafts();
    addTearDown(http.close);
    var m = DeliveriesController(http.dio, store, 'vendor');
    await m.load();
    f.afterCommit = () => store.fail = true;
    await m.enqueue(m.rows.single, 'OUT_FOR_DELIVERY');
    expect(m.canAct(m.rows.single.id), isFalse);
    expect(f.commits, 1);
    final key = f.sentKeys.single;
    m.dispose();
    store.fail = false;
    f.afterCommit = null;
    m = DeliveriesController(http.dio, store, 'vendor');
    addTearDown(m.dispose);
    await m.flush();
    expect(f.sentKeys.last, key);
    expect(f.commits, 1);
    expect(m.queue, isEmpty);
  });
  test('delivery failure preserves reason and paginated delivery cards',
      () async {
    final f = DeliveriesFixture()..rows.first['status'] = 'OUT_FOR_DELIVERY',
        http = ordersClient(f);
    addTearDown(http.close);
    for (var i = 1; i < 53; i++) {
      f.rows.add(orderJson(
          id: '88888888-8888-4888-8888-${i.toString().padLeft(12, '0')}',
          status: 'ACCEPTED'));
    }
    final m = DeliveriesController(http.dio, MemoryDrafts(), 'vendor');
    addTearDown(m.dispose);
    await m.load();
    expect(m.rows.length, 53);
    expect(m.count('PENDING'), 52);
    await m.enqueue(m.rows.first, 'FAILED', reason: '  Door locked  ');
    expect(f.sentBodies.single['reason'], 'Door locked');
    expect(m.count('FAILED'), 1);
    m.select('FAILED');
    expect(m.visible.length, 1);
  });
  testWidgets(
      'foreground scheduler flushes off-screen and resumes pending work',
      (tester) async {
    final f = DeliveriesFixture(), http = ordersClient(f);
    addTearDown(http.close);
    final m = DeliveriesController(http.dio, MemoryDrafts(), 'vendor');
    await tester.runAsync(() async {
      await m.load();
      f.offline = true;
      await m.enqueue(m.rows.single, 'OUT_FOR_DELIVERY');
      m.queue.single.nextAt = null;
    });
    await tester.pumpWidget(ProviderScope(overrides: [
      deliveriesProvider.overrideWith((ref) => m),
      sessionProvider
          .overrideWith(() => NotificationSession()..role = 'VENDOR'),
    ], child: const DeliverySyncHost(child: SizedBox())));
    final container = ProviderScope.containerOf(
        tester.element(find.byType(DeliverySyncHost)));
    expect(container.read(sessionProvider).user?.activeRole?.value, 'VENDOR');
    expect(container.read(deliveriesProvider), same(m));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    f.offline = false;
    await tester.pump(const Duration(seconds: 3));
    expect(f.commits, 0);
    await tester.runAsync(() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      for (var i = 0; i < 100 && (m.busy || m.queue.isNotEmpty); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    expect(f.commits, 1,
        reason: 'busy=${m.busy}; failure=${m.failure?.code}; '
            'states=${m.queue.map((a) => a.state).join(',')}; '
            'requests=${f.sentKeys.length}; canAct=${m.canAct(m.rows.single.id)}; nextAt=${m.queue.firstOrNull?.nextAt}');
    expect(m.queue, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'S-V-16 200% cards, payment amount validation and no text overflow',
      (tester) async {
    final f = DeliveriesFixture()..rows.first['status'] = 'OUT_FOR_DELIVERY',
        http = ordersClient(f);
    addTearDown(http.close);
    final m = DeliveriesController(http.dio, MemoryDrafts(), 'vendor');
    await tester.pumpWidget(deliveriesApp(m, scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Mark delivered'));
    await tester.tap(find.text('Mark delivered'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(TextFormField, 'Amount collected (₹)');
    await tester.enterText(field, '120.201');
    await reveal(tester, find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(f.commits, 0);
    await tester.enterText(field, '120.20');
    await reveal(tester, find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(f.commits, 1);
    expect(tester.takeException(), isNull);
  });
}
