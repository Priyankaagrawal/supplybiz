// T-018: main-isolate diagnostics. Never serialize an exception or stack trace.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/app_environment.dart';

enum DiagnosticSource { framework, platform, zone, startup, selfTest }

class BasicDiagnostics {
  BasicDiagnostics(this.environment, {void Function(String)? sink})
      : _sink = sink ?? debugPrintSynchronously;
  final AppEnvironment environment;
  final void Function(String) _sink;
  String _version = 'unavailable', _build = 'unavailable';
  static const channel = MethodChannel('in.supplybiz/app');

  Future<void> identifyBuild() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final value = await channel
          .invokeMapMethod<String, String>('diagnosticBuild')
          .timeout(const Duration(seconds: 2));
      final version = value?['version'] ?? '', build = value?['build'] ?? '';
      if (RegExp(r'^\d{1,6}\.\d{1,6}\.\d{1,6}$').hasMatch(version)) {
        _version = version;
      }
      if (RegExp(r'^\d{1,12}$').hasMatch(build)) _build = build;
    } catch (_) {
      // Unavailable native metadata must not prevent startup or leak its error.
    }
  }

  void record(DiagnosticSource source, Object error) {
    final kind = switch (error) {
      FormatException() => 'format',
      StateError() => 'state',
      AssertionError() => 'assertion',
      _ => 'unknown',
    };
    try {
      _sink(jsonEncode({
        'event': 'MOBILE_DIAGNOSTIC',
        'source': source.name,
        'kind': kind,
        'environment': environment.name,
        'platform': defaultTargetPlatform.name,
        'version': _version,
        'build': _build,
        'backend': 'local_log',
        'at': DateTime.now().toUtc().toIso8601String(),
      }));
    } catch (_) {
      // A broken diagnostic sink must never produce another unhandled error.
    }
  }

  VoidCallback install() {
    final previousFramework = FlutterError.onError;
    final previousPlatform = PlatformDispatcher.instance.onError;
    FlutterError.onError =
        (details) => record(DiagnosticSource.framework, details.exception);
    PlatformDispatcher.instance.onError = (error, _) {
      record(DiagnosticSource.platform, error);
      return true;
    };
    return () {
      FlutterError.onError = previousFramework;
      PlatformDispatcher.instance.onError = previousPlatform;
    };
  }

  void selfTest({required bool requested, bool release = kReleaseMode}) {
    if (requested && !release && environment != AppEnvironment.prod) {
      record(DiagnosticSource.selfTest, StateError('Synthetic diagnostic'));
    }
  }
}
