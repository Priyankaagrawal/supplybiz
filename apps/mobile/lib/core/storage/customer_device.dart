import 'package:flutter/services.dart';

const customerDeviceChannel = MethodChannel('in.supplybiz/customers');

/// Opens the dialer for a normalized Indian number; never places a call itself.
class CustomerDevice {
  const CustomerDevice();
  Future<bool> dial(String mobile) async {
    if (!RegExp(r'^\+91[6-9]\d{9}$').hasMatch(mobile)) return false;
    try {
      return await customerDeviceChannel
              .invokeMethod<bool>('dial', {'mobile': mobile}) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
