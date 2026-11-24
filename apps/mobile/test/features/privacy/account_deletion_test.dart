// T-019 / TC-012. Simulated HTTP; native API/OTP/database checks are separate.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/privacy/account_deletion.dart';
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show TestSession;

class Fixture implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  bool offline = false, loseConfirm = false;
  int? confirmStatus;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? s, Future<void>? cancel) async {
    calls.add(o);
    ResponseBody json(Object body, [int status = 200]) =>
        ResponseBody.fromString(jsonEncode(body), status, headers: {
          Headers.contentTypeHeader: ['application/json']
        });
    if (offline ||
        (loseConfirm && o.method == 'POST' && o.path.endsWith('/deletion'))) {
      throw DioException(
          requestOptions: o, type: DioExceptionType.connectionError);
    }
    if (o.method == 'GET') {
      return json(
          {'vendor': true, 'outstandingReceivablesPaise': '9007199254740993'});
    }
    if (o.path.endsWith('/otp')) {
      return json({'resendAfterSec': 30, 'expiresInSec': 300});
    }
    if (confirmStatus != null) {
      return json({'code': 'OTP_INVALID'}, confirmStatus!);
    }
    return json({
      'requestId': '11111111-1111-4111-8111-111111111111',
      'requestedAt': '2026-11-24T00:00:00Z',
      'eraseBy': '2026-12-24T00:00:00Z',
      'status': 'PENDING_ERASURE'
    });
  }
}

NetworkClient client(Fixture f) => NetworkClient(
    baseUrl: 'https://api.example.invalid',
    session: TestSession(),
    adapter: f,
    delay: (_) async {});
Widget host(DeletionController model) => ProviderScope(
    overrides: [accountDeletionProvider.overrideWith((ref) => model)],
    child: MaterialApp(
        theme: sbLightTheme(const Locale('en')),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...SbLocalizations.delegates
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: const AccountDeletionPage()));
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'owned deletion transport preserves exact dues, device and distinct mutation keys',
      () async {
    final f = Fixture(), c = client(f);
    var cleared = 0;
    final m = DeletionController(c, () async => 'synthetic-device', () async {
      cleared++;
    });
    addTearDown(c.close);
    addTearDown(m.dispose);
    await m.load();
    expect(m.preview!.outstandingReceivablesPaise, '9007199254740993');
    await m.send();
    await m.confirm('123456', true);
    expect(cleared, 1);
    expect(
        f.calls
            .where((o) => o.method == 'POST')
            .every((o) => o.headers['Idempotency-Key'] != null),
        isTrue);
    final otp = f.calls.firstWhere((o) => o.path.endsWith('/otp'));
    expect(otp.headers['X-Device-Id'], 'synthetic-device');
    expect(otp.data, isNull);
  });
  test(
      'uncertain response keeps exact body/key in memory and requires explicit retry',
      () async {
    final f = Fixture(), c = client(f);
    var cleared = 0;
    final m = DeletionController(c, () async => 'synthetic-device', () async {
      cleared++;
    });
    addTearDown(c.close);
    addTearDown(m.dispose);
    await m.load();
    await m.send();
    f.loseConfirm = true;
    await m.confirm('123456', true);
    expect(m.uncertain, isTrue);
    expect(m.canSend, isFalse);
    expect(cleared, 0);
    f.loseConfirm = false;
    await m.confirm('654321', false);
    final calls = f.calls
        .where((o) => o.path.endsWith('/deletion') && o.method == 'POST')
        .toList();
    expect(calls, hasLength(2));
    expect(calls[0].data, calls[1].data);
    expect(calls[0].headers['Idempotency-Key'],
        calls[1].headers['Idempotency-Key']);
    expect(cleared, 1);
  });
  test(
      'invalid or expired OTP unlocks correction; failed send never enables confirmation',
      () async {
    final f = Fixture(), c = client(f);
    var cleared = 0;
    final m = DeletionController(c, () async => 'synthetic-device', () async {
      cleared++;
    });
    addTearDown(c.close);
    addTearDown(m.dispose);
    await m.load();
    f.offline = true;
    await m.send();
    expect(m.sent, isFalse);
    f.offline = false;
    await m.send();
    f.confirmStatus = 422;
    await m.confirm('123456', true);
    expect(m.uncertain, isFalse);
    f.confirmStatus = null;
    await m.confirm('654321', true);
    expect(cleared, 1);
  });
  testWidgets(
      '200% screen warns exactly, requires acknowledgement and explicit final confirmation',
      (t) async {
    final f = Fixture(), c = client(f);
    var cleared = 0;
    final m = DeletionController(c, () async => 'synthetic-device', () async {
      cleared++;
    });
    addTearDown(c.close);
    await t.pumpWidget(host(m));
    await t.pumpAndSettle();
    expect(m.preview, isNotNull);
    await t.scrollUntilVisible(find.textContaining('9007199254740993'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('9007199254740993'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.scrollUntilVisible(find.byType(CheckboxListTile), 250,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.byType(CheckboxListTile));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Send deletion OTP'), 250,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Send deletion OTP'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byType(TextField), 250,
        scrollable: find.byType(Scrollable).first);
    await t.enterText(find.byType(TextField), '123456');
    await t.pump();
    await t.scrollUntilVisible(find.text('Delete my account'), 250,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Delete my account'));
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(cleared, 0);
    await t.tap(find.text('Delete my account').last);
    await t.pumpAndSettle();
    expect(cleared, 1);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
