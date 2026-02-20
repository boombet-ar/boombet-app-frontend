import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/afiliador_model.dart';
import 'package:boombet_app/services/http_client.dart';

class AfiliadoresService {
  Future<List<String>> fetchAfiliadorTipos() async {
    final url = '${ApiConfig.baseUrl}/afiliadores/tipos';
    final response = await HttpClient.get(
      url,
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }
      if (data is Map<String, dynamic>) {
        final list = data['data'] ?? data['tipos'] ?? data['types'];
        if (list is List) {
          return list.map((e) => e.toString()).toList();
        }
      }
      return [];
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

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

  Future<void> createAfiliador({
    required String nombre,
    required String tipoAfiliador,
    String? email,
    String? dni,
    String? telefono,
    String? tokenAfiliador,
  }) async {
    final url = '${ApiConfig.baseUrl}/afiliadores';
    final body = <String, dynamic>{
      'nombre': nombre.trim(),
      'email': email,
      'dni': dni,
      'telefono': telefono,
      'token_afiliador': tokenAfiliador,
      'tipo_afiliador': tipoAfiliador,
    };

    final response = await HttpClient.post(url, includeAuth: true, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
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

  Future<void> deleteAfiliador({required int id}) async {
    final url = '${ApiConfig.baseUrl}/afiliadores/$id';

    final response = await HttpClient.delete(url, includeAuth: true);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }
}
