import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/storage/secure_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('T-012 creates and persists a random 256-bit key; clears secrets',
      () async {
    final store = SecureStore();
    final key = await store.createDatabaseKey();
    expect(key, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(await store.readDatabaseKey(), key);
    expect(await SecureStore().createDatabaseKey(), isNot(key));
    await store.writeRefreshToken('fake-refresh');
    expect(await store.readRefreshToken(), 'fake-refresh');
    await store.markWipePending();
    expect(await store.wipePending, isTrue);
    await store.clear();
    expect(await store.readDatabaseKey(), isNull);
    expect(await store.readRefreshToken(), isNull);
    expect(await store.wipePending, isFalse);
  });
}
