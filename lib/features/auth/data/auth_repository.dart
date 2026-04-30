import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  /// Login dengan username + password.
  /// Menyimpan token dan info user ke secure storage.
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'username': username, 'password': password},
    );

    final data = response.data['data'];
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await SecureStorage.saveToken(token);
    await SecureStorage.saveUser(
      idUser:    user.idUser,
      nama:      user.nama,
      username:  user.username,
      levelUser: user.levelUser,
    );

    return user;
  }

  /// Logout dan hapus semua data lokal.
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Tetap clear storage walaupun request gagal
    } finally {
      await SecureStorage.clearAll();
      ApiClient.reset();
    }
  }

  /// Cek apakah user sudah login (ada token tersimpan).
  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Ambil info user dari storage lokal.
  Future<UserModel?> getCurrentUser() async {
    final data = await SecureStorage.getUser();
    if (data['id_user'] == null) return null;
    return UserModel(
      idUser:    data['id_user']!,
      nama:      data['nama'] ?? '',
      username:  data['username'] ?? '',
      levelUser: data['level_user'] ?? '',
    );
  }
}
