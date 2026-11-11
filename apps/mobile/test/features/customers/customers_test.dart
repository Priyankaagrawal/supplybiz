import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/app_failure.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/router/app_router.dart';
import 'package:supplybiz_mobile/core/router/guards.dart';
import 'package:supplybiz_mobile/core/router/routes.dart';
import 'package:supplybiz_mobile/core/router/routing_controller.dart';
import 'package:supplybiz_mobile/core/router/route_widgets.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/core/storage/customer_device.dart';
import 'package:supplybiz_mobile/features/customers/customers_controller.dart';
import 'package:supplybiz_mobile/features/customers/customers_page.dart';
import 'package:supplybiz_mobile/features/customers/customer_editor.dart';
import 'package:supplybiz_mobile/features/auth/auth_pages.dart'
    show authEnabledProvider;

import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import 'customer_fixture.dart';

CustomersController customerModel(CustomerFixture fixture, MemoryDrafts store,
    {String owner = 'synthetic-owner:customers'}) {
  final client = NetworkClient(
      baseUrl: 'https://api.example.test',
      session: TestSession(),
      adapter: fixture,
      delay: (_) async {});
  addTearDown(client.close);
  final model = CustomersController(client, store, owner);
  addTearDown(model.dispose);
  return model;
}

Widget customerApp(CustomersController model,
        {Widget child = const CustomersPage(), double scale = 1}) =>
    ProviderScope(
        overrides: [
          authEnabledProvider.overrideWithValue(true),
          customersProvider.overrideWith((ref) => model)
        ],
        child: MaterialApp(
            theme: sbLightTheme(const Locale('en')),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...SbLocalizations.delegates
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: child));

Future<void> reveal(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(target, 200,
      scrollable: find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'TC-060 all API pages and subscription membership support complete local search/status filters and 20-row display',
      () async {
    final fixture = CustomerFixture(),
        model = customerModel(fixture, MemoryDrafts());
    for (var i = 1; i <= 101; i++) {
      fixture.entries.add(customerJson(
          id: 'synthetic-$i',
          name: 'Synthetic $i',
          status: i == 101 ? 'INACTIVE' : 'ACTIVE'));
    }
    fixture.subscribed.add('synthetic-100');
    await model.load();
    expect(model.customers, hasLength(102));
    expect(model.visible, hasLength(20));
    model.more();
    expect(model.visible, hasLength(40));
    expect(fixture.calls.where((c) => c.queryParameters['filter'] == 'ALL'),
        hasLength(2));
    model.query('synthetic 100', 'SUBSCRIPTION');
    expect(model.visible.single.id, 'synthetic-100');
    model.query('synthetic 101', 'INACTIVE');
    expect(model.visible.single.status.value, 'INACTIVE');
    model.query('9000000000', 'ALL');
    expect(model.filtered, hasLength(102));
  });
  test(
      'TC-060 encrypted snapshot is read-only offline and scoped by account/environment',
      () async {
    final fixture = CustomerFixture(),
        store = MemoryDrafts(),
        model = customerModel(fixture, store);
    await model.load();
    fixture.offline = true;
    final restored = customerModel(fixture, store);
    await restored.load();
    expect(restored.cached, isTrue);
    expect(restored.canEdit, isFalse);
    expect(restored.customers.single.id, syntheticCustomerId);
    await restored.save({'name': 'Do not send'});
    expect(fixture.writes, isEmpty);
    final isolated = customerModel(fixture, store,
        owner: 'other-environment:other-owner:customers');
    await isolated.load();
    expect(isolated.customers, isEmpty);
  });
  test(
      'TC-061 response loss restores exact create payload/key after restart and commits once',
      () async {
    final fixture = CustomerFixture(),
        store = MemoryDrafts(),
        model = customerModel(fixture, store);
    await model.load();
    fixture.failAfterCommit = true;
    await model.save({
      'name': 'Synthetic New',
      'mobile': '9000000001',
      'address': '',
      'preferredPayment': 'UPI'
    });
    expect(model.pending, isNotNull);
    expect(model.failure, isA<NetworkFailure>());
    final key = fixture.writes.single.headers['Idempotency-Key'];
    final restored = customerModel(fixture, store);
    await restored.load();
    await restored.retryPending();
    expect(restored.pending, isNull);
    expect(restored.customers, hasLength(2));
    expect(fixture.commits, 1);
    expect(fixture.writes.last.headers['Idempotency-Key'], key);
  });
  test(
      'TC-061/063 PATCH preserves explicit email clearing and inactivation without forged identity/cap',
      () async {
    final fixture = CustomerFixture(),
        model = customerModel(fixture, MemoryDrafts());
    await model.load();
    await model
        .save({'email': null, 'status': 'INACTIVE'}, id: syntheticCustomerId);
    expect(model.customers.single.email, isNull);
    expect(model.activeCount, 0);
    expect(model.customers.single.id, syntheticCustomerId);
    final raw = fixture.writes.single.data;
    final body = raw is String ? jsonDecode(raw) as Map : raw as Map;
    expect(body.containsKey('email'), isTrue);
    expect(body['email'], isNull);
    expect(body.keys, unorderedEquals(['email', 'status']));
    expect(fixture.writes.single.headers['Idempotency-Key'], isNotEmpty);
  });
  test(
      'TC-061/062 definitive duplicate/limit rejection unlocks editing, preserves rows and shows support guidance',
      () async {
    final fixture = CustomerFixture(),
        model = customerModel(fixture, MemoryDrafts());
    await model.load();
    for (final pair in [(409, 'DUPLICATE'), (422, 'PLAN_CUSTOMER_LIMIT')]) {
      fixture.rejectStatus = pair.$1;
      fixture.rejectCode = pair.$2;
      await model.save({'status': 'ACTIVE'}, id: syntheticCustomerId);
      expect(model.failure?.code, pair.$2);
      expect(model.pending, isNull);
      expect(model.canEdit, isTrue);
      expect(model.customers, hasLength(1));
    }
  });
  test(
      'failed encrypted persistence sends no mutation; explicit retry recovers after disk becomes writable',
      () async {
    final fixture = CustomerFixture(),
        store = MemoryDrafts(),
        model = customerModel(fixture, store);
    await model.load();
    store.fail = true;
    await model.save({'status': 'INACTIVE'}, id: syntheticCustomerId);
    expect(fixture.writes, isEmpty);
    expect(model.pending, isNotNull);
    store.fail = false;
    await model.retryPending();
    expect(fixture.commits, 1);
    expect(model.pending, isNull);
  });
  test(
      'authorization denial purges snapshot/pending and prevents later offline disclosure',
      () async {
    final fixture = CustomerFixture(),
        store = MemoryDrafts(),
        model = customerModel(fixture, store);
    await model.load();
    fixture.denial = 403;
    await model.load();
    expect(model.customers, isEmpty);
    expect(model.ready, isFalse);
    expect(store.rows[model.owner], isEmpty);
    fixture.denial = null;
    fixture.offline = true;
    final restored = customerModel(fixture, store);
    await restored.load();
    expect(restored.customers, isEmpty);
  });
  test(
      'late responses after provider disposal cannot persist private customer data',
      () async {
    final fixture = CustomerFixture()..listGate = Completer<void>(),
        store = MemoryDrafts();
    final model = customerModel(fixture, store);
    final loading = model.load();
    await fixture.listReached.future;
    model.dispose();
    fixture.listGate!.complete();
    await loading;
    expect(store.rows, isEmpty);
  });
  testWidgets(
      'TC-060 offline/empty/error and detail unavailable activity render at 200% without invented totals',
      (tester) async {
    final fixture = CustomerFixture(),
        model = customerModel(fixture, MemoryDrafts());
    await tester.runAsync(model.load);
    fixture.offline = true;
    await tester.runAsync(model.load);
    await tester.pumpWidget(customerApp(model, scale: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('showing saved customers'), findsOneWidget);
    await reveal(tester, find.text('Add customer'));
    expect(
        tester
            .widget<SbButton>(find.widgetWithText(SbButton, 'Add customer'))
            .onPressed,
        isNull);
    await tester.pumpWidget(customerApp(model,
        child: const CustomerDetailPage(id: syntheticCustomerId), scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('Synthetic Customer'), findsOneWidget);
    expect(find.text('₹0'), findsNothing);
    await tester.scrollUntilVisible(
        find.text('Customer activity details are not available yet.'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'TC-061 form focuses invalid input and linked mobile is read-only at 200%',
      (tester) async {
    final fixture = CustomerFixture(),
        model = customerModel(fixture, MemoryDrafts());
    await tester.runAsync(model.load);
    await tester.pumpWidget(
        customerApp(model, child: const CustomerEditorPage(), scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Save customer'));
    await tester.tap(find.text('Save customer'));
    await tester.pumpAndSettle();
    expect(fixture.writes, isEmpty);
    expect(find.text('Enter a valid value.'), findsAtLeastNWidgets(1));
    expect(
        tester
            .widget<TextField>(find.descendant(
                of: find.byKey(const ValueKey('name')),
                matching: find.byType(TextField)))
            .focusNode!
            .hasFocus,
        isTrue);
    fixture.entries.single['userId'] = syntheticCustomerId;
    await tester.runAsync(model.load);
    await tester.pumpWidget(customerApp(model,
        child: const CustomerEditorPage(id: syntheticCustomerId), scale: 2));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('mobile')))
            .enabled,
        isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'TC-061/063 typed create/detail/edit/status routes save real transport fields and retain history',
      (tester) async {
    final fixture = CustomerFixture(),
        model = customerModel(fixture, MemoryDrafts());
    await tester.runAsync(model.load);
    final controller = RoutingController(
        access: const RouteAccess(
            signedIn: true,
            activeRole: AppRole.vendor,
            onboardingComplete: true));
    final router =
        createAppRouter(controller, initialLocation: '/vendor/customers');
    addTearDown(router.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authEnabledProvider.overrideWithValue(true),
          customersProvider.overrideWith((ref) => model)
        ],
        child: AppRoutingScope(
            controller: controller,
            environment: AppEnvironment.dev,
            child: MaterialApp.router(
                routerConfig: router,
                theme: sbLightTheme(const Locale('en')),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  ...SbLocalizations.delegates
                ],
                supportedLocales: AppLocalizations.supportedLocales))));
    await tester.pumpAndSettle();
    const VendorCustomerNewRoute()
        .push<void>(tester.element(find.byType(CustomersPage)));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('name')), 'Synthetic Added');
    await tester.enterText(find.byKey(const ValueKey('mobile')), '9000000002');
    await reveal(tester, find.text('Save customer'));
    await tester.tap(find.text('Save customer'));
    await tester.pumpAndSettle();
    expect(model.customers, hasLength(2));
    expect(model.failure, isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    router.go('/vendor/customers/$syntheticCustomerId');
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Mark inactive'));
    await tester.tap(find.text('Mark inactive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(model.find(syntheticCustomerId)!.status.value, 'INACTIVE');
    router.go('/vendor/customers/$syntheticCustomerId/edit');
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('name')), 'Synthetic Renamed');
    await reveal(tester, find.text('Save customer'));
    await tester.tap(find.text('Save customer'));
    await tester.pumpAndSettle();
    expect(model.find(syntheticCustomerId)!.name, 'Synthetic Renamed');
    expect(fixture.writes.last.method, 'PATCH');
    await tester.pumpWidget(const SizedBox());
  });
  test(
      'dialer validates numbers, uses ACTION_DIAL bridge and handles absent phone app without call permission',
      () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(customerDeviceChannel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(customerDeviceChannel, null));
    expect(await const CustomerDevice().dial('tel:bad'), isFalse);
    expect(calls, isEmpty);
    expect(await const CustomerDevice().dial('+919000000000'), isTrue);
    expect(calls.single.arguments, {'mobile': '+919000000000'});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(customerDeviceChannel,
            (_) async => throw PlatformException(code: 'NO_DIALER'));
    expect(await const CustomerDevice().dial('+919000000000'), isFalse);
  });
}
