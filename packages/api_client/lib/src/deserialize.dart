import 'package:supplybiz_api_client/src/model/consent_dto.dart';
import 'package:supplybiz_api_client/src/model/device_dto.dart';
import 'package:supplybiz_api_client/src/model/health_controller_get_live200_response.dart';
import 'package:supplybiz_api_client/src/model/me_response.dart';
import 'package:supplybiz_api_client/src/model/refresh_dto.dart';
import 'package:supplybiz_api_client/src/model/role_dto.dart';
import 'package:supplybiz_api_client/src/model/send_otp_dto.dart';
import 'package:supplybiz_api_client/src/model/send_otp_response.dart';
import 'package:supplybiz_api_client/src/model/tokens_response.dart';
import 'package:supplybiz_api_client/src/model/verify_otp_dto.dart';
import 'package:supplybiz_api_client/src/model/version_controller_get_version200_response.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'ConsentDto':
          return ConsentDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceDto':
          return DeviceDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'HealthControllerGetLive200Response':
          return HealthControllerGetLive200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MeResponse':
          return MeResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RefreshDto':
          return RefreshDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RoleDto':
          return RoleDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SendOtpDto':
          return SendOtpDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SendOtpResponse':
          return SendOtpResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TokensResponse':
          return TokensResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VerifyOtpDto':
          return VerifyOtpDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VersionControllerGetVersion200Response':
          return VersionControllerGetVersion200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!.trim(); // ignore: parameter_assignments
            return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    }
    throw Exception('Cannot deserialize');
  }