import 'package:flutter/services.dart';

class DeviceLocation {
  const DeviceLocation();
  static const channel = MethodChannel('in.supplybiz/location');
  Future<void> cancel() => channel.invokeMethod<void>('cancel');
  Future<(double, double)> current() async {
    final value = await channel.invokeMapMethod<String, dynamic>('current');
    final lat = value?['latitude'];
    final lng = value?['longitude'];
    if (lat is! num ||
        lng is! num ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180) {
      throw PlatformException(code: 'LOCATION_UNAVAILABLE');
    }
    return (lat.toDouble(), lng.toDouble());
  }
}
