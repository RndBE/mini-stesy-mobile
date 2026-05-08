import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

/// HTTP client terpusat dengan otomatis menyertakan Bearer token di setiap request.
class ApiClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // ── Interceptor: auto-inject Bearer token ──────────────────────────────
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // 401 → token expired, perlu logout
          if (e.response?.statusCode == 401) {
            SecureStorage.clearAll();
          }
          return handler.next(e);
        },
      ),
    );

    // ── Interceptor: Smart Retry (Jaringan Putus-Nyambung) ──────────────────
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        logPrint: print, // Print log ke console saat retry terjadi
        retries: 3, // Maksimal coba lagi 3 kali
        retryDelays: const [
          Duration(seconds: 1), // Tunggu 1 detik sebelum coba ke-1
          Duration(seconds: 2), // Tunggu 2 detik sebelum coba ke-2
          Duration(seconds: 3), // Tunggu 3 detik sebelum coba ke-3
        ],
        retryEvaluator: (error, attempt) {
          // Hanya retry jika errornya adalah masalah jaringan/timeout, bukan karena masalah dari server (spt 404, 401)
          final isNetworkError = error.type == DioExceptionType.connectionTimeout ||
                                 error.type == DioExceptionType.sendTimeout ||
                                 error.type == DioExceptionType.receiveTimeout ||
                                 error.type == DioExceptionType.connectionError ||
                                 error.type == DioExceptionType.unknown;
          return isNetworkError;
        },
      ),
    );

    // ── Logger (debug) ──────────────────────────────────────────────────────
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[API] $obj'),
      ),
    );

    return dio;
  }

  /// Reset instance (misal setelah logout)
  static void reset() => _instance = null;
}
