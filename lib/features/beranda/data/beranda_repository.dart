import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class BerandaRepository {
  final Dio _dio = ApiClient.instance;

  /// Mengambil info beranda (termasuk data instansi)
  Future<Map<String, dynamic>> getBerandaInfo() async {
    try {
      final response = await _dio.get(ApiEndpoints.berandaInfo);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
