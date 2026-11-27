// T-172 / TC-610–613: focused real-screen audit, synthetic HTTP and memory stores.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/storage/onboarding_device.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_controller.dart';
import 'package:supplybiz_mobile/features/onboarding/onboarding_pages.dart';
import 'package:supplybiz_mobile/features/orders/orders_controller.dart';
import 'package:supplybiz_mobile/features/subscriptions/customer_subscriptions_pages.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../../../packages/ui_kit/test/src/test_app.dart'
    show loadTestLocalizations;
import '../features/onboarding/onboarding_test.dart'
    show MemoryDrafts, OnboardingFixture, makeController;
import '../features/orders/orders_test.dart'
    show OrdersFixture, ordersClient, ordersApp, orderId;
import '../features/products/catalog_fixture.dart' show syntheticProductId;
import '../features/subscriptions/customer_subscription_fixture.dart';
import '../features/subscriptions/customer_subscriptions_test.dart' as sub;
import '../features/khata/customer_khata_fixture.dart';
import '../features/khata/customer_khata_test.dart' as khata;

/// The SDK excludes clipped targets at scroll boundaries, but compares the
/// transformed child with the untransformed viewport. Put both in root space
/// so a field clipped by an app bar is not mistaken for a 24dp control.
class VisibleAndroidTapTargets extends AccessibilityGuideline {
  const VisibleAndroidTapTargets();

  @override
  String get description => 'Fully visible Android targets are at least 48dp';

  Rect rootBounds(SemanticsNode node) {
    var bounds = node.rect;
    for (SemanticsNode? current = node;
        current != null;
        current = current.parent) {
      if (current.transform != null) {
        bounds = MatrixUtils.transformRect(current.transform!, bounds);
      }
    }
    return bounds;
  }

  bool clipped(Rect bounds, Rect viewport, double minimum) =>
      !bounds.overlaps(viewport) ||
      (bounds.width < minimum &&
          (bounds.left <= viewport.left + .001 ||
              bounds.right >= viewport.right - .001)) ||
      (bounds.height < minimum &&
          (bounds.top <= viewport.top + .001 ||
              bounds.bottom >= viewport.bottom - .001));

  @override
  Evaluation evaluate(WidgetTester tester) {
    var result = const Evaluation.pass();
    for (final view in tester.binding.renderViews) {
      final root = view.owner?.semanticsOwner?.rootSemanticsNode;
      if (root == null) {
        return const Evaluation.fail('Semantics tree unavailable');
      }
      final ratio = view.flutterView.devicePixelRatio;
      void visit(SemanticsNode node) {
        node.visitChildren((child) {
          visit(child);
          return true;
        });
        if (node.isMergedIntoParent ||
            (androidTapTargetGuideline as MinimumTapTargetGuideline)
                .shouldSkipNode(node)) {
          return;
        }
        final bounds = rootBounds(node), minimum = 48 * ratio;
        if (clipped(
            bounds, Offset.zero & view.flutterView.physicalSize, minimum)) {
          return;
        }
        for (SemanticsNode? parent = node.parent;
            parent != null;
            parent = parent.parent) {
          if (parent.flagsCollection.hasImplicitScrolling &&
              clipped(bounds, rootBounds(parent), minimum)) {
            return;
          }
        }
        if (bounds.width / ratio < 48 - .001 ||
            bounds.height / ratio < 48 - .001) {
          result += Evaluation.fail(
              '${node.getSemanticsData().label}: ${bounds.size / ratio}; expected at least 48dp');
        }
      }

      visit(root);
    }
    return result;
  }
}

Future<void> auditVisible(WidgetTester tester, {required bool contrast}) async {
  expect(tester.takeException(), isNull);
  await expectLater(tester, meetsGuideline(const VisibleAndroidTapTargets()));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  if (contrast) {
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }
}

Future<void> auditScroll(WidgetTester tester, {required bool contrast}) async {
  await tester.pumpAndSettle();
  await auditVisible(tester, contrast: contrast);
  // Audit each viewport, including controls that begin below the fold.
  final scrollable = find.byType(Scrollable).first;
  final position = tester.state<ScrollableState>(scrollable).position;
  var visited = 0;
  while (position.pixels < position.maxScrollExtent && visited++ < 30) {
    await tester.drag(scrollable, const Offset(0, -280));
    await tester.pumpAndSettle();
    await auditVisible(tester, contrast: contrast);
  }
  expect(position.pixels, position.maxScrollExtent,
      reason:
          'The audit must reach the bottom rather than skip hidden actions');
}

void registerAccessibilityAudit({bool native = false}) {
  setUpAll(loadTestLocalizations);
  for (final scale in [1.0, 2.0]) {
    for (final journey in ['J-01', 'J-02', 'J-03', 'J-06']) {
      testWidgets('T-172 TC-610/611/613 $journey at ${scale * 100}%',
          (tester) async {
        if (!native) {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 800);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              onboardingChannel, (call) async => null);
          addTearDown(() => tester.binding.defaultBinaryMessenger
              .setMockMethodCallHandler(onboardingChannel, null));
        }
        final semantics = tester.ensureSemantics();
        try {
          final contrast = !native;
          if (journey == 'J-01') {
            final fixture = OnboardingFixture()..step = 2;
            final model = makeController(fixture, MemoryDrafts());
            await tester.runAsync(model.load);
            await tester.pumpWidget(ProviderScope(
                overrides: [onboardingProvider.overrideWith((ref) => model)],
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
                    home: const OnboardingPage())));
            await auditScroll(tester, contrast: contrast);
          } else if (journey == 'J-02') {
            final fixture = OrdersFixture(), http = ordersClient(fixture);
            addTearDown(http.close);
            final model = VendorOrdersController(
                VendorOrdersApi(http.dio), MemoryDrafts(), 'synthetic:audit');
            await tester.runAsync(() => model.open(orderId));
            await tester.pumpWidget(ordersApp(model, scale: scale));
            await auditScroll(tester, contrast: contrast);
            final reject = find.widgetWithText(SbButton, 'Reject order');
            await tester.ensureVisible(reject);
            await tester.pumpAndSettle();
            await tester.tap(reject);
            await tester.pumpAndSettle();
            await auditVisible(tester, contrast: contrast);
            expect(find.byType(BottomSheet), findsOneWidget);
          } else if (journey == 'J-03') {
            final fixture = CustomerSubscriptionFixture();
            final model =
                sub.customerSubscriptionModel(fixture, MemoryDrafts());
            addTearDown(model.client.close);
            await tester.runAsync(() async {
              await model.load();
              await model.prepare(syntheticProductId);
            });
            await tester.pumpWidget(sub.customerSubscriptionApp(model,
                scale: scale,
                child: CustomerSubscriptionEditor(
                    model: model, plan: model.plans!.items.first)));
            await auditScroll(tester, contrast: contrast);
            expect(fixture.writes, isEmpty);
          } else {
            final fixture = CustomerKhataFixture()..vpa = null;
            final model = khata.model(fixture, MemoryDrafts(),
                scope: 'vendor:$khataVendor');
            addTearDown(model.client.close);
            await tester.runAsync(() => khata.ready(model));
            await tester.pumpWidget(khata.app(model, scale: scale));
            await khata.settle(tester, model);
            await auditScroll(tester, contrast: contrast);
            tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position
                .jumpTo(0);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
                find.widgetWithText(SbButton, 'Settle dues'), 280,
                scrollable: find.byType(Scrollable).first);
            final settle = find.widgetWithText(SbButton, 'Settle dues');
            await Scrollable.ensureVisible(tester.element(settle),
                alignment: .5);
            await tester.pumpAndSettle();
            await tester.tap(settle);
            await khata.settle(tester, model);
            await auditVisible(tester, contrast: contrast);
            expect(find.byType(AlertDialog), findsOneWidget);
            expect(find.text('I paid cash - submit claim'), findsOneWidget);
            expect(fixture.writes, isEmpty);
          }
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          semantics.dispose();
        }
      });
    }
  }
}
