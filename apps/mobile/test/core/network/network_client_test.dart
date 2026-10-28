import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplybiz_mobile/core/network/app_failure.dart';
import 'package:supplybiz_mobile/core/network/network_client.dart';

class _Session implements NetworkSession {
  String? token = 'test-access-old';
  int refreshes = 0;
  int clears = 0;
  Future<void> Function()? onRefresh;
  final started = Completer<void>();
  @override
  String? get accessToken => token;
  @override
  Future<void> refresh() async {
    refreshes++;
    if (!started.isCompleted) started.complete();
    await onRefresh?.call();
    token = 'test-access-new';
  }

  @override
  Future<void> clear() async {
    clears++;
    token = null;
  }
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  final headers = <Map<String, dynamic>>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    headers.add(Map.of(options.headers));
    return await respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _response(int status, [Object body = const {'ok': true}]) =>
    ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });

Future<AppFailure> _failure(Future<Response<dynamic>> request) async {
  try {
    await request;
  } on AppFailure catch (failure) {
    return failure;
  }
  throw StateError('Expected request failure');
}

void main() {
  late _Session session;
  NetworkClient client(_Adapter adapter,
      {String Function()? language, Future<void> Function(Duration)? delay}) {
    final result = NetworkClient(
        baseUrl: 'https://api.supplybiz.example/api/v1',
        session: session,
        adapter: adapter,
        language: language,
        delay: delay ?? (_) async {});
    addTearDown(result.close);
    return result;
  }

  setUp(() => session = _Session());

  test(
      'TC-500 mobile replay: concurrent 401s share refresh and preserve POST key/body',
      () async {
    final gate = Completer<void>();
    final originals = Completer<void>();
    var oldRequests = 0;
    session.onRefresh = () => gate.future;
    final payloads = <Object?>[];
    final adapter = _Adapter((options) {
      payloads.add(options.data);
      if (options.headers['Authorization'] == 'Bearer test-access-old') {
        if (++oldRequests == 2) originals.complete();
        return _response(401);
      }
      return _response(200);
    });
    final network = client(adapter);
    final results = Future.wait([
      network.request<dynamic>('first',
          data: {'qty': 2}, options: Options(method: 'POST')),
      network.request<dynamic>('second'),
    ]);
    await originals.future;
    await session.started.future;
    expect(session.refreshes, 1);
    gate.complete();
    expect((await results).map((r) => r.statusCode), [200, 200]);
    expect(session.refreshes, 1);
    final writes =
        adapter.headers.where((h) => h.containsKey('Idempotency-Key'));
    expect(writes, hasLength(2));
    expect(writes.map((h) => h['Idempotency-Key']).toSet(), hasLength(1));
    expect(writes.map((h) => h['X-Request-Id']).toSet(), hasLength(1));
    expect(payloads.whereType<Map<String, dynamic>>(), [
      {'qty': 2},
      {'qty': 2}
    ]);
  });

  test('a delayed old-token 401 reuses the rotated token', () async {
    final delayed = Completer<void>();
    final received = Completer<void>();
    final adapter = _Adapter((options) async {
      if (options.headers['Authorization'] == 'Bearer test-access-old') {
        if (options.path == 'late') {
          received.complete();
          await delayed.future;
        }
        return _response(401);
      }
      return _response(200);
    });
    final network = client(adapter);
    final late = network.request<dynamic>('late');
    await received.future;
    await network.request<dynamic>('first');
    delayed.complete();
    expect((await late).statusCode, 200);
    expect(session.refreshes, 1);
  });

  test('refresh rejection fails all waiters and clears the session once',
      () async {
    final gate = Completer<void>();
    final originals = Completer<void>();
    var calls = 0;
    session.onRefresh = () async {
      await gate.future;
      throw const UnauthorizedFailure(code: 'REFRESH_REUSED');
    };
    final adapter = _Adapter((_) {
      if (++calls == 2) originals.complete();
      return _response(401);
    });
    final network = client(adapter);
    final failures = Future.wait([
      _failure(network.request<dynamic>('first')),
      _failure(network.request<dynamic>('second')),
    ]);
    await originals.future;
    await session.started.future;
    gate.complete();
    expect(await failures, everyElement(isA<UnauthorizedFailure>()));
    expect(session.refreshes, 1);
    expect(session.clears, 1);
    expect(session.token, isNull);
    expect(calls, 2);
  });

  test('a second 401 is terminal and never loops', () async {
    final adapter = _Adapter((_) => _response(401));
    final failure = await _failure(client(adapter).request<dynamic>('me'));
    expect(failure, isA<UnauthorizedFailure>());
    expect(adapter.headers, hasLength(2));
    expect(session.refreshes, 1);
    expect(session.clears, 1);
  });

  test('temporary refresh failure keeps the session and releases the lock',
      () async {
    session.onRefresh = () async => throw const TimeoutFailure();
    final adapter = _Adapter((options) => _response(
        options.headers['Authorization'] == 'Bearer test-access-new'
            ? 200
            : 401));
    final network = client(adapter);
    expect(
        await _failure(network.request<dynamic>('me')), isA<TimeoutFailure>());
    expect(session.clears, 0);
    expect(session.token, 'test-access-old');
    session.onRefresh = null;
    expect((await network.request<dynamic>('me')).statusCode, 200);
    expect(session.refreshes, 2);
  });

  test('public requests send no bearer token and never refresh', () async {
    final adapter = _Adapter((_) => _response(401));
    final failure = await _failure(client(adapter).request<dynamic>(
        'auth/refresh',
        options: Options(
            method: 'POST',
            headers: {'authorization': 'Bearer test-caller-token'},
            extra: {NetworkClient.publicRequest: true})));
    expect(failure, isA<UnauthorizedFailure>());
    expect(adapter.headers.single.containsKey('Authorization'), isFalse);
    expect(session.refreshes, 0);
  });

  test('headers use locale and preserve caller keys without case duplicates',
      () async {
    final adapter = _Adapter((_) => _response(200));
    await client(adapter, language: () => 'hi').request<dynamic>('me',
        options: Options(method: 'PATCH', headers: {
          'idempotency-key': '2c1a29e8-93ad-4cb1-b4bd-36b9327d24d4',
          'x-request-id': 'f4ab3753-f0ce-4f21-9604-62ea99214783',
          'authorization': 'Bearer test-caller-token',
        }));
    final headers = adapter.headers.single;
    expect(headers['Accept-Language'], 'hi');
    expect(headers['Authorization'], 'Bearer test-access-old');
    expect(headers['Idempotency-Key'], '2c1a29e8-93ad-4cb1-b4bd-36b9327d24d4');
    expect(headers['X-Request-Id'], 'f4ab3753-f0ce-4f21-9604-62ea99214783');
    expect(headers.containsKey('authorization'), isFalse);
    expect(headers.containsKey('idempotency-key'), isFalse);
  });

  test('every mutation gets a UUID idempotency key', () async {
    final adapter = _Adapter((_) => _response(200));
    final network = client(adapter);
    for (final method in ['POST', 'PATCH', 'PUT', 'DELETE']) {
      await network.request<dynamic>('resource',
          options: Options(method: method));
    }
    final keys = adapter.headers.map((h) => h['Idempotency-Key']);
    expect(keys.toSet(), hasLength(4));
    for (final key in keys) {
      expect(
          key,
          matches(RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    }
  });

  test('GET retries twice with backoff and a stable correlation ID', () async {
    final delays = <Duration>[];
    final adapter = _Adapter((_) => _response(503));
    final failure = await _failure(
        client(adapter, delay: (duration) async => delays.add(duration))
            .request<dynamic>('health/ready'));
    expect(failure, isA<ServerFailure>());
    expect(adapter.headers, hasLength(3));
    expect(delays,
        [const Duration(milliseconds: 250), const Duration(milliseconds: 500)]);
    expect(adapter.headers.map((h) => h['X-Request-Id']).toSet(), hasLength(1));
  });

  test('GET retries connection errors but mutations never auto retry',
      () async {
    final adapter = _Adapter((options) => throw DioException(
        requestOptions: options, type: DioExceptionType.connectionError));
    final network = client(adapter);
    expect(await _failure(network.request<dynamic>('resource')),
        isA<NetworkFailure>());
    expect(adapter.headers, hasLength(3));
    for (final method in ['POST', 'PATCH', 'PUT', 'DELETE']) {
      expect(
          await _failure(network.request<dynamic>('resource',
              options: Options(method: method))),
          isA<NetworkFailure>());
    }
    expect(adapter.headers, hasLength(7));
  });

  test('mutation 5xx is mapped once without replay', () async {
    final adapter = _Adapter((_) => _response(500));
    expect(
        await _failure(client(adapter)
            .request<dynamic>('resource', options: Options(method: 'POST'))),
        isA<ServerFailure>());
    expect(adapter.headers, hasLength(1));
  });

  test('foreign origin and paths outside API are rejected before transport',
      () async {
    final adapter = _Adapter((_) => _response(200));
    final network = client(adapter);
    for (final path in [
      'https://other.example/api/v1/me',
      '../admin',
      'https://api.supplybiz.example/api/v10/me'
    ]) {
      expect(await _failure(network.request<dynamic>(path)),
          isA<ForbiddenFailure>());
    }
    expect(adapter.headers, isEmpty);
  });

  test('cancellation during refresh does not replay the request', () async {
    final gate = Completer<void>();
    session.onRefresh = () => gate.future;
    final adapter = _Adapter((_) => _response(401));
    final token = CancelToken();
    final result =
        _failure(client(adapter).request<dynamic>('me', cancelToken: token));
    await session.started.future;
    token.cancel();
    gate.complete();
    expect(await result, isA<UnknownFailure>());
    expect(adapter.headers, hasLength(1));
  });

  test('multipart bodies are cloned for the one authenticated replay',
      () async {
    final bodies = <FormData>[];
    final adapter = _Adapter((options) {
      bodies.add(options.data as FormData);
      return _response(bodies.length == 1 ? 401 : 200);
    });
    final body = FormData.fromMap({
      'purpose': 'PRODUCT_IMAGE',
      'file': MultipartFile.fromBytes([1, 2, 3], filename: 'test-image.png'),
    });
    final result = await client(adapter).request<dynamic>('media',
        data: body, options: Options(method: 'POST'));
    expect(result.statusCode, 200);
    expect(bodies, hasLength(2));
    expect(identical(bodies[0], bodies[1]), isFalse);
    expect(bodies[1].fields, bodies[0].fields);
    expect(bodies[1].files.single.value.filename, 'test-image.png');
    expect(bodies[1].files.single.value.length, 3);
  });

  test('injected Dio exposes AppFailure and never follows redirects', () async {
    final adapter = _Adapter((options) {
      expect(options.followRedirects, isFalse);
      return _response(403, {'code': 'PLAN_FEATURE_LOCKED'});
    });
    await expectLater(
        client(adapter).dio.get<dynamic>('vendor/reports',
            options: Options(followRedirects: true)),
        throwsA(isA<DioException>()
            .having((e) => e.error, 'typed error', isA<ForbiddenFailure>())));
    expect(adapter.headers, hasLength(1));
  });
}
