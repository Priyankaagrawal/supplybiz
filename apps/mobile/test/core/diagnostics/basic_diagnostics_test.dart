import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/config/app_environment.dart';
import 'package:supplybiz_mobile/core/diagnostics/basic_diagnostics.dart';

class PrivateError {
  @override
  String toString() => throw StateError('Must never inspect private payload');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(
      () => messenger.setMockMethodCallHandler(BasicDiagnostics.channel, null));

  test('T-018 records all sources without exception, stack or arbitrary fields',
      () {
    final lines = <String>[];
    final d = BasicDiagnostics(AppEnvironment.dev, sink: lines.add);
    for (final source in DiagnosticSource.values) {
      d.record(
          source,
          StateError(
              'synthetic token=secret phone=+919000000000 https://private.invalid'));
    }
    d.record(DiagnosticSource.zone, PrivateError());
    expect(lines, hasLength(6));
    for (final line in lines) {
      expect(line.length, lessThan(512));
      expect(line, isNot(contains('secret')));
      expect(line, isNot(contains('private.invalid')));
      expect(line, isNot(contains('+919')));
      final row = jsonDecode(line) as Map<String, dynamic>;
      expect(row.keys.toSet(), {
        'event',
        'source',
        'kind',
        'environment',
        'platform',
        'version',
        'build',
        'backend',
        'at'
      });
      expect(row['backend'], 'local_log');
      expect(row['environment'], 'dev');
      expect(row['version'], 'unavailable');
    }
    expect(jsonDecode(lines.last)['kind'], 'unknown');
  });

  test('native Android version/build are allowlisted and captured', () async {
    messenger.setMockMethodCallHandler(BasicDiagnostics.channel, (call) async {
      expect(call.method, 'diagnosticBuild');
      return {'version': '0.1.0', 'build': '12'};
    });
    final lines = <String>[];
    final d = BasicDiagnostics(AppEnvironment.staging, sink: lines.add);
    await d.identifyBuild();
    d.record(DiagnosticSource.startup, const FormatException('private'));
    expect(jsonDecode(lines.single), containsPair('version', '0.1.0'));
    expect(jsonDecode(lines.single), containsPair('build', '12'));
    expect(jsonDecode(lines.single), containsPair('kind', 'format'));
  });

  test(
      'T-170 pending metadata permits diagnostics and updates after completion',
      () async {
    final response = Completer<Map<String, String>>();
    messenger.setMockMethodCallHandler(
        BasicDiagnostics.channel, (_) => response.future);
    final lines = <String>[];
    final d = BasicDiagnostics(AppEnvironment.dev, sink: lines.add);
    final lookup = d.identifyBuild();
    d.record(DiagnosticSource.startup, StateError('synthetic'));
    expect(jsonDecode(lines.single)['version'], 'unavailable');
    response.complete({'version': '0.1.0', 'build': '12'});
    await lookup;
    d.record(DiagnosticSource.startup, StateError('synthetic'));
    expect(jsonDecode(lines.last)['version'], '0.1.0');
    expect(jsonDecode(lines.last)['build'], '12');
  });

  test('invalid native identity is omitted without leaking it', () async {
    messenger.setMockMethodCallHandler(
        BasicDiagnostics.channel,
        (_) async => {
              'version': 'synthetic-private-email@example.invalid',
              'build': 'private-token'
            });
    final lines = <String>[];
    final d = BasicDiagnostics(AppEnvironment.prod, sink: lines.add);
    await d.identifyBuild();
    d.record(DiagnosticSource.startup, StateError('private'));
    expect(jsonDecode(lines.single)['version'], 'unavailable');
    expect(jsonDecode(lines.single)['build'], 'unavailable');
    expect(lines.single, isNot(contains('private')));
  });

  test('missing native channel does not block diagnostics', () async {
    final lines = <String>[];
    final d = BasicDiagnostics(AppEnvironment.dev, sink: lines.add);
    await expectLater(d.identifyBuild(), completes);
    d.record(DiagnosticSource.startup, StateError('private'));
    expect(jsonDecode(lines.single)['version'], 'unavailable');
  });

  test('framework and platform handlers capture safely and can be restored',
      () {
    final lines = <String>[];
    final framework = FlutterError.onError,
        platform = PlatformDispatcher.instance.onError;
    final restore =
        BasicDiagnostics(AppEnvironment.dev, sink: lines.add).install();
    try {
      FlutterError.onError!(FlutterErrorDetails(
          exception: PrivateError(),
          stack: StackTrace.fromString('private stack')));
      expect(
          PlatformDispatcher.instance.onError!(
              PrivateError(), StackTrace.fromString('private stack')),
          isTrue);
    } finally {
      restore();
    }
    expect(FlutterError.onError, same(framework));
    expect(PlatformDispatcher.instance.onError, same(platform));
    expect(
        lines.map((l) => jsonDecode(l)['source']), ['framework', 'platform']);
    expect(lines.join(), isNot(contains('private')));
  });

  test('uncaught asynchronous zone errors produce safe records', () async {
    final done = Completer<void>(), lines = <String>[];
    final d = BasicDiagnostics(AppEnvironment.dev, sink: lines.add);
    runZonedGuarded(() {
      Timer.run(() => throw PrivateError());
    }, (error, stack) {
      d.record(DiagnosticSource.zone, error);
      done.complete();
    });
    await done.future;
    expect(jsonDecode(lines.single)['source'], 'zone');
  });

  test('self-test requires explicit opt-in and is disabled in prod and release',
      () {
    final lines = <String>[];
    final dev = BasicDiagnostics(AppEnvironment.dev, sink: lines.add);
    dev.selfTest(requested: false);
    dev.selfTest(requested: true, release: true);
    BasicDiagnostics(AppEnvironment.prod, sink: lines.add)
        .selfTest(requested: true, release: false);
    expect(lines, isEmpty);
    dev.selfTest(requested: true, release: false);
    expect(jsonDecode(lines.single)['source'], 'selfTest');
  });

  test('broken sinks cannot crash the app or recurse', () {
    final d = BasicDiagnostics(AppEnvironment.dev,
        sink: (_) => throw StateError('private'));
    expect(() => d.record(DiagnosticSource.framework, PrivateError()),
        returnsNormally);
  });
}
