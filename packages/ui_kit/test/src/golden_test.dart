import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadTestLocalizations);
  for (final language in ['en', 'hi']) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('TC-507 T-009 catalog $language ${width.toInt()} $scale', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          const boundary = ValueKey('catalog');
          await tester.pumpWidget(
            testApp(
              RepaintBoundary(
                key: boundary,
                child: ColoredBox(
                    color: SbColors.background,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final widget in catalog(language))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: widget,
                          ),
                      ],
                    )),
              ),
              language: language,
              scale: scale,
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(boundary),
            matchesGoldenFile(
              'goldens/catalog_${language}_${width.toInt()}_$scale.png',
            ),
          );
        });
      }
    }
  }
}
