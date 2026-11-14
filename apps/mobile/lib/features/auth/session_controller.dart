import 'dart:async';

import 'package:dio/dio.dart';
import 'package:device_coordination/device_coordination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';

import '../../core/config/app_environment.dart';
import '../../core/config/app_config.dart';
import '../../core/network/app_failure.dart';
import '../../core/network/network_client.dart';
import '../../core/storage/app_storage.dart';
import 'auth_repository.dart';

class AuthConfig {
  const AuthConfig(
      {required this.baseUrl,
      this.termsVersion = '',
      this.terms = '',
      this.privacyVersion = '',
      this.privacy = ''});
  final String baseUrl, termsVersion, terms, privacyVersion, privacy;
  bool get consentAvailable =>
      termsVersion.isNotEmpty &&
      termsVersion.length <= 50 &&
      privacyVersion.isNotEmpty &&
      privacyVersion.length <= 50 &&
      terms.isNotEmpty &&
      privacy.isNotEmpty;
}

final authConfigProvider = Provider<AuthConfig>((ref) => AuthConfig(
    baseUrl: AppEnvironment.dev.apiBaseUrl,
    termsVersion: const String.fromEnvironment('TERMS_VERSION'),
    terms: const String.fromEnvironment('TERMS_TEXT'),
    privacyVersion: const String.fromEnvironment('PRIVACY_VERSION'),
    privacy: const String.fromEnvironment('PRIVACY_TEXT')));
final authStorageProvider =
    Provider<AuthStorage>((ref) => DeviceAuthStorage(AppStorage.instance));
final authAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);
final sessionProvider =
    NotifierProvider<SessionController, AuthState>(SessionController.new);

class AuthState {
  const AuthState(
      {this.ready = false,
      this.busy = false,
      this.user,
      this.failure,
      this.challenge = false,
      this.mobile = '',
      this.channel = 'SMS',
      this.retryAt});
  final bool ready, busy, challenge;
  final MeResponse? user;
  final AppFailure? failure;
  final String mobile, channel;
  final DateTime? retryAt;
  AuthState copy(
          {bool? ready,
          bool? busy,
          MeResponse? user,
          bool clearUser = false,
          AppFailure? failure,
          bool? challenge,
          String? mobile,
          String? channel,
          DateTime? retryAt}) =>
      AuthState(
          ready: ready ?? this.ready,
          busy: busy ?? this.busy,
          user: clearUser ? null : user ?? this.user,
          failure: failure,
          challenge: challenge ?? this.challenge,
          mobile: mobile ?? this.mobile,
          channel: channel ?? this.channel,
          retryAt: retryAt ?? this.retryAt);
}

/// Owns memory-only access tokens; generation checks fence late refresh/login results after logout.
class SessionController extends Notifier<AuthState> implements NetworkSession {
  late AuthStorage _storage;
  late AuthRepository repository;
  late AuthConfig config;
  String? _access;
  int _generation = 0;
  bool _disposed = false;
  Future<void>? _refreshing;
  @override
  String? get accessToken => _access;
  @override
  AuthState build() {
    _storage = ref.read(authStorageProvider);
    config = ref.read(authConfigProvider);
    // Generated paths already include /api/v1; Dio concatenates base-path prefixes.
    final api = Uri.parse(config.baseUrl);
    if (api.path.replaceFirst(RegExp(r'/$'), '') != '/api/v1') {
      throw ArgumentError('The configured API base path must be /api/v1.');
    }
    final client = NetworkClient(
        baseUrl: api.replace(path: '').toString(),
        session: this,
        appVersion: () => ref.read(configProvider).version,
        onUpgradeRequired: () =>
            ref.read(configProvider.notifier).requireUpdate(),
        adapter: ref.read(authAdapterProvider));
    repository = AuthRepository(client);
    ref.onDispose(() {
      _disposed = true;
      _generation++;
      client.close();
    });
    return const AuthState();
  }

  bool _current(int generation) => !_disposed && generation == _generation;
  Future<T> _storageLock<T>(Future<T> Function() action) =>
      _storage is CoordinatedAuthStorage
          ? (_storage as CoordinatedAuthStorage).exclusiveSession(action)
          : action();
  Future<void> restore() async {
    if (state.busy) return;
    state = state.copy(busy: true);
    final generation = _generation;
    try {
      await _storageLock(() async {
        await _storage.initialize();
        if (await _storage.readRefreshToken() != null) await refresh();
      });
      if (_current(generation)) state = state.copy(ready: true, busy: false);
    } catch (error) {
      if (_current(generation)) {
        state = state.copy(ready: false, busy: false, failure: _failure(error));
      }
    }
  }

  AppFailure _failure(Object error) =>
      error is AppFailure ? error : const UnknownFailure();
  Future<void> _run(Future<void> Function(int generation) action) async {
    if (state.busy) return;
    final generation = _generation;
    state = state.copy(busy: true);
    try {
      await action(generation);
    } catch (error) {
      if (_current(generation)) {
        final failure = _failure(error);
        state = state.copy(
            failure: failure,
            retryAt: failure is BusinessRuleFailure &&
                    failure.retryAfterSeconds != null
                ? DateTime.now()
                    .add(Duration(seconds: failure.retryAfterSeconds!))
                : null);
      }
    } finally {
      if (_current(generation)) {
        state = state.copy(busy: false, failure: state.failure);
      }
    }
  }

  Future<void> send(String mobile, String channel,
          {required bool consentAccepted, String? appHash}) =>
      _run((generation) async {
        final normalized = mobile.replaceAll(RegExp(r'\s'), '');
        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(normalized) ||
            !config.consentAvailable ||
            !consentAccepted) {
          throw const BusinessRuleFailure(code: 'CONSENT_UNAVAILABLE');
        }
        final device = await _storage.installationId();
        await repository.send(normalized, channel, device, appHash);
        if (_current(generation)) {
          state = state.copy(
              mobile: normalized,
              channel: channel,
              challenge: true,
              retryAt: DateTime.now().add(const Duration(seconds: 30)));
        }
      });
  Future<void> verify(String code) => _run((generation) async {
        if (!state.challenge ||
            !RegExp(r'^\d{6}$').hasMatch(code) ||
            !config.consentAvailable) {
          return;
        }
        final tokens = await repository.verify(
            state.mobile,
            code,
            ConsentDto(
                termsVersion: config.termsVersion,
                privacyVersion: config.privacyVersion));
        await _accept(tokens, generation);
      });
  void changeNumber() {
    if (!state.busy) state = AuthState(ready: true, mobile: state.mobile);
  }

  Future<void> _accept(TokensResponse tokens, int generation) =>
      _storageLock(() async {
        if (!_current(generation)) return;
        await _storage.initialize();
        if (!_current(generation)) return;
        // AppStorage serializes persistence with a concurrent logout wipe.
        await _storage.writeRefreshToken(tokens.refreshToken);
        if (!_current(generation)) return;
        _access = tokens.accessToken;
        state = state.copy(user: tokens.user, challenge: false, ready: true);
      });

  @override
  Future<void> refresh() async {
    // A foreground refresh may already be waiting for the lease held by a
    // delivery request. That request must not join the waiting flight on 401:
    // rotate under its current lease, then the waiter reads the latest token.
    if (_storage is CoordinatedAuthStorage && DeviceCoordination.isHeld) {
      await _rotate();
      return;
    }
    final flight = _refreshing ??= _rotate();
    try {
      await flight;
    } finally {
      if (identical(_refreshing, flight)) _refreshing = null;
    }
  }

  Future<void> _rotate() async {
    final generation = _generation;
    try {
      await _storageLock(() async {
        if (!_current(generation)) return;
        final token = await _storage.readRefreshToken();
        if (token == null) throw const UnauthorizedFailure();
        final tokens = await repository.refresh(token);
        await _accept(tokens, generation);
      });
    } on UnauthorizedFailure catch (failure) {
      if (_current(generation)) await clear(reason: failure);
      rethrow;
    }
  }

  Future<void> selectRole(String role) => _run((generation) async {
        final user = state.user;
        if (user == null || !{'CUSTOMER', 'VENDOR'}.contains(role)) return;
        final changed = await repository.role(role,
            held: user.roles.any((held) => held.value == role));
        if (_current(generation)) state = state.copy(user: changed);
      });
  Future<void> revalidate() => _run((generation) async {
        if (state.user == null) return;
        final user = await repository.currentUser();
        if (_current(generation)) state = state.copy(user: user);
      });
  Future<void> logout({bool all = false}) => _run((generation) async {
        try {
          await repository.logout(all);
        } on UnauthorizedFailure {
          /* Already revoked: local secrets must still be erased. */
        }
        await clear();
      });
  @override
  Future<void> clear({AppFailure? reason}) async {
    _generation++;
    _access = null;
    state = AuthState(ready: true, failure: reason);
    try {
      await _storageLock(() => _storage.wipeOnLogout());
    } catch (_) {
      state = state.copy(
          failure: const UnknownFailure(code: 'STORAGE_CLEANUP_REQUIRED'));
      rethrow;
    }
  }
}
