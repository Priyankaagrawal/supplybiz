import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/app_failure.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/router/app_router.dart';
import 'package:supplybiz_mobile/core/router/guards.dart';
import 'package:supplybiz_mobile/core/router/routes.dart';
import 'package:supplybiz_mobile/core/router/routing_controller.dart';
import 'package:supplybiz_mobile/core/router/route_widgets.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/core/storage/device_location.dart';
import 'package:supplybiz_mobile/features/addresses/addresses_controller.dart';
import 'package:supplybiz_mobile/features/addresses/addresses_page.dart';
import 'package:supplybiz_mobile/features/addresses/address_editor.dart';
import 'package:supplybiz_mobile/features/auth/auth_pages.dart'
    show authEnabledProvider;
import 'package:ui_kit/ui_kit.dart';
import '../onboarding/onboarding_test.dart' show MemoryDrafts, TestSession;
import 'address_fixture.dart';

AddressesController addressModel(AddressFixture fixture, MemoryDrafts store,
    {String owner = 'synthetic:addresses'}) {
  final client = NetworkClient(
      baseUrl: 'https://api.example.test',
      session: TestSession(),
      adapter: fixture,
      delay: (_) async {});
  addTearDown(client.close);
  return AddressesController(client, store, owner);
}

AddressInput input() => AddressInput.fromJson(addressJson()..remove('id'));
Widget addressApp(AddressesController model,
        {Widget home = const AddressesPage(), double scale = 1}) =>
    ProviderScope(
        overrides: [addressesProvider.overrideWith((ref) => model)],
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
            home: home));
Future<void> reveal(WidgetTester tester, Finder finder,
    {double delta = 200}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(finder, delta,
      scrollable: find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'TC-290 manual field validation rejects missing/NaN/out-of-range coordinates and invalid pincode',
      () {
    for (final field in [
      'label',
      'line1',
      'line2',
      'city',
      'state',
      'pincode',
      'latitude',
      'longitude'
    ]) {
      expect(validAddressField(field, ''), isFalse);
    }
    for (final value in ['NaN', 'Infinity', '91', '-91', 'abc']) {
      expect(validAddressField('latitude', value), isFalse);
    }
    for (final value in ['181', '-181']) {
      expect(validAddressField('longitude', value), isFalse);
    }
    for (final value in ['012345', '12345', '1234567', 'abcdef']) {
      expect(validAddressField('pincode', value), isFalse);
    }
    expect(validAddressField('latitude', '-90'), isTrue);
    expect(validAddressField('longitude', '180'), isTrue);
    expect(validAddressField('pincode', '560001'), isTrue);
    expect(validAddressField('landmark', ''), isTrue);
  });
  test(
      'TC-290 generated client CRUD/default/delete refresh authoritative server state and send stable mutation keys',
      () async {
    final fixture = AddressFixture(),
        model = addressModel(fixture, MemoryDrafts());
    addTearDown(model.dispose);
    await model.load();
    expect(model.addresses, isEmpty);
    expect(await model.save(input()), isTrue);
    final first = model.addresses.single;
    expect(first.isDefault, isTrue);
    await model
        .save(AddressInput.fromJson({...input().toJson(), 'isDefault': false}));
    final second = model.addresses.last;
    await model.makeDefault(second.id);
    expect(model.find(first.id)!.isDefault, isFalse);
    await model.save(
        AddressInput.fromJson(
            {...input().toJson(), 'label': 'Changed', 'isDefault': true}),
        id: second.id);
    expect(model.find(second.id)!.label, 'Changed');
    await model.remove(second.id);
    expect(model.addresses.single.isDefault, isTrue);
    expect(fixture.writes.map((w) => w.headers['Idempotency-Key']).toSet(),
        hasLength(5));
    for (final w in fixture.writes) {
      expect(w.headers['Authorization'], isNotNull);
    }
  });
  test(
      'response loss persists an account-scoped request; restart never auto-submits and explicit retry reuses key',
      () async {
    final fixture = AddressFixture(), store = MemoryDrafts();
    var model = addressModel(fixture, store);
    await model.load();
    fixture.loseResponse = true;
    await model.save(input());
    expect(model.pending, isNotNull);
    expect(model.canEdit, isFalse);
    final key = fixture.writes.single.headers['Idempotency-Key'];
    model.dispose();
    model = addressModel(fixture, store);
    addTearDown(model.dispose);
    await model.load();
    expect(fixture.writes, hasLength(1));
    expect(model.addresses, hasLength(1));
    final other =
        addressModel(fixture, store, owner: 'another-account:addresses');
    addTearDown(other.dispose);
    await other.load();
    expect(other.pending, isNull);
    await model.retryPending();
    expect(fixture.writes.last.headers['Idempotency-Key'], key);
    expect(model.pending, isNull);
    expect(model.addresses, hasLength(1));
    expect(await store.read(model.owner), isEmpty);
  });
  test(
      'accepted mutation stays completed when list refresh fails; immediate resubmission is blocked',
      () async {
    final fixture = AddressFixture(),
        model = addressModel(fixture, MemoryDrafts());
    addTearDown(model.dispose);
    await model.load();
    fixture.offlineAfterWrite = true;
    expect(await model.save(input()), isTrue);
    expect(model.completed, isTrue);
    expect(model.failure, isA<NetworkFailure>());
    expect(model.pending, isNull);
    expect(model.canEdit, isFalse);
    expect(await model.save(input()), isFalse);
    expect(fixture.writes, hasLength(1));
  });
  test(
      'offline refresh keeps last view read-only; role denial clears private state and pending request',
      () async {
    final fixture = AddressFixture()..rows.add(addressJson()),
        store = MemoryDrafts();
    final model = addressModel(fixture, store);
    addTearDown(model.dispose);
    await model.load();
    fixture.offline = true;
    await model.load();
    expect(model.failure, isA<NetworkFailure>());
    expect(model.addresses, hasLength(1));
    expect(model.canEdit, isFalse);
    expect(await model.save(input()), isFalse);
    fixture.offline = false;
    await model.load();
    fixture.loseResponse = true;
    await model.save(input());
    fixture.status = 403;
    await model.retryPending();
    expect(model.addresses, isEmpty);
    expect(model.pending, isNull);
    expect(await store.read(model.owner), isEmpty);
  });
  test(
      'expired retries cannot resend; dismissal requires reviewing a fresh server list',
      () async {
    final fixture = AddressFixture(), store = MemoryDrafts();
    final request = {
      'method': 'POST',
      'id': null,
      'key': 'synthetic-expired',
      'body': input().toJson(),
      'created': 0
    };
    await store.write('synthetic:addresses', {'pending': jsonEncode(request)});
    final model = addressModel(fixture, store);
    addTearDown(model.dispose);
    await model.load();
    await model.retryPending();
    expect(fixture.writes, isEmpty);
    expect(model.failure?.code, 'ADDRESS_RETRY_EXPIRED');
    await model.dismissExpired();
    expect(model.pending, isNotNull);
    await model.load();
    await model.dismissExpired();
    expect(model.pending, isNull);
    expect(model.canEdit, isTrue);
  });
  test('disposed controller cannot publish late loads or send saved requests',
      () async {
    final fixture = AddressFixture(),
        model = addressModel(fixture, MemoryDrafts());
    final loading = model.load();
    model.dispose();
    await loading;
    expect(model.addresses, isEmpty);
    expect(await model.save(input()), isFalse);
    expect(fixture.writes, isEmpty);
  });
  testWidgets(
      'TC-290 200% list confirms deletion; cancellation preserves address',
      (tester) async {
    final fixture = AddressFixture()..rows.add(addressJson()),
        model = addressModel(fixture, MemoryDrafts());
    await tester.runAsync(model.load);
    await tester.pumpWidget(addressApp(model, scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Delete address'));
    await tester.tap(find.text('Delete address'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(fixture.writes, isEmpty);
    await tester.tap(find.text('Delete address'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(model.addresses, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'TC-290 GPS denial leaves 200% manual form usable; invalid form cannot submit',
      (tester) async {
    final fixture = AddressFixture(),
        model = addressModel(fixture, MemoryDrafts());
    await tester.runAsync(model.load);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceLocation.channel,
            (_) async => throw PlatformException(code: 'LOCATION_DENIED'));
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceLocation.channel, null));
    await tester
        .pumpWidget(addressApp(model, home: const AddressForm(), scale: 2));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Use current location'));
    await tester.tap(find.text('Use current location'));
    await tester.pumpAndSettle();
    expect(find.textContaining('manually'), findsWidgets);
    await reveal(tester, find.text('Save address'));
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();
    expect(fixture.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('typed customer profile address route and role guard work',
      (tester) async {
    final fixture = AddressFixture(),
        model = addressModel(fixture, MemoryDrafts());
    await tester.runAsync(model.load);
    final routing = RoutingController()
      ..update(const RouteAccess(signedIn: true, activeRole: AppRole.customer));
    final router =
        createAppRouter(routing, initialLocation: '/customer/profile');
    addTearDown(router.dispose);
    addTearDown(routing.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authEnabledProvider.overrideWithValue(true),
          addressesProvider.overrideWith((ref) => model)
        ],
        child: AppRoutingScope(
            controller: routing,
            environment: AppEnvironment.dev,
            child: MaterialApp.router(
                routerConfig: router,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  ...SbLocalizations.delegates
                ],
                supportedLocales: AppLocalizations.supportedLocales))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Addresses'));
    await tester.pumpAndSettle();
    expect(find.byType(AddressesPage), findsOneWidget);
    const CustomerAddressNewRoute()
        .go(tester.element(find.byType(AddressesPage)));
    await tester.pumpAndSettle();
    expect(find.byType(AddressForm), findsOneWidget);
    for (final e
        in input().toJson().entries.where((e) => e.key != 'isDefault')) {
      final field = find.byKey(ValueKey('address-${e.key}'));
      await reveal(tester, field);
      await tester.enterText(field, '${e.value}');
    }
    await reveal(tester, find.text('Save address'));
    fixture.loseResponse = true;
    await tester.runAsync(() async {
      await tester.tap(find.text('Save address'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byType(AddressForm), findsOneWidget);
    expect(model.pending, isNotNull);
    await reveal(tester, find.text('Retry saved request'), delta: -200);
    await tester.runAsync(() async {
      await tester.tap(find.text('Retry saved request'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byType(AddressForm), findsNothing);
    expect(find.byType(AddressesPage), findsOneWidget);
    expect(model.addresses, hasLength(1));
    expect(
        guardRedirect(
            const RouteAccess(
                signedIn: true,
                activeRole: AppRole.vendor,
                onboardingComplete: true),
            const CustomerAddressesRoute().location),
        '/common/switch-role');
  });
}
