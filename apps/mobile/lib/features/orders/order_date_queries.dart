import 'package:dio/dio.dart';

/// Generated clients pass DateTime query values for OpenAPI calendar dates.
/// Adapt only these date filters, preserving the selected day without converting
/// it through UTC. Mutation timestamps and unrelated requests are untouched.
void configureOrderDateQueries(Dio dio) {
  if (!dio.interceptors.any((i) => i is _OrderDateQueryInterceptor)) {
    dio.interceptors.add(_OrderDateQueryInterceptor());
  }
}

class _OrderDateQueryInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'GET' &&
        {'/api/v1/vendor/orders', '/api/v1/vendor/deliveries'}
            .contains(options.uri.path)) {
      final date = options.queryParameters['date'];
      if (date is DateTime) {
        options.queryParameters = {
          ...options.queryParameters,
          'date': date.toIso8601String().substring(0, 10),
        };
      }
    }
    handler.next(options);
  }
}
