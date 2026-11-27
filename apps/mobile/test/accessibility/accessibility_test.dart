import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'audit_scenarios.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('TC-610 scroll audit rejects 24dp and accepts 48dp targets',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      for (final height in [24.0, 48.0]) {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                appBar: AppBar(title: const Text('Synthetic calibration')),
                body: ListView(children: [
                  const SizedBox(height: 100),
                  Center(
                      child: SizedBox(
                          width: 100,
                          height: height,
                          child: Semantics(
                              button: true,
                              label: 'Synthetic undersized action',
                              child: GestureDetector(
                                  onTap: () {},
                                  child: Container(color: Colors.blue))))),
                  const SizedBox(height: 1000)
                ]))));
        final result = const VisibleAndroidTapTargets().evaluate(tester);
        expect(result.passed, height == 48);
      }
    } finally {
      semantics.dispose();
    }
  });
  registerAccessibilityAudit();
}
