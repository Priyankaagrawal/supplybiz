import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/app.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';

void main() {
  for (final environment in AppEnvironment.values) {
    testWidgets('${environment.name} environment renders the app shell',
        (tester) async {
      await tester.pumpWidget(SupplyBizApp(environment: environment));

      expect(find.text('Supply Biz'), findsOneWidget);
      expect(
          find.text('${environment.displayName} environment'), findsOneWidget);
    });
  }

  testWidgets('startup failure is shown instead of a blank screen',
      (tester) async {
    await tester.pumpWidget(
      const StartupFailureApp(error: 'Firebase configuration is missing'),
    );

    expect(find.textContaining('could not start'), findsOneWidget);
    expect(find.textContaining('Firebase configuration is missing'),
        findsOneWidget);
  });
}
