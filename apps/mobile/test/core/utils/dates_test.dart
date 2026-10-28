import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/utils/dates.dart';

void main() {
  setUpAll(initializeDateFormatters);

  test('IST business date rolls over at 18:30 UTC', () {
    expect(istDateKey(DateTime.parse('2026-10-28T18:29:59Z')), '2026-10-28');
    expect(istDateKey(DateTime.parse('2026-10-28T18:30:00Z')), '2026-10-29');
    expect(
        formatIstDate(DateTime.parse('2026-10-28T18:30:00Z')), 'Oct 29, 2026');
    expect(formatIstDateTime(DateTime.parse('2026-10-28T18:30:00Z')),
        'Oct 29, 2026 00:00');
  });

  test('IST conversion handles year boundaries and leap days', () {
    expect(istDateKey(DateTime.parse('2026-12-31T20:00:00Z')), '2027-01-01');
    expect(istDateKey(DateTime.parse('2028-02-28T20:00:00Z')), '2028-02-29');
  });

  test('an explicit offset and local DateTime preserve the same instant', () {
    final utc = DateTime.parse('2026-10-28T18:30:00Z');
    final offset = DateTime.parse('2026-10-28T14:30:00-04:00');
    expect(formatIstDateTime(offset), formatIstDateTime(utc));
    expect(formatIstDateTime(utc.toLocal()), formatIstDateTime(utc));
    expect(utc.hour, 18);
  });

  test('Hindi dates use bundled Hindi month names', () {
    final timestamp = DateTime.parse('2026-01-01T00:00:00Z');
    expect(formatIstDate(timestamp, locale: 'hi'), '1 जन॰ 2026');
    expect(formatIstDateTime(timestamp, locale: 'hi'), '1 जन॰ 2026 05:30');
  });
}
