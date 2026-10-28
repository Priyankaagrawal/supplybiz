import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/utils/money.dart';

void main() {
  test('TC-502 INR uses Indian grouping and optional nonzero paise', () {
    const cases = {
      12000000: '₹1,20,000',
      5050: '₹50.50',
      0: '₹0',
      1: '₹0.01',
      10: '₹0.10',
      100: '₹1',
      99999: '₹999.99',
      100000: '₹1,000',
      10000000: '₹1,00,000',
      1000000000: '₹1,00,00,000',
      -1: '-₹0.01',
      -5050: '-₹50.50',
      -12000000: '-₹1,20,000',
      // Exceeds exact double integer precision; formatting stays integer-only.
      9007199254740993: '₹9,00,71,99,25,47,409.93',
    };
    for (final entry in cases.entries) {
      expect(formatInr(entry.key), entry.value, reason: '${entry.key} paise');
    }
  });
}
