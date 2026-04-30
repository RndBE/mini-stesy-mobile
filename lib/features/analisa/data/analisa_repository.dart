import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AnalisaRepository {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getAnalisaData(String idLogger, {
    required String from,
    required String to,
    String? parameter,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.analisaData(idLogger),
        queryParameters: {
          'from': from,
          'to': to,
          if (parameter != null) 'parameter': parameter,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
