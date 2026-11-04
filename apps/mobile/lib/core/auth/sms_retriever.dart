import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android SMS Retriever. No SMS permission; manual input remains available.
class SmsRetriever {
  static const _channel = MethodChannel('in.supplybiz/sms');
  Timer? _timeout;
  Completer<String?>? _pending;
  Future<String?> start(void Function(String) onCode) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    _finish(null);
    final pending = _pending = Completer<String?>();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'code' &&
          call.arguments is String &&
          RegExp(r'^\d{6}$').hasMatch(call.arguments as String)) {
        onCode(call.arguments as String);
      }
    });
    _timeout = Timer(const Duration(seconds: 3), () => _finish(null));
    unawaited(_channel.invokeMethod<String>('start').then((hash) {
      if (identical(_pending, pending)) _finish(hash);
    }, onError: (Object _) {
      if (identical(_pending, pending)) _finish(null);
    }));
    return pending.future;
  }

  void _finish(String? value) {
    _timeout?.cancel();
    _timeout = null;
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(value);
  }

  void stop() {
    _finish(null);
    _channel.setMethodCallHandler(null);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Best effort: a missing bridge must not prevent navigating away.
      unawaited(_channel.invokeMethod<void>('stop').catchError((Object _) {}));
    }
  }
}
