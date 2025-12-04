import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class CuponesService {
  static Future<Map<String, dynamic>> getCupones({
    required int page,
    required int pageSize,
    String? apiKey,
    String? micrositioId,
    String? codigoAfiliado,
  }) async {
    try {
      // Usar valores por defecto si no se proporcionan
      final key = apiKey ?? '';
      final microId = micrositioId ?? '';
      final affiliate = codigoAfiliado ?? '';

      developer.log(
        'DEBUG CuponesService - Fetching cupones (page: $page, key: $key, microId: $microId, affiliate: $affiliate)',
      );

      final url = Uri.parse('${ApiConfig.baseUrl}/cupones')
          .replace(
            queryParameters: {
              'key': key,
              'micrositio_id': microId,
              'codigo_afiliado': affiliate,
              'page': page.toString(),
              'subcategories': 'false',
            },
          )
          .toString();

      developer.log('DEBUG CuponesService - URL: $url');

      final response = await HttpClient.get(url, includeAuth: true);

      developer.log(
        'DEBUG CuponesService - Response status: ${response.statusCode}',
      );
      developer.log('DEBUG CuponesService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as dynamic;

        developer.log(
          'DEBUG CuponesService - Decoded data type: ${data.runtimeType}',
        );

        // El backend devuelve: { count, previous, next, results: [...] }
        List<dynamic> cuponList = [];
        int total = 0;
        bool hasMore = false;

        if (data is Map) {
          // Extraer los cupones de 'results'
          cuponList = data['results'] ?? data['data'] ?? data['cupones'] ?? [];
          total = data['count'] ?? cuponList.length;
          hasMore = (data['next'] != null);

          developer.log(
            'DEBUG CuponesService - Total: $total, HasMore: $hasMore, List length: ${cuponList.length}',
          );
        }

        final cupones = cuponList
            .map((json) => Cupon.fromJson(json as Map<String, dynamic>))
            .toList();

        developer.log('DEBUG CuponesService - Got ${cupones.length} cupones');

        return {
          'cupones': cupones,
          'total': total,
          'page': page,
          'page_size': pageSize,
          'has_more': hasMore,
        };
      } else {
        developer.log('ERROR CuponesService - Status: ${response.statusCode}');
        throw Exception(
          'Error fetching cupones: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      developer.log('ERROR CuponesService - Exception: $e');
      developer.log(
        'ERROR CuponesService - Stack trace: ${StackTrace.current}',
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCuponesRecibidos({
    String? apiKey,
    String? micrositioId,
    String? codigoAfiliado,
  }) async {
    try {
      // Usar valores por defecto si no se proporcionan
      final key = apiKey ?? ApiConfig.apiKey;
      final microId = micrositioId ?? ApiConfig.micrositioId.toString();
      final affiliate = codigoAfiliado ?? ApiConfig.codigoAfiliado;

      developer.log(
        'DEBUG CuponesService - Fetching cupones recibidos (key: $key, microId: $microId, affiliate: $affiliate)',
      );

      final url = Uri.parse('${ApiConfig.baseUrl}/cupones/recibidos')
          .replace(
            queryParameters: {
              'key': key,
              'micrositio_id': microId,
              'codigo_afiliado': affiliate,
            },
          )
          .toString();

      developer.log('DEBUG CuponesService - URL: $url');

      final response = await HttpClient.get(url, includeAuth: true);

      developer.log(
        'DEBUG CuponesService - Response status: ${response.statusCode}',
      );
      developer.log('DEBUG CuponesService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as dynamic;

        developer.log(
          'DEBUG CuponesService - Decoded data type: ${data.runtimeType}',
        );

        // El backend devuelve: { count, results: [...] }
        List<dynamic> cuponList = [];
        int total = 0;

        if (data is Map) {
          // Extraer los cupones de 'results'
          cuponList = data['results'] ?? data['data'] ?? data['cupones'] ?? [];
          total = data['count'] ?? cuponList.length;

          developer.log(
            'DEBUG CuponesService - Total: $total, List length: ${cuponList.length}',
          );
        }

        final cupones = cuponList
            .map((json) => Cupon.fromJson(json as Map<String, dynamic>))
            .toList();

        developer.log(
          'DEBUG CuponesService - Got ${cupones.length} cupones recibidos',
        );

        return {'cupones': cupones, 'total': total};
      } else {
        developer.log('ERROR CuponesService - Status: ${response.statusCode}');
        throw Exception(
          'Error fetching cupones recibidos: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      developer.log('ERROR CuponesService - Exception: $e');
      developer.log(
        'ERROR CuponesService - Stack trace: ${StackTrace.current}',
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> claimCupon({
    required String cuponId,
  }) async {
    try {
      developer.log('DEBUG CuponesService - Claiming cupon (id: $cuponId)');

      final url = '${ApiConfig.baseUrl}/cupones/$cuponId/codigo';

      developer.log('DEBUG CuponesService - URL: $url');

      // Usar HttpClient que automáticamente agrega el token JWT
      final response = await HttpClient.post(
        url,
        body: {}, // Body vacío, pero el token JWT va en headers automáticamente
      );

      developer.log(
        'DEBUG CuponesService - Response status: ${response.statusCode}',
      );
      developer.log('DEBUG CuponesService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        developer.log('DEBUG CuponesService - Cupon claimed successfully');

        return {'success': true, 'data': data['success'] ?? data};
      } else {
        developer.log('ERROR CuponesService - Status: ${response.statusCode}');
        throw Exception(
          'Error claiming cupon: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      developer.log('ERROR CuponesService - Exception: $e');
      developer.log(
        'ERROR CuponesService - Stack trace: ${StackTrace.current}',
      );
      rethrow;
    }
  }
}
