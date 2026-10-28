import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/storage/app_database.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';

class MemorySecrets extends SecureStore {
  String? key;
  String? refresh;
  bool pending = false;
  bool failClear = false;
  int creations = 0;

  @override
  Future<String?> readDatabaseKey() async => key;
  @override
  Future<String> createDatabaseKey() async {
    creations++;
    return key = List.filled(64, 'a').join();
  }

  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> writeRefreshToken(String value) async => refresh = value;
  @override
  Future<bool> get wipePending async => pending;
  @override
  Future<void> markWipePending() async => pending = true;
  @override
  Future<void> clear() async {
    if (failClear) throw StateError('Simulated secure storage failure');
    key = null;
    refresh = null;
    pending = false;
  }
}

class FakeDatabase extends AppDatabase {
  FakeDatabase() : super(NativeDatabase.memory());
  bool closed = false;
  bool failOpen = false;
  Completer<void>? gate;
  @override
  Future<void> open() async {
    await gate?.future;
    if (failOpen) throw StateError('Simulated unreadable database');
  }

  @override
  Future<void> close() async {
    closed = true;
    await super.close();
  }
}

void main() {
  late Directory directory;
  late MemorySecrets secrets;
  late List<FakeDatabase> databases;
  late AppStorage storage;
  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('supplybiz-storage-test-');
    secrets = MemorySecrets();
    databases = [];
    storage = AppStorage(
      secrets: secrets,
      directory: () async => directory,
      databaseFactory: (_, __) {
        final database = FakeDatabase();
        databases.add(database);
        return database;
      },
    );
  });
  tearDown(() async {
    for (final database in databases) {
      if (!database.closed) await database.close();
    }
    await directory.delete(recursive: true);
  });

  test('T-012 concurrent initialization shares a key and database', () async {
    await Future.wait([storage.initialize(), storage.initialize()]);
    expect(secrets.creations, 1);
    expect(databases, hasLength(1));
    expect(storage.database, same(databases.single));
  });

  test('T-012 lost key preserves existing database and rejects startup',
      () async {
    final file = File('${directory.path}/supplybiz.sqlite');
    await file.writeAsString('fake encrypted bytes');
    await expectLater(storage.initialize(), throwsStateError);
    expect(await file.readAsString(), 'fake encrypted bytes');
    expect(secrets.creations, 0);
    expect(databases, isEmpty);
  });

  test('T-012 logout closes handles, removes sidecars and clears secrets',
      () async {
    await storage.initialize();
    await storage.writeRefreshToken('fake-refresh');
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      await File('${directory.path}/supplybiz.sqlite$suffix')
          .writeAsString('fake');
    }
    final wipe = storage.wipeOnLogout();
    expect(() => storage.database, throwsStateError);
    await wipe;
    expect(databases.single.closed, isTrue);
    expect(await directory.list().toList(), isEmpty);
    expect(secrets.key, isNull);
    expect(await storage.readRefreshToken(), isNull);
    await storage.initialize();
    expect(secrets.creations, 2);
  });

  test('T-012 failed wipe stays blocked and resumes on next startup', () async {
    await storage.initialize();
    secrets.failClear = true;
    await expectLater(storage.wipeOnLogout(), throwsStateError);
    expect(secrets.pending, isTrue);
    await expectLater(storage.readRefreshToken(), throwsStateError);
    expect(() => storage.database, throwsStateError);
    secrets.failClear = false;
    final restarted = AppStorage(
      secrets: secrets,
      directory: () async => directory,
      databaseFactory: (_, __) {
        final database = FakeDatabase();
        databases.add(database);
        return database;
      },
    );
    await restarted.initialize();
    expect(secrets.pending, isFalse);
    expect(secrets.creations, 2);
  });

  test('T-012 plaintext SQLite is rejected by runtime cipher check', () async {
    final database = AppDatabase(NativeDatabase.memory());
    await expectLater(database.open(), throwsStateError);
    await database.close();
  });
}
