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
      int page = 1;
      int lastPage = 1;
      List<dynamic> allData = [];
      List<dynamic>? paramsData;

      // Ambil halaman pertama untuk mendapatkan total last_page
      final initialResponse = await _dio.get(
        ApiEndpoints.analisaData(idLogger),
        queryParameters: {
          'from': from,
          'to': to,
          'parameter': ?parameter,
          'per_page': 1000,
          'page': 1,
        },
      );

      final responseData = initialResponse.data;
      if (responseData['success'] != true) {
        return responseData;
      }

      allData.addAll(responseData['data'] ?? []);
      paramsData = responseData['params'];

      final meta = responseData['meta'];
      if (meta != null) {
        lastPage = meta['last_page'] ?? 1;
      }

      // Jika ada lebih dari 1 halaman, lakukan fetch secara pararel (concurrent) dengan chunking (max 10 request bersamaan)
      if (lastPage > 1) {
        final chunkSize = 10;
        for (int start = 2; start <= lastPage; start += chunkSize) {
          int end = start + chunkSize - 1;
          if (end > lastPage) end = lastPage;
          
          List<Future<Response>> requests = [];
          for (int p = start; p <= end; p++) {
            requests.add(_dio.get(
              ApiEndpoints.analisaData(idLogger),
              queryParameters: {
                'from': from,
                'to': to,
                'parameter': ?parameter,
                'per_page': 1000,
                'page': p,
              },
            ));
          }

          final responses = await Future.wait(requests);
          for (var resp in responses) {
            final resData = resp.data;
            if (resData['success'] == true) {
              allData.addAll(resData['data'] ?? []);
            }
          }
        }
      }

      return {
        'success': true,
        'data': allData,
        'params': paramsData,
      };
    } catch (e) {
      rethrow;
    }
  }
}
