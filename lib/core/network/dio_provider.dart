import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = StateNotifierProvider<DioNotifier, DioState>((ref) {
  return DioNotifier();
});

final dioInstanceProvider = Provider<Dio>((ref) {
  return ref.watch(dioProvider.notifier).dio;
});

class DioState {
  final Dio dio;
  final String baseUrl;
  final Duration timeout;

  const DioState({
    required this.dio,
    required this.baseUrl,
    required this.timeout,
  });
}

class DioNotifier extends StateNotifier<DioState> {
  DioNotifier() : super(_createInitialState()) {
    _configureDio();
  }

  static DioState _createInitialState() {
    final dio = Dio();
    return DioState(
      dio: dio,
      baseUrl: 'https://api.example.com', // Replace with actual API URL
      timeout: const Duration(seconds: 30),
    );
  }

  void _configureDio() {
    state.dio.options = BaseOptions(
      baseUrl: state.baseUrl,
      connectTimeout: state.timeout,
      receiveTimeout: state.timeout,
      sendTimeout: state.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
    );

    state.dio.interceptors.clear();
    state.dio.interceptors.addAll([
      _LoggingInterceptor(),
      _ErrorInterceptor(),
      _RetryInterceptor(),
    ]);
  }

  void updateBaseUrl(String newBaseUrl) {
    state = DioState(
      dio: state.dio,
      baseUrl: newBaseUrl,
      timeout: state.timeout,
    );
    state.dio.options.baseUrl = newBaseUrl;
  }

  void updateTimeout(Duration newTimeout) {
    state = DioState(
      dio: state.dio,
      baseUrl: state.baseUrl,
      timeout: newTimeout,
    );
    state.dio.options.connectTimeout = newTimeout;
    state.dio.options.receiveTimeout = newTimeout;
    state.dio.options.sendTimeout = newTimeout;
  }

  void updateHeaders(Map<String, String> headers) {
    state.dio.options.headers.addAll(headers);
  }

  Dio get dio => state.dio;

  @override
  void dispose() {
    state.dio.close();
    super.dispose();
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🚀 REQUEST: ${options.method} ${options.uri}');
    print('📤 Headers: ${options.headers}');
    if (options.data != null) {
      print('📤 Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
    print('📥 Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ ERROR: ${err.message}');
    print('🔗 URL: ${err.requestOptions.uri}');
    if (err.response != null) {
      print('📥 Error Response: ${err.response?.data}');
    }
    handler.next(err);
  }
}

/// Error Interceptor for consistent error handling
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    DioException customErr;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        customErr = DioException(
          requestOptions: err.requestOptions,
          error: 'Connection timeout. Please check your internet connection.',
          type: err.type,
        );
        break;

      case DioExceptionType.connectionError:
        customErr = DioException(
          requestOptions: err.requestOptions,
          error: 'No internet connection. Please check your network settings.',
          type: err.type,
        );
        break;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        String message;

        switch (statusCode) {
          case 400:
            message = 'Bad request. Please check your input.';
            break;
          case 401:
            message = 'Unauthorized. Please login again.';
            break;
          case 403:
            message = 'Access forbidden. You don\'t have permission.';
            break;
          case 404:
            message = 'Resource not found.';
            break;
          case 429:
            message = 'Too many requests. Please try again later.';
            break;
          case 500:
            message = 'Server error. Please try again later.';
            break;
          case 502:
          case 503:
          case 504:
            message = 'Service unavailable. Please try again later.';
            break;
          default:
            message = 'Something went wrong. Please try again.';
        }

        customErr = DioException(
          requestOptions: err.requestOptions,
          error: message,
          response: err.response,
          type: err.type,
        );
        break;

      default:
        customErr = err;
    }

    handler.next(customErr);
  }
}

/// Retry Interceptor for automatic retry on failures
class _RetryInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] ?? 0;

    // Only retry on network errors and server errors (5xx)
    final shouldRetry = (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            (err.response?.statusCode != null &&
                err.response!.statusCode! >= 500)) &&
        retryCount < maxRetries;

    if (shouldRetry) {
      print(
          '🔄 Retrying request (${retryCount + 1}/$maxRetries): ${err.requestOptions.uri}');

      // Wait before retry
      await Future.delayed(retryDelay * (retryCount + 1));

      // Update retry count
      err.requestOptions.extra['retryCount'] = retryCount + 1;

      try {
        // Create a new Dio instance for retry to avoid infinite loops
        final retryDio = Dio();
        retryDio.options = err.requestOptions.copyWith() as BaseOptions;
        final response = await retryDio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Continue with original error if retry fails
      }
    }

    handler.next(err);
  }
}
