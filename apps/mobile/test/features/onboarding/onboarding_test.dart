import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/app.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import '../auth/auth_fixture.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';
import 'package:supplybiz_mobile/core/network/app_failure.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_pages.dart';
import 'package:supplybiz_mobile/core/storage/onboarding_device.dart';
import 'package:supplybiz_mobile/features/onboarding/mask_document.dart';

const categoryId = '11111111-1111-4111-8111-111111111111';

class MemoryDrafts implements OnboardingDrafts {
  final rows = <String, Map<String, String>>{};
  bool fail = false;
  @override
  Future<Map<String, String>> read(String owner) async => {...?rows[owner]};
  @override
  Future<void> write(String owner, Map<String, String> values) async {
    if (fail) throw StateError('Synthetic disk failure');
    rows[owner] = {...values};
  }
}

class OnboardingFixture implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  int step = 1, categoryFailures = 0;
  bool offline = false;
  String status = 'MANUAL_REVIEW';
  Map<String, dynamic> get profile => {
        'id': categoryId,
        'categoryId': categoryId,
        'onboardingStep': step,
        'kycStatus': step < 4 ? 'NOT_VERIFIED' : status,
        'businessName': 'Synthetic shop',
        'gstin': null,
        'addressLine': 'Synthetic address',
        'city': 'Synthetic city',
        'state': 'Synthetic state',
        'pincode': '110001',
        'latitude': 28.6,
        'longitude': 77.2,
        'shopPhotoMediaId': null,
        'settings': {
          'serviceRadiusKm': null,
          'deliveryChargePaise': 0,
          'minOrderPaise': 0,
          'timeSlots': [],
          'autoAcceptSubscriptions': false,
          'acceptingToday': true,
          'deliveryPaused': false,
          'allowKhataOrders': true,
          'version': 1
        }
      };
  Map<String, dynamic> get kyc => {
        'id': categoryId,
        'vendorId': categoryId,
        'status': status,
        'verificationMethod': 'MANUAL_REVIEW',
        'providerChecks': 'NOT_RUN',
        'submittedAt': '2026-11-10T00:00:00Z',
        'reviewedAt': null,
        'reviewerId': null,
        'reason': status == 'REJECTED' ? 'Synthetic rejection reason' : null,
        'aadhaarFrontMediaId': categoryId,
        'aadhaarBackMediaId': categoryId,
        'panMediaId': categoryId,
        'panLast4': '000A',
        'accountLast4': '0000',
        'holderName': 'Synthetic holder',
        'bankName': 'Synthetic bank',
        'ifsc': 'TEST0000000',
        'upiId': null
      };
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    calls.add(options);
    if (offline) {
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    }
    final path = options.uri.path;
    int code = 200;
    Object response = profile;
    if (path.endsWith('/categories')) {
      response = [
        {
          'id': categoryId,
          'code': 'DAIRY',
          'name': 'Dairy / Milk Supplier',
          'icon': null
        }
      ];
    } else if (path.endsWith('/category')) {
      if (categoryFailures-- > 0) {
        code = 503;
        response = {'code': 'UNAVAILABLE'};
      } else {
        step = 2;
        code = 201;
        response = profile;
      }
    } else if (path.endsWith('/business')) {
      step = 3;
      response = profile;
    } else if (path.endsWith('/kyc')) {
      if (options.method == 'POST') {
        step = 4;
        status = 'MANUAL_REVIEW';
        code = 201;
      }
      if (step < 4) {
        code = 404;
        response = {'code': 'KYC_NOT_SUBMITTED'};
      } else {
        response = kyc;
      }
    } else if (path.endsWith('/onboarding') && step == 1) {
      code = 404;
      response = {'code': 'ONBOARDING_NOT_STARTED'};
    } else if (path.endsWith('/media')) {
      await stream?.drain<void>();
      code = 201;
      response = {'mediaId': categoryId, 'status': 'READY'};
    }
    return ResponseBody.fromString(jsonEncode(response), code, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

class TestSession implements NetworkSession {
  @override
  String? get accessToken => 'synthetic-access';
  @override
  Future<void> refresh() async {}
  @override
  Future<void> clear({AppFailure? reason}) async {}
}

OnboardingController makeController(OnboardingFixture api, MemoryDrafts drafts,
    {String owner = 'owner'}) {
  final client = NetworkClient(
      baseUrl: 'https://api.example.test',
      adapter: api,
      session: TestSession());
  return OnboardingController(client, drafts, owner);
}

class OnboardingAppFixture implements HttpClientAdapter {
  final vendor = OnboardingFixture()..step = 2;
  final auth = AuthFixture()
    ..activeRole = 'VENDOR'
    ..roles.add('VENDOR');
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancel) =>
      options.uri.path.contains('/vendor/')
          ? vendor.fetch(options, stream, cancel)
          : auth.fetch(options, stream, cancel);
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(onboardingChannel, (call) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(onboardingChannel, null);
  });
  test('TC-022 step/draft restore, account isolation and persistent retry keys',
      () async {
    final api = OnboardingFixture()..categoryFailures = 1,
        drafts = MemoryDrafts();
    final model = makeController(api, drafts);
    await model.load();
    expect(model.ready, true);
    expect(model.step, 1);
    await model.saveCategory(categoryId);
    expect(model.failure, isA<ServerFailure>());
    final key = api.calls.last.headers['Idempotency-Key'];
    model.dispose();
    final restored = makeController(api, drafts);
    await restored.load();
    await restored.saveCategory(categoryId);
    expect(api.calls.last.headers['Idempotency-Key'], key);
    expect(restored.step, 2);
    restored.edit('businessName', 'Unfinished synthetic draft');
    await restored.flush();
    restored.dispose();
    final again = makeController(api, drafts);
    await again.load();
    expect(again.values['businessName'], 'Unfinished synthetic draft');
    expect((await drafts.read('another-owner')), isEmpty);
    again.dispose();
  });
  test(
      'TC-022 local save failure prevents server mutation; retry persists safely',
      () async {
    final api = OnboardingFixture(), drafts = MemoryDrafts()..fail = true;
    final model = makeController(api, drafts);
    await model.load();
    await model.saveCategory(categoryId);
    expect(api.calls.where((c) => c.method == 'POST'), isEmpty);
    drafts.fail = false;
    await model.saveCategory(categoryId);
    expect(model.step, 2);
    expect(drafts.rows['owner']!['categoryKey'], isNotEmpty);
    model.dispose();
  });
  test(
      'TC-023 oversize never uploads; multipart uses generated client/key/purpose',
      () async {
    final api = OnboardingFixture(),
        model = makeController(api, MemoryDrafts());
    await model.upload('panMediaId', Uint8List(5 * 1024 * 1024 + 1),
        pdf: false, key: 'synthetic-key');
    expect(api.calls, isEmpty);
    await model.upload('panMediaId', Uint8List.fromList([137, 80, 78, 71]),
        pdf: false, key: 'synthetic-key');
    expect(api.calls.single.headers['Idempotency-Key'], 'synthetic-key');
    expect(
        api.calls.single.headers['Authorization'], 'Bearer synthetic-access');
    expect(model.values['panMediaId'], categoryId);
    await model.flush();
    model.dispose();
  });
  test(
      'TC-025/026 submission, masked status, rejection and sensitive-draft cleanup',
      () async {
    final api = OnboardingFixture()..step = 3, drafts = MemoryDrafts();
    final model = makeController(api, drafts);
    await model.load();
    model.values.addAll({
      'aadhaarFrontMediaId': categoryId,
      'aadhaarBackMediaId': categoryId,
      'panMediaId': categoryId,
      'pan': 'AAAAA0000A',
      'holderName': 'Synthetic holder',
      'bankName': 'Synthetic bank',
      'accountNumber': '000000000',
      'accountNumberConfirmation': '000000000',
      'ifsc': 'TEST0000000'
    });
    await model.submit();
    await model.flush();
    expect(model.failure, isNull);
    expect(model.complete, true);
    expect(model.submission!.providerChecks.value, 'NOT_RUN');
    expect(drafts.rows['owner']!.containsKey('accountNumber'), false);
    expect(drafts.rows['owner']!.containsKey('submitPayload'), false);
    api.status = 'REJECTED';
    await model.load();
    expect(model.canSubmit, true);
    expect(model.submission!.reason, 'Synthetic rejection reason');
    model.dispose();
  });
  test('TC-022 disposed owner ignores late writes', () async {
    final drafts = MemoryDrafts();
    final model = makeController(OnboardingFixture(), drafts);
    model.dispose();
    model.edit('pan', 'AAAAA0000A');
    await model.flush();
    expect(drafts.rows, isEmpty);
  });
  Future<void> launch(WidgetTester tester, OnboardingController model,
      {double scale = 1}) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [onboardingProvider.overrideWith((ref) => model)],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
                useMaterial3: true,
                filledButtonTheme: FilledButtonThemeData(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48))),
                outlinedButtonTheme: OutlinedButtonThemeData(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48))),
                textButtonTheme: TextButtonThemeData(
                    style:
                        TextButton.styleFrom(minimumSize: const Size(48, 48)))),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: const OnboardingPage())));
    await tester.pumpAndSettle();
  }

  testWidgets('TC-020 required category, 200% scale and Android labels/targets',
      (tester) async {
    final model = makeController(OnboardingFixture(), MemoryDrafts());
    await tester.runAsync(model.load);
    await launch(tester, model, scale: 2);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save & Continue'))
            .onPressed,
        isNull);
    final semantics = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
    await tester.tap(find.text('Dairy / Milk Supplier'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save & Continue'))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'TC-021/024 business and bank validation prevent invalid mutations',
      (tester) async {
    final api = OnboardingFixture()..step = 3;
    final model = makeController(api, MemoryDrafts());
    await tester.runAsync(model.load);
    await launch(tester, model);
    Future<void> enter(String label, String value) async {
      await tester.enterText(find.widgetWithText(TextFormField, label), value);
    }

    await enter('Account number', '000000000');
    await enter('Confirm account number', '000000001');
    await enter('IFSC', 'TEST1000000');
    await tester.ensureVisible(find.text('Submit for verification'));
    await tester.tap(find.text('Submit for verification'));
    await tester.pumpAndSettle();
    expect(find.text('Account numbers must match.'), findsOneWidget);
    expect(api.calls.where((call) => call.method == 'POST'), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'TC-022 restored vendor session follows persisted server step through real router',
      (tester) async {
    final api = OnboardingAppFixture();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authConfigProvider.overrideWithValue(testAuthConfig),
          authAdapterProvider.overrideWithValue(api),
          authStorageProvider.overrideWithValue(
              MemoryAuthStorage()..token = 'synthetic-refresh'),
          onboardingDraftsProvider.overrideWithValue(MemoryDrafts()),
        ],
        child: const SupplyBizApp(
            environment: AppEnvironment.dev, enableAuth: true)));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 4'), findsOneWidget);
    expect(find.text('Synthetic shop'), findsOneWidget);
    await tester.ensureVisible(find.text('Save & Continue'));
    await tester.tap(find.text('Save & Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test('TC-029 manual masking flattens black pixels into the encoded document',
      () async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.white, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 100);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    image.dispose();
    picture.dispose();
    final result = await maskImage(bytes, const Rect.fromLTWH(.1, .7, .6, .1));
    final codec = await ui.instantiateImageCodec(result);
    final masked = (await codec.getNextFrame()).image;
    final rgba = (await masked.toByteData())!;
    expect(rgba.getUint8((75 * 100 + 20) * 4), 0);
    expect(rgba.getUint8((10 * 100 + 10) * 4), 255);
    masked.dispose();
    codec.dispose();
  });
}
