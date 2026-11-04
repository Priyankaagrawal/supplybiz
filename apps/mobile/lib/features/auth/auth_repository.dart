import 'package:dio/dio.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/app_failure.dart';
import '../../core/network/network_client.dart';
import '../../core/storage/app_storage.dart';

abstract interface class AuthStorage {
  Future<void> initialize();
  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String token);
  Future<String> installationId();
  Future<void> wipeOnLogout();
}

class DeviceAuthStorage implements AuthStorage {
  DeviceAuthStorage(this.storage);
  final AppStorage storage;
  @override
  Future<void> initialize() => storage.initialize();
  @override
  Future<String?> readRefreshToken() => storage.readRefreshToken();
  @override
  Future<void> writeRefreshToken(String token) =>
      storage.writeRefreshToken(token);
  @override
  Future<void> wipeOnLogout() => storage.wipeOnLogout();
  @override
  Future<String> installationId() => storage.installationId();
}

class AuthRepository {
  AuthRepository(NetworkClient client)
      : auth = AuthApi(client.dio),
        me = MeApi(client.dio);
  final AuthApi auth;
  final MeApi me;
  static const _uuid = Uuid();
  static const _public = {NetworkClient.publicRequest: true};
  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  Future<void> send(
          String mobile, String channel, String device, String? hash) =>
      _call(() async {
        await auth.otpControllerSend(
            xDeviceId: device,
            idempotencyKey: _uuid.v4(),
            sendOtpDto: SendOtpDto(
                mobile: mobile,
                channel: channel == 'SMS'
                    ? SendOtpDtoChannelEnum.SMS
                    : SendOtpDtoChannelEnum.WHATSAPP,
                appHash: hash),
            extra: _public);
      });
  Future<TokensResponse> verify(
          String mobile, String code, ConsentDto consent) =>
      _call(() async => (await auth.sessionsControllerVerify(
              idempotencyKey: _uuid.v4(),
              verifyOtpDto: VerifyOtpDto(
                  mobile: mobile,
                  code: code,
                  consent: consent,
                  device: DeviceDto(platform: DeviceDtoPlatformEnum.ANDROID)),
              extra: _public))
          .data!);
  Future<TokensResponse> refresh(String token) =>
      _call(() async => (await auth.sessionsControllerRefresh(
              idempotencyKey: _uuid.v4(),
              refreshDto: RefreshDto(refreshToken: token),
              extra: _public))
          .data!);
  Future<MeResponse> currentUser() =>
      _call(() async => (await me.meControllerMe()).data!);
  Future<MeResponse> role(String value, {required bool held}) =>
      _call(() async {
        final input = RoleDto(
            role: value == 'CUSTOMER'
                ? RoleDtoRoleEnum.CUSTOMER
                : RoleDtoRoleEnum.VENDOR);
        if (!held) {
          await me.meControllerAddRole(
              idempotencyKey: _uuid.v4(), roleDto: input);
        }
        return (await me.meControllerActiveRole(
                idempotencyKey: _uuid.v4(), roleDto: input))
            .data!;
      });
  Future<void> logout(bool all) => _call(() async {
        await auth.sessionsControllerLogout(
            idempotencyKey: _uuid.v4(), all: all ? 'true' : 'false');
      });
}
