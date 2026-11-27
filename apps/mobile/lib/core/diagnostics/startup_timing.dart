// T-170: opt-in local phase measurements, not remote performance telemetry.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/app_environment.dart';

enum StartupPhase {
  binding,
  diagnosticsScheduled,
  dateFormats,
  storage,
  firebase,
  runApp,
  firstFrame
}

class StartupTiming {
  StartupTiming(AppEnvironment environment,
      {bool requested = const bool.fromEnvironment('STARTUP_TIMING_PROBE'),
      bool release = kReleaseMode,
      void Function(String)? sink})
      : enabled = requested && !release && environment != AppEnvironment.prod,
        _sink = sink ?? debugPrintSynchronously {
    if (enabled) _clock.start();
  }
  final bool enabled;
  final void Function(String) _sink;
  final Stopwatch _clock = Stopwatch();
  int _previous = 0;

  void mark(StartupPhase phase) {
    if (!enabled) return;
    final elapsed = _clock.elapsedMicroseconds;
    try {
      _sink(jsonEncode({
        'event': 'STARTUP_PHASE',
        'phase': phase.name,
        'elapsedUs': elapsed,
        'phaseUs': elapsed - _previous
      }));
    } catch (_) {/* A failed diagnostic cannot change startup behavior. */}
    _previous = elapsed;
  }
}
