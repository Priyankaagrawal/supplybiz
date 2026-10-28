import 'package:dio/dio.dart';

import '../l10n/l10n.dart';

/// Safe application errors. Provider text and request bodies are never retained.
sealed class AppFailure implements Exception {
  const AppFailure({this.code, this.requestId});
  final String? code;
  final String? requestId;

  String toMessage(AppLocalizations l10n) => switch (this) {
        NetworkFailure() => l10n.networkUnavailable,
        TimeoutFailure() => l10n.networkTimeout,
        UnauthorizedFailure() => l10n.networkUnauthorized,
        ForbiddenFailure(code: 'PLAN_FEATURE_LOCKED') => l10n.networkPlanLocked,
        ForbiddenFailure() => l10n.networkForbidden,
        NotFoundFailure() => l10n.networkNotFound,
        ConflictFailure(code: 'VERSION_CONFLICT') =>
          l10n.networkVersionConflict,
        ConflictFailure() => l10n.networkConflict,
        ValidationFailure() => l10n.networkValidation,
        BusinessRuleFailure(code: 'RATE_LIMITED') => l10n.networkRateLimited,
        BusinessRuleFailure() => l10n.networkBusinessRule,
        ServerFailure() => l10n.networkServer,
        UnknownFailure() => l10n.startupError,
      };
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure();
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({super.code, super.requestId});
}

final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({super.code, super.requestId});
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({super.code, super.requestId});
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure({super.code, super.requestId});
}

final class ValidationFailure extends AppFailure {
  ValidationFailure(
      {required Map<String, List<String>> fieldErrors,
      super.code,
      super.requestId})
      : fieldErrors = Map.unmodifiable(fieldErrors.map(
          (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
        ));
  final Map<String, List<String>> fieldErrors;
}

final class BusinessRuleFailure extends AppFailure {
  const BusinessRuleFailure({super.code, super.requestId});
}

final class ServerFailure extends AppFailure {
  const ServerFailure({super.code, super.requestId});
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({super.code});
}

String? _safeIdentifier(Object? value) =>
    value is String && RegExp(r'^[a-zA-Z0-9_.\[\]-]{1,128}$').hasMatch(value)
        ? value
        : null;

AppFailure mapDioFailure(DioException error) {
  if (error.error case final AppFailure failure) return failure;
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.cancel:
      return const UnknownFailure(code: 'REQUEST_CANCELLED');
    default:
      break;
  }
  final response = error.response;
  final body = response?.data;
  final problem = body is Map<String, dynamic> ? body : <String, dynamic>{};
  final code = _safeIdentifier(problem['code']);
  final requestId = _safeIdentifier(problem['requestId']) ??
      _safeIdentifier(response?.headers.map['x-request-id']?.firstOrNull);
  final status = response?.statusCode;
  return switch (status) {
    400 => ValidationFailure(
        fieldErrors: _fieldErrors(problem['errors']),
        code: code,
        requestId: requestId),
    401 => UnauthorizedFailure(code: code, requestId: requestId),
    403 => ForbiddenFailure(code: code, requestId: requestId),
    404 => NotFoundFailure(code: code, requestId: requestId),
    409 => ConflictFailure(code: code, requestId: requestId),
    422 when code == 'VALIDATION_FAILED' => ValidationFailure(
        fieldErrors: _fieldErrors(problem['errors']),
        code: code,
        requestId: requestId),
    410 ||
    422 ||
    426 ||
    429 =>
      BusinessRuleFailure(code: code, requestId: requestId),
    final int status when status >= 500 =>
      ServerFailure(code: code, requestId: requestId),
    _ => const UnknownFailure(),
  };
}

Map<String, List<String>> _fieldErrors(Object? errors) {
  final result = <String, List<String>>{};
  if (errors is! List) return result;
  for (final error in errors) {
    if (error is! Map<String, dynamic>) continue;
    final field = _safeIdentifier(error['field']);
    final code = _safeIdentifier(error['code']);
    if (field != null && code != null) {
      (result[field] ??= []).add(code);
    }
  }
  return result;
}
