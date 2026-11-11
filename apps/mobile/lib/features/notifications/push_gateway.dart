import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushGatewayProvider =
    Provider<PushGateway>((ref) => FirebasePushGateway());
final pushRefreshProvider = StateProvider<int>((ref) => 0);

abstract class PushGateway {
  bool get available;
  Stream<Map<String, dynamic>> get foreground;
  Stream<Map<String, dynamic>> get opened;
  Stream<String> get tokens;
  Future<Map<String, dynamic>?> initial();
  Future<bool> permitted({bool request = false});
  Future<String?> token();
}

class FirebasePushGateway implements PushGateway {
  @override
  bool get available => Firebase.apps.isNotEmpty;
  @override
  Stream<Map<String, dynamic>> get foreground =>
      FirebaseMessaging.onMessage.map((m) => m.data);
  @override
  Stream<Map<String, dynamic>> get opened =>
      FirebaseMessaging.onMessageOpenedApp.map((m) => m.data);
  @override
  Stream<String> get tokens => FirebaseMessaging.instance.onTokenRefresh;
  @override
  Future<Map<String, dynamic>?> initial() async =>
      (await FirebaseMessaging.instance.getInitialMessage())?.data;
  @override
  Future<bool> permitted({bool request = false}) async {
    final settings = request
        ? await FirebaseMessaging.instance.requestPermission(provisional: false)
        : await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<String?> token() async {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    return FirebaseMessaging.instance.getToken();
  }
}
