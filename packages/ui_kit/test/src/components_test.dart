import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadTestLocalizations);
  test('TC-502 integer INR grouping and nonzero paise', () {
    expect(formatInr(12000000), '₹1,20,000');
    expect(formatInr(5050), '₹50.50');
    expect(formatInr(0), '₹0');
    expect(formatInr(-1), '-₹0.01');
    expect(formatInr(100000000), '₹10,00,000');
  });

  testWidgets('TC-508 quantity bounds and controlled updates', (tester) async {
    var value = 0;
    await tester.pumpWidget(
      testApp(
        StatefulBuilder(
          builder: (context, update) => SbQuantityStepper(
            value: value,
            max: 2,
            onChanged: (next) => update(() => value = next),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Decrease quantity'));
    expect(value, 0);
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(value, 1);
    await tester.longPress(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();
    expect(value, lessThanOrEqualTo(2));
  });

  testWidgets('TC-508 loading button cannot submit twice', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      testApp(
        SbButton(label: 'Continue', loading: true, onPressed: () => calls++),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Continue'));
    expect(calls, 0);
  });

  testWidgets('TC-508 search debounce and cancellation', (tester) async {
    final values = <String>[];
    await tester.pumpWidget(testApp(SbSearchBar(onChanged: values.add)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'm');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'milk');
    await tester.pump(const Duration(milliseconds: 299));
    expect(values, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(values, ['milk']);
    await tester.enterText(find.byType(TextField), 'discard');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(values, ['milk']);
  });

  testWidgets('TC-509 upload type and size validation before callback', (
    tester,
  ) async {
    var file = const SbUploadFile(
      name: 'sample.png',
      mimeType: 'image/png',
      sizeBytes: 2048,
    );
    final accepted = <SbUploadFile>[];
    await tester.pumpWidget(
      testApp(
        SbUploadField(
          label: 'Upload',
          pickFile: () async => file,
          onSelected: accepted.add,
          allowedTypes: const {'image/png'},
          maxBytes: 1024,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose file'));
    await tester.pumpAndSettle();
    expect(accepted, isEmpty);
    expect(
      find.text('Unsupported file type or file is too large'),
      findsOneWidget,
    );
    file = const SbUploadFile(
      name: 'sample.png',
      mimeType: 'image/png',
      sizeBytes: 512,
    );
    await tester.tap(find.text('Choose file'));
    await tester.pumpAndSettle();
    expect(accepted, [file]);
  });

  testWidgets('TC-508 chart data has a table alternative', (tester) async {
    await tester.pumpWidget(
      testApp(
        const SbChart(
          data: [
            SbChartDatum(label: 'Milk', value: 5050, formattedValue: '₹50.50'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('View as table'));
    await tester.pumpAndSettle();
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('₹50.50'), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
  });

  for (final language in ['en', 'hi']) {
    testWidgets('TC-610/611 $language tap targets, labels and contrast', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      for (final widget in catalog(language)) {
        await tester.pumpWidget(testApp(widget, language: language));
        // Busy indicators intentionally animate; never wait for them to settle.
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(widget.runtimeType), findsWidgets);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      semantics.dispose();
    });
    testWidgets('TC-613 $language at 200% on a 320dp phone', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final widget in catalog(language)) {
        await tester.pumpWidget(testApp(widget, language: language, scale: 2));
        await tester.pump(const Duration(seconds: 1));
        expect(
          tester.takeException(),
          isNull,
          reason: widget.runtimeType.toString(),
        );
      }
    });
  }
}
