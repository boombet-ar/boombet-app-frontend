import 'dart:convert';
import 'dart:developer';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/sub_afiliado_model.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/utils/error_parser.dart';

class SubAfiliadosService {
  static const _base = 'afiliadores/mis-subafiliadores';

  Future<List<SubAfiliadoModel>> fetchSubAfiliados() async {
    final url = '${ApiConfig.baseUrl}/$_base';

    final response = await HttpClient.get(
      url,
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(SubAfiliadoModel.fromJson)
            .toList();
      }
      throw Exception('Formato inesperado de respuesta');
    }

    log(
      '[SubAfiliadosService] fetchSubAfiliados error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }

  Future<int> fetchTotalJugadores(int id) async {
    final url = '${ApiConfig.baseUrl}/$_base/$id';

    final response = await HttpClient.get(
      url,
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return (data['totalJugadores'] as num?)?.toInt() ?? 0;
      }
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<SubAfiliadoModel> createSubAfiliado({
    required String username,
    required String password,
    required String role,
    required String dni,
    required String email,
    required String telefono,
  }) async {
    final url = '${ApiConfig.baseUrl}/$_base';
    final body = {
      'username': username.trim(),
      'password': password,
      'role': role.trim(),
      'dni': dni.trim(),
      'email': email.trim(),
      'telefono': telefono.trim(),
    };

    final response = await HttpClient.post(url, includeAuth: true, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return SubAfiliadoModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    log(
      '[SubAfiliadosService] createSubAfiliado error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }

  Future<SubAfiliadoModel> toggleActivo(int id) async {
    final url = '${ApiConfig.baseUrl}/$_base/$id/activo';

    final response = await HttpClient.patch(url, includeAuth: true, body: {});

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return SubAfiliadoModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<void> deleteSubAfiliado(int id) async {
    final url = '${ApiConfig.baseUrl}/$_base/$id';

    final response = await HttpClient.delete(url, includeAuth: true);

    if (response.statusCode == 200 || response.statusCode == 204) return;

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }
}
