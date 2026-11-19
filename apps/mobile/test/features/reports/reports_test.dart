// TC-095/096/097/512: focused transport, recovery, authorization and UI smoke.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/reports/reports_controller.dart';
import 'package:supplybiz_mobile/features/reports/reports_page.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import '../../core/network/reports_client_test.dart' show ReportsAdapter;
import '../../core/network/report_exports_client_test.dart' show ExportAdapter;

class Fixture extends ReportsAdapter {
  final files = ExportAdapter();
  bool offline = false,
      locked = false,
      suspended = false,
      loseCreate = false,
      expired = false,
      wrongSize = false;
  Completer<void>? gate, started;
  String exportFrom = '2026-01-01', exportTo = '2026-03-05';
  ResponseBody json(Object o, [int code = 200]) =>
      ResponseBody.fromString(jsonEncode(o), code, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    if (offline) {
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    if (suspended) return json({'code': 'VENDOR_SUSPENDED'}, 403);
    final export = o.path.contains('/exports');
    if (locked && (!o.path.endsWith('/summary') || export)) {
      return json({'code': 'PLAN_FEATURE_LOCKED'}, 403);
    }
    if (export) {
      if (o.method == 'POST') {
        final body = jsonDecode(o.data as String) as Map;
        exportFrom = body['from'] as String;
        exportTo = body['to'] as String;
      }
      final result = await files.fetch(o, s, c);
      if (o.method == 'POST' && loseCreate) {
        loseCreate = false;
        throw DioException(
            requestOptions: o, type: DioExceptionType.receiveTimeout);
      }
      if (o.path.endsWith('/download') || o.method == 'POST') return result;
      final body = jsonDecode(await utf8.decoder.bind(result.stream).join())
          as Map<String, dynamic>;
      return json({
        ...body, 'from': exportFrom, 'to': exportTo,
        'status': expired ? 'EXPIRED' : 'READY',
        'sizeBytes': wrongSize ? files.csv.length + 1 : files.csv.length,
        // An arbitrary server path must never be fetched by the app.
        'downloadPath': 'https://untrusted.example.test/other.csv'
      });
    }
    if (o.path.endsWith('/summary') && gate != null) {
      started?.complete();
      await gate!.future;
    }
    final result = await super.fetch(o, s, c);
    final body = jsonDecode(await utf8.decoder.bind(result.stream).join())
        as Map<String, dynamic>;
    return json({
      ...body,
      if (o.queryParameters['from'] != null) 'from': o.queryParameters['from'],
      if (o.queryParameters['to'] != null) 'to': o.queryParameters['to']
    });
  }
}

(ReportsController, NetworkClient) model(Fixture f, MemoryDrafts store,
    {String owner = 'test:vendor', ShareReport? share}) {
  final client = NetworkClient(
      baseUrl: 'https://api.example.test',
      session: TestSession(),
      adapter: f,
      delay: (_) async {});
  final m = ReportsController(client, store, owner,
      share: share ?? (_, __) async => true);
  return (m, client);
}

void cleanup((ReportsController, NetworkClient) pair) {
  pair.$1.dispose();
  pair.$2.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));
  test(
      'inclusive 366-day maximum, leap dates and strict ordered calendar dates',
      () {
    expect(validReportRange('2024-01-01', '2024-12-31'), isTrue);
    expect(validReportRange('2024-01-01', '2025-01-01'), isFalse);
    for (final v in [
      ('2026-02-29', '2026-03-01'),
      ('2026-11-20', '2026-11-19'),
      ('0000-01-01', '0000-01-02'),
      ('2026-1-01', '2026-01-01')
    ]) {
      expect(validReportRange(v.$1, v.$2), isFalse);
    }
  });
  test(
      'exact values, pagination and locked tier preserves summary but removes advanced data',
      () async {
    final f = Fixture(), p = model(f, MemoryDrafts()), m = p.$1;
    addTearDown(() => cleanup(p));
    await m.load();
    expect(m.summary!.totalSalesPaise, '9007199254740993');
    expect(m.summary!.totalEarningsPaise, '-9007199254740993');
    expect(m.daily!.bucket.value, 'WEEK');
    await m.page(20);
    expect(f.calls.last.queryParameters['offset'], 20);
    expect(m.products!.items.single.quantityPacks, '9007199254740993');
    f.locked = true;
    await m.load();
    expect(m.locked, isTrue);
    expect(m.summary, isNotNull);
    expect(m.daily, isNull);
    expect(m.products, isNull);
    await m.exportCsv();
    expect(f.files.calls, isEmpty);
  });
  test(
      'offline cached summary is labelled stale, blocks export, isolates account and clears on suspension',
      () async {
    final store = MemoryDrafts(), f = Fixture(), p = model(f, store);
    await p.$1.load();
    cleanup(p);
    f.offline = true;
    final q = model(f, store);
    addTearDown(() => cleanup(q));
    await q.$1.load();
    expect(q.$1.summary, isNotNull);
    expect(q.$1.stale, isTrue);
    await q.$1.exportCsv();
    expect(f.files.calls, isEmpty);
    final other = model(f, store, owner: 'test:other-vendor');
    addTearDown(() => cleanup(other));
    await other.$1.load();
    expect(other.$1.summary, isNull);
    f.offline = false;
    f.suspended = true;
    await q.$1.load();
    expect(q.$1.summary, isNull);
    expect(store.rows['test:vendor'], isEmpty);
  });
  test(
      'lost create response survives recreation; exact key/body and bytes remain frozen after filter change',
      () async {
    final f = Fixture(), store = MemoryDrafts();
    var shared = 0;
    final p = model(f, store);
    await p.$1.load();
    f.loseCreate = true;
    await p.$1.exportCsv();
    expect(p.$1.hasPending, isTrue);
    cleanup(p);
    final first = f.files.calls.single;
    final q = model(f, store, share: (s, bytes) async {
      shared++;
      expect(bytes, f.files.csv);
      expect(s.from, DateTime(2026, 1, 1));
      return true;
    });
    addTearDown(() => cleanup(q));
    await q.$1.load(from: '2026-11-01', to: '2026-11-19');
    await q.$1.exportCsv();
    final second = f.files.calls.where((e) => e.method == 'POST').last;
    expect(second.headers['Idempotency-Key'], first.headers['Idempotency-Key']);
    expect(second.data, first.data);
    expect(shared, 1);
    expect(f.files.calls.last.path,
        endsWith('/exports/11111111-1111-4111-8111-111111111111/download'));
    expect(q.$1.chooserOpened, isTrue);
    await q.$1.resetExport();
    expect(q.$1.hasPending, isFalse);
  });
  test(
      'failed durable key write sends nothing; expired export never downloads or shares',
      () async {
    final f = Fixture(), store = MemoryDrafts(), p = model(f, store);
    addTearDown(() => cleanup(p));
    await p.$1.load();
    store.fail = true;
    await p.$1.exportCsv();
    expect(f.files.calls, isEmpty);
    expect(p.$1.hasPending, isTrue);
    store.fail = false;
    f.expired = true;
    await p.$1.exportCsv();
    expect(p.$1.exportExpired, isTrue);
    expect(p.$1.chooserOpened, isFalse);
    expect(f.files.calls.where((e) => e.path.endsWith('/download')), isEmpty);
  });
  test(
      'live export downgrade removes detail and byte size mismatch cannot reach native share',
      () async {
    var shared = 0;
    final f = Fixture(),
        p = model(f, MemoryDrafts(), share: (_, __) async {
          shared++;
          return true;
        });
    addTearDown(() => cleanup(p));
    await p.$1.load();
    f.locked = true;
    await p.$1.exportCsv();
    expect(p.$1.locked, isTrue);
    expect(p.$1.daily, isNull);
    expect(shared, 0);
    f.locked = false;
    await p.$1.load();
    f.wrongSize = true;
    await p.$1.exportCsv();
    expect(p.$1.exportFailure, isNotNull);
    expect(shared, 0);
  });
  test('disposed controller cannot publish late summary or overwrite cache',
      () async {
    final f = Fixture(), store = MemoryDrafts(), p = model(f, store);
    f.gate = Completer<void>();
    f.started = Completer<void>();
    final flight = p.$1.load();
    await f.started!.future;
    p.$1.dispose();
    f.gate!.complete();
    await flight;
    p.$2.close();
    expect(p.$1.summary, isNull);
    expect(store.rows, isEmpty);
  });
  testWidgets(
      '200% summary and horizontally scrollable tables render without overflow; locked guidance appears',
      (t) async {
    final f = Fixture(), p = model(f, MemoryDrafts());
    await t.runAsync(p.$1.load);
    await t.pumpWidget(ProviderScope(
        overrides: [reportsProvider.overrideWith((ref) => p.$1)],
        child: MaterialApp(
            theme: sbLightTheme(const Locale('en')),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...SbLocalizations.delegates
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!),
            home: const ReportsPage())));
    await t.pump();
    await t.runAsync(() async {
      while (p.$1.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
        find.byKey(const ValueKey('reports-metric-Total sales')), 350,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    expect(find.textContaining('9,00,71,99,25,47,409.93'), findsWidgets);
    await t.scrollUntilVisible(find.text('Weekly sales'), 400,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    expect(find.byType(DataTable), findsWidgets);
    expect(t.takeException(), isNull);
    f.locked = true;
    await t.runAsync(p.$1.load);
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
        find.textContaining('Contact support for a plan change.'), -400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('View plans'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    p.$2.close();
  });
}
