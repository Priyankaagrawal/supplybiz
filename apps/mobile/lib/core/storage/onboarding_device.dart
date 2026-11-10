import 'package:flutter/services.dart';

const onboardingChannel = MethodChannel('in.supplybiz/onboarding');

/// Android SAF and window security. File contents stay in memory until upload.
class OnboardingDevice {
  const OnboardingDevice();
  Future<void> secure(bool enabled, String owner) => onboardingChannel
      .invokeMethod<void>('secure', {'enabled': enabled, 'owner': owner});
  Future<Map<String, dynamic>?> pick() =>
      onboardingChannel.invokeMapMethod<String, dynamic>('pick');
  Future<Uint8List?> previewPdf(Uint8List bytes) =>
      onboardingChannel.invokeMethod<Uint8List>('previewPdf', {'bytes': bytes});
}
