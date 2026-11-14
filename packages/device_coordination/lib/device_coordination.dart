import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// A process-wide Android critical section shared by foreground/headless engines.
/// Tokens are native-only capabilities and contain no account/session data.
class DeviceCoordination {
  static const channel = MethodChannel('in.supplybiz/device-coordination');
  static final Object _held = Object();
  static bool get isHeld =>
      Zone.current[_held] is _Lease && (Zone.current[_held] as _Lease).active;
  static Future<String> appVersion() async {
    final version = await channel.invokeMethod<String>('version');
    if (version == null) throw StateError('App version unavailable.');
    return version;
  }

  static Future<T> exclusive<T>(Future<T> Function() action) async {
    if (!Platform.isAndroid || isHeld) return action();
    final token = await channel.invokeMethod<String>('acquire');
    if (token == null) throw StateError('Device coordination is unavailable.');
    final lease = _Lease();
    try {
      return await runZoned(action, zoneValues: {_held: lease});
    } finally {
      lease.active = false;
      await channel.invokeMethod<void>('release', {'token': token});
    }
  }
}

class _Lease {
  bool active = true;
}
