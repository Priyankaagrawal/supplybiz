import 'dart:async';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'app_failure.dart';

/// T-015 owns token storage/rotation and logout lifecycle. Never log tokens.
abstract interface class NetworkSession {
  String? get accessToken;

  /// Rotate tokens and persist them before completing; throw on failure.
  /// Use a public request (or separate transport) to avoid recursive refresh.
  Future<void> refresh();
  Future<void> clear();
}

class NetworkClient {
  NetworkClient({
    required String baseUrl,
    required NetworkSession session,
    String Function()? language,
    HttpClientAdapter? adapter,
    Future<void> Function(Duration)? delay,
  }) : dio = Dio(BaseOptions(
          baseUrl: '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/',
          connectTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          followRedirects: false,
          headers: {'Accept': 'application/json'},
        )) {
    final base = Uri.parse(dio.options.baseUrl);
    if (!{'http', 'https'}.contains(base.scheme) ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw ArgumentError('An absolute HTTP(S) API base URL is required.');
    }
    if (adapter != null) dio.httpClientAdapter = adapter;
    dio.interceptors.add(_NetworkInterceptor(dio, base, session,
        language ?? () => 'en', delay ?? Future<void>.delayed));
  }

  /// Pass this instance to generated clients. Their DioException.error contains
  /// an AppFailure; use [mapDioFailure] at the repository boundary.
  final Dio dio;

  /// Set this extra option for unauthenticated OTP/refresh/public endpoints.
  static const publicRequest = 'network.public';

  Future<Response<T>> request<T>(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) async {
    try {
      return await dio.request<T>(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  void close() => dio.close(force: true);
}

class _NetworkInterceptor extends Interceptor {
  _NetworkInterceptor(
      this.dio, this.base, this.session, this.language, this.delay);
  final Dio dio;
  final Uri base;
  final NetworkSession session;
  final String Function() language;
  final Future<void> Function(Duration) delay;
  Future<void>? _refreshing;
  static const _authRetried = 'network.authRetried';
  static const _getRetries = 'network.getRetries';
  static const _sentToken = 'network.sentToken';
  static const _uuid = Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri;
    if (uri.origin != base.origin ||
        !uri.path.startsWith(base.path) ||
        uri.userInfo.isNotEmpty) {
      handler.reject(_withFailure(
          options, const ForbiddenFailure(code: 'INVALID_API_ORIGIN')));
      return;
    }
    options.followRedirects = false;
    // Normalize caller headers so mixed-case names cannot produce duplicates.
    _setHeader(options, 'X-Request-Id',
        _header(options, 'X-Request-Id') ?? _uuid.v4());
    if ({'POST', 'PATCH', 'PUT', 'DELETE'}
        .contains(options.method.toUpperCase())) {
      _setHeader(options, 'Idempotency-Key',
          _header(options, 'Idempotency-Key') ?? _uuid.v4());
    }
    final locale = language();
    _setHeader(options, 'Accept-Language', locale == 'hi' ? 'hi' : 'en');
    options.headers
        .removeWhere((key, _) => key.toLowerCase() == 'authorization');
    final token = options.extra[NetworkClient.publicRequest] == true
        ? null
        : session.accessToken;
    options.extra[_sentToken] = token;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    final options = error.requestOptions;
    try {
      final authenticated = options.extra[NetworkClient.publicRequest] != true;
      if (error.response?.statusCode == 401 && authenticated) {
        if (options.extra[_authRetried] == true || options.data is Stream) {
          if (session.accessToken == options.extra[_sentToken]) {
            await session.clear();
          }
          handler.next(_mapped(error));
          return;
        }
        final sentToken = options.extra[_sentToken];
        if (session.accessToken == null && sentToken != null) {
          throw const UnauthorizedFailure();
        }
        // A delayed 401 for an old token reuses the already-refreshed token.
        if (session.accessToken == sentToken) await _refresh();
        options.extra[_authRetried] = true;
        _checkCancelled(options);
        handler.resolve(await _replay(options));
        return;
      }
      final retries = options.extra[_getRetries] as int? ?? 0;
      if (options.method.toUpperCase() == 'GET' &&
          retries < 2 &&
          (error.type == DioExceptionType.connectionError ||
              (error.response?.statusCode ?? 0) >= 500)) {
        options.extra[_getRetries] = retries + 1;
        await delay(Duration(milliseconds: 250 * (1 << retries)));
        _checkCancelled(options);
        handler.resolve(await _replay(options));
        return;
      }
      handler.next(_mapped(error));
    } on DioException catch (failure) {
      handler.reject(_mapped(failure));
    } on AppFailure catch (failure) {
      handler.reject(_withFailure(options, failure));
    } catch (_) {
      handler.reject(_withFailure(options, const UnknownFailure()));
    }
  }

  Future<void> _refresh() async {
    final flight = _refreshing ??= _rotate();
    try {
      await flight;
    } finally {
      if (identical(_refreshing, flight)) _refreshing = null;
    }
  }

  Future<void> _rotate() async {
    try {
      await session.refresh();
      if (session.accessToken == null) throw const UnauthorizedFailure();
    } catch (error) {
      final failure = error is DioException
          ? mapDioFailure(error)
          : error is AppFailure
              ? error
              : const UnknownFailure();
      if (failure is UnauthorizedFailure) await session.clear();
      throw failure;
    }
  }

  Future<Response<dynamic>> _replay(RequestOptions options) {
    final data = options.data;
    return dio.fetch<dynamic>(
        options.copyWith(data: data is FormData ? data.clone() : data));
  }

  void _checkCancelled(RequestOptions options) {
    final cancelled = options.cancelToken?.cancelError;
    if (cancelled != null) throw cancelled;
  }

  String? _header(RequestOptions options, String name) {
    for (final entry in options.headers.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) {
        return entry.value?.toString();
      }
    }
    return null;
  }

  void _setHeader(RequestOptions options, String name, String value) {
    options.headers
        .removeWhere((key, _) => key.toLowerCase() == name.toLowerCase());
    options.headers[name] = value;
  }

  DioException _mapped(DioException error) =>
      error.copyWith(error: mapDioFailure(error), message: 'Request failed.');
  DioException _withFailure(RequestOptions options, AppFailure failure) =>
      DioException(
          requestOptions: options, error: failure, message: 'Request failed.');
}
