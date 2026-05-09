import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

/// HTTP client terpusat dengan otomatis menyertakan Bearer token di setiap request.
class ApiClient {
  static Dio? _instance;
  static bool _isShowingSuspendDialog = false;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
        connectTimeout: const Duration(seconds: 5), // Turunkan dari 15s agar cepat terdeteksi offline
        receiveTimeout: const Duration(seconds: 10), // Turunkan dari 30s
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // ── Interceptor: Proactive Connectivity Check ────────────────────────────
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Cek DNS super cepat (timeout 1.5 detik), kalau gagal langsung throw error
            // tanpa harus nunggu connectTimeout 5 detik.
            final result = await InternetAddress.lookup('google.com').timeout(const Duration(milliseconds: 1500));
            if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
              return handler.next(options);
            }
          } catch (_) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: 'No Internet Connection',
              ),
            );
          }
          return handler.next(options);
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
          final ctx = navigatorKey.currentContext;

          // 401 → token expired, perlu logout normal
          if (e.response?.statusCode == 401) {
            SecureStorage.clearAll();
            if (ctx != null && !_isShowingSuspendDialog) {
              Navigator.of(ctx).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          }

          // 403 → suspended / non-aktif
          if (e.response?.statusCode == 403) {
            final data = e.response?.data;
            if (data is Map && data.containsKey('message')) {
              final String rawMsg = data['message'].toString();
              final String msgLower = rawMsg.toLowerCase();
              
              if (msgLower.contains('suspend') || msgLower.contains('non-aktif') || msgLower.contains('ditangguhkan')) {
                SecureStorage.clearAll();
                
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setString('pending_suspend_message', rawMsg);
                  if (ctx != null) {
                    Navigator.of(ctx).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                });
              }
            }
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
          // Hanya berlaku untuk endpoint LOGIN
          if (!error.requestOptions.path.contains('/auth/login')) {
            return false;
          }

          // Hanya retry jika errornya adalah masalah jaringan/timeout, bukan masalah server (spt 404, 401)
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
