import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class PetaRepository {
  final Dio _dio = ApiClient.instance;

  /// Mengambil data titik koordinat logger (Pos) untuk peta
  Future<List<dynamic>> getPetaPoints() async {
    try {
      final response = await _dio.get(ApiEndpoints.petaPoints);
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
