import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/core/diagnostics/startup_timing.dart';

void main() {
  test('T-170 phase probing is opt-in and unavailable in production/release',
      () {
    final records = <String>[];
    for (final probe in [
      StartupTiming(AppEnvironment.dev, requested: false, sink: records.add),
      StartupTiming(AppEnvironment.prod,
          requested: true, release: false, sink: records.add),
      StartupTiming(AppEnvironment.dev,
          requested: true, release: true, sink: records.add),
    ]) {
      probe.mark(StartupPhase.storage);
    }
    expect(records, isEmpty);
  });
  test('phase records contain monotonic numeric timings and fixed labels only',
      () async {
    final records = <String>[];
    final probe = StartupTiming(AppEnvironment.dev,
        requested: true, release: false, sink: records.add);
    probe.mark(StartupPhase.binding);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    probe.mark(StartupPhase.storage);
    final first = jsonDecode(records[0]) as Map<String, dynamic>,
        second = jsonDecode(records[1]) as Map<String, dynamic>;
    expect(second.keys.toSet(), {'event', 'phase', 'elapsedUs', 'phaseUs'});
    expect(
        second['elapsedUs'], greaterThanOrEqualTo(first['elapsedUs'] as int));
    expect(second['phaseUs'], second['elapsedUs'] - first['elapsedUs']);
    expect(second['phase'], 'storage');
  });
  test('a broken phase sink cannot interrupt bootstrap', () {
    final probe = StartupTiming(AppEnvironment.dev,
        requested: true,
        release: false,
        sink: (_) => throw StateError('synthetic'));
    expect(() => probe.mark(StartupPhase.firstFrame), returnsNormally);
  });
}
