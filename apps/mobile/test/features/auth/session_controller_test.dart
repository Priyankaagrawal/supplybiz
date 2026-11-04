import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import 'package:supplybiz_mobile/core/network/app_failure.dart';
import 'auth_fixture.dart';

void main() {
  late ProviderContainer container;
  late AuthFixture api;
  late MemoryAuthStorage storage;
  late SessionController session;
  setUp(() {
    api = AuthFixture();
    storage = MemoryAuthStorage();
    container = ProviderContainer(overrides: [
      authConfigProvider.overrideWithValue(testAuthConfig),
      authStorageProvider.overrideWithValue(storage),
      authAdapterProvider.overrideWithValue(api)
    ]);
    session = container.read(sessionProvider.notifier);
  });
  tearDown(() => container.dispose());
  Future<void> login() async {
    await session.restore();
    await session.send('9000000000', 'SMS', consentAccepted: true);
    await session.verify('123456');
  }

  test(
      'TC-001/013 refuses invalid mobile and missing consent before any network mutation',
      () async {
    await session.send('5000000000', 'SMS', consentAccepted: true);
    await session.send('9000000000', 'SMS', consentAccepted: false);
    expect(api.calls, isEmpty);
    expect(storage.token, isNull);
  });
  test(
      'TC-001/007/013 sends normalized phone/channel/device/idempotency and versioned consent',
      () async {
    await session.restore();
    await session.send('90000 00000', 'WHATSAPP', consentAccepted: true);
    expect(container.read(sessionProvider).challenge, isTrue);
    final sent = api.calls.last;
    expect(api.body(sent), {'mobile': '9000000000', 'channel': 'WHATSAPP'});
    expect(sent.headers['X-Device-Id'], 'synthetic-installation');
    expect(sent.headers['Idempotency-Key'], isNotEmpty);
    expect(sent.headers.containsKey('Authorization'), isFalse);
    await session.verify('123456');
    expect(api.body(api.calls.last)['consent'],
        {'termsVersion': 'synthetic-v1', 'privacyVersion': 'synthetic-v1'});
    expect(session.accessToken, 'synthetic-access-0');
    expect(storage.token, 'synthetic-refresh-0');
    expect(container.read(sessionProvider).user?.activeRole, isNull);
  });
  test(
      'TC-006 preserves server rate-limit wait time; failed send cannot advance to OTP',
      () async {
    api.sendStatus = 429;
    await session.send('9000000000', 'SMS', consentAccepted: true);
    final state = container.read(sessionProvider);
    expect(state.failure?.code, 'RATE_LIMITED');
    expect(state.challenge, isFalse);
    expect(state.retryAt!.difference(DateTime.now()).inSeconds,
        greaterThanOrEqualTo(58));
  });
  test(
      'TC-003 invalid OTP never establishes a session; change number retains phone',
      () async {
    api.verifyStatus = 422;
    await login();
    expect(container.read(sessionProvider).failure?.code, 'OTP_INVALID');
    expect(session.accessToken, isNull);
    expect(storage.token, isNull);
    session.changeNumber();
    expect(container.read(sessionProvider).mobile, '9000000000');
    expect(container.read(sessionProvider).challenge, isFalse);
  });
  test(
      'TC-009 refresh is single-flight and persists only the rotated refresh token',
      () async {
    await login();
    api.refreshGate = Completer<void>();
    final one = session.refresh(), two = session.refresh();
    await api.refreshStarted.future;
    expect(api.refreshes, 1);
    api.refreshGate!.complete();
    await Future.wait([one, two]);
    expect(storage.token, 'synthetic-refresh-1');
    expect(session.accessToken, 'synthetic-access-1');
    expect(api.calls.last.headers.containsKey('Authorization'), isFalse);
  });
  test('TC-010 late refresh response cannot restore tokens after logout wipe',
      () async {
    await login();
    api.refreshGate = Completer<void>();
    final refreshing = session.refresh();
    await api.refreshStarted.future;
    await session.clear();
    api.refreshGate!.complete();
    await refreshing;
    expect(storage.token, isNull);
    expect(session.accessToken, isNull);
    expect(container.read(sessionProvider).user, isNull);
    expect(storage.wipes, 1);
  });
  test('TC-009 reuse clears local credentials and encrypted data', () async {
    await login();
    api.refreshStatus = 401;
    await expectLater(session.refresh(), throwsA(isA<UnauthorizedFailure>()));
    expect(storage.token, isNull);
    expect(session.accessToken, isNull);
    expect(container.read(sessionProvider).user, isNull);
    expect(storage.wipes, 1);
  });
  test(
      'TC-008 role changes use server user and preserve an authenticated session',
      () async {
    await login();
    await session.selectRole('VENDOR');
    expect(container.read(sessionProvider).user?.activeRole?.value, 'VENDOR');
    expect(api.calls.where((call) => call.uri.path.endsWith('/roles')),
        hasLength(1));
    await session.selectRole('VENDOR');
    expect(api.calls.where((call) => call.uri.path.endsWith('/roles')),
        hasLength(1));
    expect(session.accessToken, isNotNull);
  });
  test('TC-010 logout all sends authenticated mutation then wipes local state',
      () async {
    await login();
    await session.logout(all: true);
    expect(api.calls.last.uri.path, '/api/v1/auth/logout');
    expect(api.calls.last.queryParameters['all'], 'true');
    expect(
        api.calls.last.headers['Authorization'], 'Bearer synthetic-access-0');
    expect(storage.wipes, 1);
    expect(storage.token, isNull);
    expect(container.read(sessionProvider).user, isNull);
  });
  test(
      'TC-008/009 cold start restores server roles using persisted refresh only',
      () async {
    storage.token = 'synthetic-persisted-refresh';
    api.roles.add('VENDOR');
    api.activeRole = 'VENDOR';
    await session.restore();
    expect(container.read(sessionProvider).ready, isTrue);
    expect(container.read(sessionProvider).user?.activeRole?.value, 'VENDOR');
    expect(api.calls, hasLength(1));
    expect(api.calls.single.uri.path, '/api/v1/auth/refresh');
    expect(storage.token, 'synthetic-refresh-1');
  });
  test(
      'offline cold start preserves refresh token and requires retry before another account login',
      () async {
    storage.token = 'synthetic-persisted-refresh';
    api.refreshStatus = 503;
    await session.restore();
    expect(container.read(sessionProvider).ready, isFalse);
    expect(container.read(sessionProvider).failure, isA<ServerFailure>());
    expect(storage.token, 'synthetic-persisted-refresh');
    expect(storage.wipes, 0);
    api.refreshStatus = 200;
    await session.restore();
    expect(container.read(sessionProvider).ready, isTrue);
    expect(container.read(sessionProvider).user, isNotNull);
  });
}
