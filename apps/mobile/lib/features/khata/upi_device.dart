// T-083: external app results are never proof of payment.
import 'package:flutter/services.dart';
import '../sales/sales_controller.dart' show saleDecimal;

class UpiDevice {
  static const channel = MethodChannel('in.supplybiz/upi');
  Future<bool> open(Uri uri) async {
    try {
      final result =
          await channel.invokeMethod<Object?>('pay', {'uri': uri.toString()});
      return result == true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

Uri khataUpiUri(String vpa, String name, BigInt amount) {
  if (!RegExp(r'^[\w.-]{2,256}@[a-zA-Z]{2,64}$').hasMatch(vpa) ||
      name.trim().isEmpty ||
      name.length > 200 ||
      amount <= BigInt.zero ||
      amount > BigInt.parse('9223372036854775807')) {
    throw const FormatException('Invalid payment details');
  }
  return Uri(scheme: 'upi', host: 'pay', queryParameters: {
    'pa': vpa,
    'pn': name,
    'am': saleDecimal(amount),
    'cu': 'INR',
    'tn': 'Supply Biz Khata'
  });
}
