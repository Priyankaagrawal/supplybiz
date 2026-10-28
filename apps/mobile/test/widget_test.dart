import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:supplybiz_mobile/app.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final delegate in SbLocalizations.delegates) {
      await delegate.load(const Locale('en'));
    }
  });
  for (final environment in AppEnvironment.values) {
    testWidgets('${environment.name} environment renders the app shell', (
      tester,
    ) async {
      await tester.pumpWidget(SupplyBizApp(environment: environment));
      await tester.pumpAndSettle();

      expect(find.text('Supply Biz'), findsOneWidget);
      expect(
        find.text('${environment.displayName} environment'),
        findsOneWidget,
      );
    });
  }

  testWidgets('Hindi device locale translates the shell at 200% text scale',
      (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('hi')];
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
    for (final delegate in SbLocalizations.delegates) {
      await delegate.load(const Locale('hi'));
    }
    await tester.pumpWidget(
      const SupplyBizApp(environment: AppEnvironment.dev),
    );
    await tester.pumpAndSettle();
    expect(find.text('डेवलपमेंट परिवेश'), findsOneWidget);
    expect(find.text('Development environment'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unsupported device language falls back to English',
      (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      const SupplyBizApp(environment: AppEnvironment.dev),
    );
    await tester.pumpAndSettle();
    expect(find.text('Development environment'), findsOneWidget);
  });

  testWidgets('startup failure is shown instead of a blank screen', (
    tester,
  ) async {
    await tester.pumpWidget(const StartupFailureApp());
    await tester.pumpAndSettle();

    expect(
        find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.textContaining('Firebase'), findsNothing);
  });

  testWidgets('startup failure follows the Hindi device locale',
      (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('hi')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    for (final delegate in SbLocalizations.delegates) {
      await delegate.load(const Locale('hi'));
    }
    await tester.pumpWidget(const StartupFailureApp());
    await tester.pumpAndSettle();
    expect(
      find.text('कुछ गलत हुआ। कृपया फिर कोशिश करें।'),
      findsOneWidget,
    );
  });
}
