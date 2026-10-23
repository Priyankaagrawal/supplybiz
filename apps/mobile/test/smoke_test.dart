import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';

void main() {
  test('all documented mobile flavors are available', () {
    expect(
      AppEnvironment.values.map((environment) => environment.name),
      ['dev', 'staging', 'prod'],
    );
  });
}
