import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supplybiz_mobile/core/storage/app_database.dart';
import 'package:supplybiz_mobile/core/storage/app_storage.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('T-012 SQLCipher persistence, wrong key and logout wipe',
      (_) async {
    final root = await getApplicationSupportDirectory();
    final directory = await Directory('${root.path}/storage-test').create();
    const backend = FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError: false,
        storageNamespace: 'supplybiz.storage.test',
      ),
      iOptions: IOSOptions(
        accountName: 'supplybiz.storage.test',
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    final secrets = SecureStore(backend: backend);
    final storage =
        AppStorage(secrets: secrets, directory: () async => directory);
    await storage.wipeOnLogout();
    addTearDown(() async {
      await storage.wipeOnLogout();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    await storage.initialize();
    await storage.writeRefreshToken('fake-integration-refresh');
    final key = await secrets.readDatabaseKey();
    expect(key, isNotNull);
    await storage.database.customStatement('CREATE TABLE probe (value TEXT)');
    await storage.database.customStatement(
        'INSERT INTO probe VALUES (?)', ['fake-persisted-value']);
    await storage.close();

    final file = File('${directory.path}/supplybiz.sqlite');
    final bytes = await file.readAsBytes();
    expect(utf8.decode(bytes.take(16).toList(), allowMalformed: true),
        isNot(startsWith('SQLite format 3')));
    expect(utf8.decode(bytes, allowMalformed: true),
        isNot(contains('fake-persisted-value')));
    final wrongKey =
        AppDatabase.encrypted(file.path, List.filled(64, '0').join());
    await expectLater(wrongKey.open(), throwsA(anything));
    await wrongKey.close();

    final restarted = AppStorage(
        secrets: SecureStore(backend: backend),
        directory: () async => directory);
    await restarted.initialize();
    expect(await restarted.readRefreshToken(), 'fake-integration-refresh');
    expect(
        (await restarted.database
                .customSelect('SELECT value FROM probe')
                .getSingle())
            .read<String>('value'),
        'fake-persisted-value');
    expect(await secrets.readDatabaseKey(), key);
    await restarted.wipeOnLogout();
    expect(await file.exists(), isFalse);
    expect(await secrets.readDatabaseKey(), isNull);
    expect(await secrets.readRefreshToken(), isNull);
    await restarted.initialize();
    expect(await secrets.readDatabaseKey(), isNot(key));
    expect(
        await restarted.database
            .customSelect("SELECT name FROM sqlite_master WHERE name = 'probe'")
            .get(),
        isEmpty);
    await restarted.wipeOnLogout();
  });
}
