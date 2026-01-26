import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/afiliador_model.dart';
import 'package:boombet_app/services/http_client.dart';

class AfiliadoresService {
  Future<AfiliadoresPage> fetchAfiliadores({
    int page = 0,
    int size = 10,
    String sort = 'id,desc',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/afiliadores').replace(
      queryParameters: {'page': '$page', 'size': '$size', 'sort': sort},
    );

    final response = await HttpClient.get(
      uri.toString(),
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return AfiliadoresPage.fromJson(data);
      }
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<AfiliadorModel> createAfiliador({
    required String nombre,
    required String email,
    required String dni,
    required String telefono,
  }) async {
    final url = '${ApiConfig.baseUrl}/afiliadores';

    final response = await HttpClient.post(
      url,
      includeAuth: true,
      body: {
        'nombre': nombre,
        'email': email,
        'dni': dni,
        'telefono': telefono,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return AfiliadorModel.fromJson(data);
      }
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<AfiliadorModel> toggleAfiliadorActivo({required int id}) async {
    final url = '${ApiConfig.baseUrl}/afiliadores/$id/activo';

    final response = await HttpClient.patch(url, includeAuth: true);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return AfiliadorModel.fromJson(data);
      }
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }
}
