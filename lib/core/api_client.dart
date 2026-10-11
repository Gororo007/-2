import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../state/auth_notifier.dart';
import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({AuthNotifier? authNotifier}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = authNotifier?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;

        // ПУНКТ 12 методички: Автоматический refresh токена при 401
        // Условие !path.contains('/auth/') защищает от бесконечного цикла!
        if (status == 401 && !path.contains('/auth/') && authNotifier != null) {
          try {
            await authNotifier.refreshTokens();
            final options = error.requestOptions;
            options.headers['Authorization'] =
                'Bearer ${authNotifier.accessToken}';
            final response = await dio.fetch(options);
            return handler.resolve(response);
          } catch (_) {
            await authNotifier.logout();
          }
        }

        if (kDebugMode) {
          debugPrint('[API] Сбой ${error.requestOptions.uri}: ${error.type}');
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}
