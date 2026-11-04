import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:supplybiz_mobile/features/auth/auth_repository.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';

const testAuthConfig = AuthConfig(
    baseUrl: 'https://api.example.test/api/v1',
    termsVersion: 'synthetic-v1',
    privacyVersion: 'synthetic-v1',
    terms: 'Synthetic test terms',
    privacy: 'Synthetic test privacy');

class MemoryAuthStorage implements AuthStorage {
  String? token;
  int wipes = 0;
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> readRefreshToken() async => token;
  @override
  Future<void> writeRefreshToken(String value) async {
    token = value;
  }

  @override
  Future<void> wipeOnLogout() async {
    wipes++;
    token = null;
  }

  @override
  Future<String> installationId() async => 'synthetic-installation';
}

class AuthFixture implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  int refreshes = 0;
  int refreshStatus = 200;
  int sendStatus = 200;
  int verifyStatus = 200;
  Completer<void>? refreshGate;
  final refreshStarted = Completer<void>();
  String? activeRole;
  final roles = <String>[];
  Map<String, Object?> get user => {
        'id': '11111111-1111-4111-8111-111111111111',
        'mobile': '+919000000000',
        'name': null,
        'language': 'EN',
        'roles': [...roles],
        'activeRole': activeRole
      };
  Map<String, Object?> tokens() => {
        'accessToken': 'synthetic-access-$refreshes',
        'refreshToken': 'synthetic-refresh-$refreshes',
        'expiresInSec': 900,
        'user': user
      };
  Map<String, dynamic> body(RequestOptions options) => options.data == null
      ? {}
      : jsonDecode(options.data as String) as Map<String, dynamic>;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    calls.add(options);
    final path = options.uri.path;
    var status = 200;
    Object data = user;
    if (path.endsWith('/otp/send')) {
      status = sendStatus;
      data = status == 200
          ? {'resendAfterSec': 30, 'expiresInSec': 300}
          : {'code': 'RATE_LIMITED', 'retryAfterSec': 60};
    } else if (path.endsWith('/otp/verify')) {
      status = verifyStatus;
      data = status == 200 ? tokens() : {'code': 'OTP_INVALID'};
    } else if (path.endsWith('/refresh')) {
      refreshes++;
      if (!refreshStarted.isCompleted) refreshStarted.complete();
      await refreshGate?.future;
      status = refreshStatus;
      data = status == 200 ? tokens() : {'code': 'REFRESH_REUSED'};
    } else if (path.endsWith('/logout')) {
      status = 204;
      data = '';
    } else if (path.endsWith('/roles') || path.endsWith('/active-role')) {
      final role = body(options)['role'] as String;
      if (!roles.contains(role)) roles.add(role);
      if (path.endsWith('/active-role')) activeRole = role;
      data = user;
    }
    return ResponseBody.fromString(
        status == 204 ? '' : jsonEncode(data), status,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}
