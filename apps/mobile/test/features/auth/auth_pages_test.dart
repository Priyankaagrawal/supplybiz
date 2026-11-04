import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:supplybiz_mobile/app.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/features/auth/session_controller.dart';
import 'auth_fixture.dart';

void main() {
  setUpAll(() async {
    for (final delegate in SbLocalizations.delegates) {
      await delegate.load(const Locale('en'));
    }
  });
  Future<void> launch(
      WidgetTester tester, AuthFixture api, MemoryAuthStorage storage,
      {AuthConfig config = testAuthConfig}) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authConfigProvider.overrideWithValue(config),
          authStorageProvider.overrideWithValue(storage),
          authAdapterProvider.overrideWithValue(api)
        ],
        child: const SupplyBizApp(
            environment: AppEnvironment.dev, enableAuth: true)));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'TC-001/013 login needs valid mobile and consent; change number retains input',
      (tester) async {
    final api = AuthFixture();
    await launch(tester, api, MemoryAuthStorage());
    await tester.enterText(find.byType(TextField).first, '5000000000');
    await tester.pump();
    expect(find.textContaining('Enter a valid 10-digit'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Send OTP'))
            .onPressed,
        isNull);
    await tester.enterText(find.byType(TextField).first, '90000 00000');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tap(tester, 'Continue with WhatsApp');
    expect(find.text('Verify mobile number'), findsOneWidget);
    expect(find.text('Resend in 30s'), findsOneWidget);
    await tap(tester, 'Change number');
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '9000000000');
    expect(api.calls, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'TC-003/008/010 sign in, select role and logout-all through real generated client',
      (tester) async {
    final api = AuthFixture(), storage = MemoryAuthStorage();
    await launch(tester, api, storage);
    await tester.enterText(find.byType(TextField).first, '9000000000');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tap(tester, 'Continue with WhatsApp');
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pumpAndSettle();
    expect(find.text('Choose your role'), findsOneWidget);
    await tap(tester, 'I want to buy');
    expect(find.byType(SbBottomNav), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tap(tester, 'I sell / supply');
    expect(find.text('Set up your business'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tap(tester, 'I want to buy');
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tap(tester, 'Logout from all devices');
    expect(find.text('Sign in'), findsOneWidget);
    expect(storage.wipes, 1);
    expect(storage.token, isNull);
    expect(api.calls.last.uri.path, '/api/v1/auth/logout');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'TC-013 missing legal docs fails closed; login is accessible at 200% scale',
      (tester) async {
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();
    await launch(tester, AuthFixture(), MemoryAuthStorage(),
        config: const AuthConfig(baseUrl: 'https://api.example.test/api/v1'));
    expect(find.textContaining('Terms and Privacy Policy are unavailable'),
        findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '9000000000');
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Send OTP'))
            .onPressed,
        isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });
}
