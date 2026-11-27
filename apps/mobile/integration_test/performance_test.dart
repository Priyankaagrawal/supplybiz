// T-170 / TC-601: actual vendor order widgets; synthetic transport, no API/DB claim.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/features/orders/orders_controller.dart';
import 'package:supplybiz_mobile/features/orders/orders_pages.dart';
import 'package:flutter/widgets.dart';
import '../test/features/orders/orders_test.dart'
    show OrdersFixture, ordersClient, ordersApp, orderJson;
import '../test/features/onboarding/onboarding_test.dart' show MemoryDrafts;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('T-170 profile 500-order scrolling and process RSS',
      (tester) async {
    expect(kProfileMode, isTrue,
        reason: 'Performance evidence requires profile mode');
    final fixture = OrdersFixture();
    fixture.rows.clear();
    fixture.rows.addAll(List.generate(
        500,
        (i) => orderJson(
            id: '88888888-8888-4888-8888-${i.toString().padLeft(12, '0')}',
            number: 'SYN-${i.toString().padLeft(4, '0')}')));
    final client = ordersClient(fixture);
    addTearDown(client.close);
    final model = VendorOrdersController(
        VendorOrdersApi(client.dio), MemoryDrafts(), 'synthetic:performance');
    final baselineRss = ProcessInfo.currentRss;
    await tester.pumpWidget(ordersApp(model, child: const VendorOrdersPage()));
    await tester.pumpAndSettle();
    while (model.items.length < 500) {
      await model.load(more: true);
      expect(model.failure, isNull);
    }
    await tester.pumpAndSettle();
    expect(model.items.length, 500);
    final loadedRss = ProcessInfo.currentRss;
    final list = find.byType(ListView);
    // Warm shaders/layout before the measured eight gestures.
    await tester.fling(list, const Offset(0, -1200), 1500);
    await tester.pumpAndSettle();
    await binding.watchPerformance(() async {
      for (var i = 0; i < 8; i++) {
        await tester.fling(list, Offset(0, i < 4 ? -1600 : 1600), 1800);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'orders500');
    final report = {
      'task': 'T-170',
      'scenario': 'real order list, 500 synthetic rows, in-memory transport',
      'baselineRssBytes': baselineRss,
      'loaded500RssBytes': loadedRss,
      'afterScrollRssBytes': ProcessInfo.currentRss,
      'peakRssBytes': ProcessInfo.maxRss,
      'referenceAcceptance': 'NOT_RUN',
      'frames': binding.reportData!['orders500'],
    };
    binding.reportData!['processMemory'] = {
      'baselineRssBytes': baselineRss,
      'loaded500RssBytes': loadedRss,
      'afterScrollRssBytes': ProcessInfo.currentRss,
      'peakRssBytes': ProcessInfo.maxRss,
    };
    // Aggregate numeric timing/memory only; no widget tree, account or request data.
    // ignore: avoid_print
    print('T170_PERFORMANCE ${jsonEncode(report)}');
    expect((binding.reportData!['orders500'] as Map)['frame_count'],
        greaterThan(0));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
