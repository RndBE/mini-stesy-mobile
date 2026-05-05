import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class BerandaRepository {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>?> getCachedBerandaInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString('beranda_info_cache');
      if (cachedData != null) {
        return jsonDecode(cachedData) as Map<String, dynamic>;
      }
    } catch (e) {
      // Ignore cache parsing error
    }
    return null;
  }

  /// Mengambil info beranda (termasuk data instansi)
  Future<Map<String, dynamic>> getBerandaInfo() async {
    try {
      final response = await _dio.get(ApiEndpoints.berandaInfo);
      final data = response.data['data'] as Map<String, dynamic>;
      
      // Simpan ke cache agar load berikutnya instan
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('beranda_info_cache', jsonEncode(data));
      
      return data;
    } catch (e) {
      rethrow;
    }
  }
}
