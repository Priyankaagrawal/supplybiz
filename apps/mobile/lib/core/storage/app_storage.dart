import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'secure_store.dart';

/// One owner per app process. T-015 calls [wipeOnLogout] after invalidating its
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

  Future<void> initialize() => _serial(() async {
        if (await _secrets.wipePending) await _wipe();
        if (_blocked) throw StateError('Local storage cleanup is required.');
        if (_database != null) return;
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
        } catch (_) {
          await database.close();
          rethrow;
        }
      });

  Future<String?> readRefreshToken() => _serial(() async {
        if (_blocked || await _secrets.wipePending) {
          throw StateError('Local storage cleanup is required.');
        }
        return _secrets.readRefreshToken();
      });

  Future<void> writeRefreshToken(String token) => _serial(() async {
        // Session generation checks still belong to T-015 before this call.
        database;
        await _secrets.writeRefreshToken(token);
      });

  Future<void> wipeOnLogout() {
    _blocked = true;
    return _serial(_wipe);
  }

  Future<void> close() => _serial(() async {
        final database = _database;
        await database?.close();
        _database = null;
      });

  Future<void> _wipe() async {
    _blocked = true;
    await _secrets.markWipePending();
    final database = _database;
    await database?.close();
    _database = null;
    final path = await _path();
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final file = File('$path$suffix');
      if (await file.exists()) await file.delete();
    }
    await _secrets.clear();
    _blocked = false;
  }
}
