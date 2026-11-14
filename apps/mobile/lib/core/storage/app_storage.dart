import 'dart:async';
import 'dart:io';
import 'package:device_coordination/device_coordination.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'secure_store.dart';

/// One owner per Flutter engine. T-050 coordinates the background engine with
/// session rotation/logout and delivery writes using DeviceCoordination.
/// T-015 calls [wipeOnLogout] after invalidating its
/// in-memory session and draining/cancelling requests and feature DB consumers.
class AppStorage {
  AppStorage({
    SecureStore? secrets,
    Future<Directory> Function()? directory,
    AppDatabase Function(String path, String key)? databaseFactory,
  })  : _secrets = secrets ?? SecureStore(),
        _directory = directory ?? getApplicationSupportDirectory,
        _databaseFactory = databaseFactory ?? _encryptedDatabase;

  static final instance = AppStorage();
  final SecureStore _secrets;
  final Future<Directory> Function() _directory;
  final AppDatabase Function(String, String) _databaseFactory;
  Future<void> _tail = Future.value();
  AppDatabase? _database;
  String? _openedKey;
  bool _blocked = false;

  AppDatabase get database {
    final database = _database;
    if (database == null || _blocked) {
      throw StateError('Local storage is unavailable.');
    }
    return database;
  }

  static AppDatabase _encryptedDatabase(String path, String key) =>
      AppDatabase.encrypted(path, key);

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<String> _path() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return p.join(directory.path, 'supplybiz.sqlite');
  }

  Future<void> initialize() =>
      DeviceCoordination.exclusive(() => _serial(() async {
            if (await _secrets.wipePending) await _wipe();
            if (_blocked) {
              throw StateError('Local storage cleanup is required.');
            }
            if (_database != null) {
              if (await _secrets.readDatabaseKey() == _openedKey) return;
              await _database!.close();
              _database = null;
              _openedKey = null;
            }
            final path = await _path();
            var key = await _secrets.readDatabaseKey();
            // A lost key must never silently discard an existing user's data.
            if (key == null && await File(path).exists()) {
              throw StateError('Local database key is unavailable.');
            }
            key ??= await _secrets.createDatabaseKey();
            if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(key)) {
              throw StateError('Invalid local database key.');
            }
            final database = _databaseFactory(path, key);
            try {
              await database.open();
              _database = database;
              _openedKey = key;
            } catch (_) {
              await database.close();
              rethrow;
            }
          }));

  /// Fence a stale engine after another engine wipes or rotates the DB key.
  Future<void> validateCurrent() => _serial(() async {
        database;
        if (await _secrets.wipePending ||
            await _secrets.readDatabaseKey() != _openedKey) {
          await _database?.close();
          _database = null;
          _openedKey = null;
          throw StateError('Local storage session changed.');
        }
      });

  Future<String?> readRefreshToken() => _serial(() async {
        if (_blocked || await _secrets.wipePending) {
          throw StateError('Local storage cleanup is required.');
        }
        return _secrets.readRefreshToken();
      });

  Future<String> installationId() => _serial(_secrets.installationId);

  Future<void> writeRefreshToken(String token) => _serial(() async {
        // Session generation checks still belong to T-015 before this call.
        database;
        await _secrets.writeRefreshToken(token);
      });

  Future<void> wipeOnLogout() {
    _blocked = true;
    return DeviceCoordination.exclusive(() => _serial(_wipe));
  }

  Future<void> close() => _serial(() async {
        final database = _database;
        await database?.close();
        _database = null;
        _openedKey = null;
      });

  Future<void> _wipe() async {
    _blocked = true;
    await _secrets.markWipePending();
    final database = _database;
    await database?.close();
    _database = null;
    _openedKey = null;
    final path = await _path();
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final file = File('$path$suffix');
      if (await file.exists()) await file.delete();
    }
    await _secrets.clear();
    _blocked = false;
  }
}
