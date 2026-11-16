// T-053 / TC-064: an old account's in-flight response cannot restore wiped data.
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/features/customers/customer_links_controller.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import 'customer_links_test.dart' show LinkFixture, linkId;

void main() {
  test('TC-064 logout/dispose fences in-flight consent and late cache writes',
      () async {
    final f = LinkFixture(), store = MemoryDrafts();
    final client = NetworkClient(
        baseUrl: 'https://api.example.test',
        session: TestSession(),
        adapter: f);
    addTearDown(client.close);
    final m = CustomerLinksController(client, store, 'old:links');
    await m.load();
    f.gate = Completer<void>();
    final task = m.decide(linkId, true);
    while (f.calls.where((r) => r.method == 'POST').isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    m.dispose();
    store.rows.clear();
    f.gate!.complete();
    await task;
    expect(store.rows, isEmpty);
    expect(m.completed, isNull);
  });
}
