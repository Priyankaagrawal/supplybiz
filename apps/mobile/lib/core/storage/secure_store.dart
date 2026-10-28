import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-bound secrets only. Access tokens belong in session memory (T-015).
class SecureStore {
  SecureStore({FlutterSecureStorage? backend})
      : _backend = backend ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: false),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _backend;
  static const _dbKey = 'supplybiz.db_key';
  static const _refreshToken = 'supplybiz.refresh_token';
  static const _wipePending = 'supplybiz.wipe_pending';

  Future<String?> readDatabaseKey() => _backend.read(key: _dbKey);

  Future<String> createDatabaseKey() async {
    final random = Random.secure();
    final key = List.generate(
            32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    await _backend.write(key: _dbKey, value: key);
    return key;
  }

  Future<String?> readRefreshToken() => _backend.read(key: _refreshToken);
  Future<void> writeRefreshToken(String value) =>
      _backend.write(key: _refreshToken, value: value);
  Future<bool> get wipePending async =>
      await _backend.read(key: _wipePending) == 'true';
  Future<void> markWipePending() =>
      _backend.write(key: _wipePending, value: 'true');

  // Remove the recovery marker last, so interrupted cleanup resumes on startup.
  Future<void> clear() async {
    await _backend.delete(key: _refreshToken);
    await _backend.delete(key: _dbKey);
    await _backend.delete(key: _wipePending);
  }
}
