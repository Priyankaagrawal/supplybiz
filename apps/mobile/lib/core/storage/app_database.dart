import 'package:drift/drift.dart';
import 'package:encrypted_drift/encrypted_drift.dart';

/// ADR-006 / T-012 migration root. Feature tasks add their own tables and DAOs.
/// No schema codegen is needed until the first feature declares tables.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);

  AppDatabase.encrypted(String path, String key)
      : super(_SqlCipherExecutor(path, key));

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) => migrator.createAll(),
        onUpgrade: (migrator, from, to) async {
          // Add explicit, tested version steps as feature schemas are introduced.
          throw StateError('Unsupported local database migration.');
        },
        beforeOpen: (_) async {
          final cipher = await customSelect('PRAGMA cipher_version').get();
          if (cipher.isEmpty ||
              cipher.first.data.values.every((value) => '$value'.isEmpty)) {
            throw StateError('Encrypted database support is required.');
          }
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> open() async {
    await customSelect('SELECT count(*) FROM sqlite_master').getSingle();
  }
}

class _SqlCipherExecutor extends EncryptedExecutor {
  _SqlCipherExecutor(String path, String key)
      : super(
            path: path,
            password: key,
            singleInstance: false,
            logStatements: false);

  @override
  Future<void> close() {
    // The upstream delegate has no database handle when native open fails
    // (for example, a wrong key). Avoid masking that failure during cleanup.
    if (sqfliteDb == null) return Future.value();
    return super.close();
  }
}
