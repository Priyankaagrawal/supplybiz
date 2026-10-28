import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/l10n/l10n.dart';
import 'package:supplybiz_mobile/core/network/app_failure.dart';

DioException _error(
    {int? status,
    Object? body,
    DioExceptionType type = DioExceptionType.badResponse}) {
  final options = RequestOptions(path: 'test');
  return DioException(
      requestOptions: options,
      type: type,
      response: status == null
          ? null
          : Response<dynamic>(
              requestOptions: options, statusCode: status, data: body));
}

void main() {
  test('Problem Details map to typed failures using the HTTP status', () {
    final cases = <int, Matcher>{
      400: isA<ValidationFailure>(),
      401: isA<UnauthorizedFailure>(),
      403: isA<ForbiddenFailure>(),
      404: isA<NotFoundFailure>(),
      409: isA<ConflictFailure>(),
      410: isA<BusinessRuleFailure>(),
      422: isA<BusinessRuleFailure>(),
      426: isA<BusinessRuleFailure>(),
      429: isA<BusinessRuleFailure>(),
      500: isA<ServerFailure>(),
      503: isA<ServerFailure>(),
      418: isA<UnknownFailure>(),
    };
    for (final entry in cases.entries) {
      expect(
          mapDioFailure(_error(status: entry.key, body: {
            'code': 'TEST_CODE',
            'status': 200,
            'requestId': 'test-request-id',
          })),
          entry.value,
          reason: 'HTTP ${entry.key}');
    }
  });

  test('validation preserves field codes but drops raw provider messages', () {
    final failure = mapDioFailure(_error(status: 422, body: {
      'code': 'VALIDATION_FAILED',
      'requestId': 'test-request-id',
      'detail': 'test-private-detail',
      'errors': [
        {
          'field': 'qty',
          'code': 'BELOW_MOQ',
          'message': 'test-private-message'
        },
        {'field': 'qty', 'code': 'REQUIRED'},
        {'field': 'ignored', 'message': 'test-private-message'},
        42,
      ],
    })) as ValidationFailure;
    expect(failure.code, 'VALIDATION_FAILED');
    expect(failure.requestId, 'test-request-id');
    expect(failure.fieldErrors, {
      'qty': ['BELOW_MOQ', 'REQUIRED']
    });
    expect(
        () => failure.fieldErrors['qty']!.add('OTHER'), throwsUnsupportedError);
  });

  test('transport failures and malformed response bodies are safe', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout
    ]) {
      expect(mapDioFailure(_error(type: type)), isA<TimeoutFailure>());
    }
    expect(mapDioFailure(_error(type: DioExceptionType.connectionError)),
        isA<NetworkFailure>());
    expect(mapDioFailure(_error(type: DioExceptionType.cancel)).code,
        'REQUEST_CANCELLED');
    expect(mapDioFailure(_error(type: DioExceptionType.badCertificate)),
        isA<UnknownFailure>());
    for (final body in [
      null,
      'html error',
      12,
      ['bad'],
      {'code': 7}
    ]) {
      expect(
          mapDioFailure(_error(status: 500, body: body)), isA<ServerFailure>());
    }
    final failure = mapDioFailure(_error(status: 403, body: {
      'code': 'test unsafe\nprovider text',
      'requestId': {'bad': true},
    }));
    expect(failure.code, isNull);
    expect(failure.requestId, isNull);
  });

  test('failure messages use EN/HI strings, never raw title or detail',
      () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final hi = await AppLocalizations.delegate.load(const Locale('hi'));
    final failure = mapDioFailure(_error(status: 403, body: {
      'code': 'PLAN_FEATURE_LOCKED',
      'title': 'test-private-provider-title',
      'detail': 'test-private-detail',
    }));
    expect(failure.toMessage(en), en.networkPlanLocked);
    expect(failure.toMessage(hi), hi.networkPlanLocked);
    expect(failure.toMessage(en), isNot(failure.toMessage(hi)));
    expect(failure.toMessage(en), isNot(contains('test-private')));
    expect(const ConflictFailure(code: 'VERSION_CONFLICT').toMessage(en),
        en.networkVersionConflict);
    expect(const BusinessRuleFailure(code: 'RATE_LIMITED').toMessage(hi),
        hi.networkRateLimited);
  });
}
