import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/formulario_model.dart';
import 'package:boombet_app/services/http_client.dart';

class FormulariosService {
  Future<List<FormularioModel>> fetchFormularios({
    int page = 0,
    int size = 50,
  }) async {
    final response = await HttpClient.get(
      '${ApiConfig.baseUrl}/formularios?page=$page&size=$size',
      includeAuth: true,
      cacheTtl: Duration.zero,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    List<dynamic> content = const [];
    if (decoded is Map<String, dynamic>) {
      final c = decoded['content'];
      if (c is List) content = c;
    } else if (decoded is List) {
      content = decoded;
    }
    return content
        .whereType<Map>()
        .map((m) => FormularioModel.fromMap(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  Future<FormularioModel> createFormulario({
    String? contrasena,
    int? tidId,
    int? sorteoId,
  }) async {
    final body = <String, dynamic>{};
    if (contrasena != null && contrasena.isNotEmpty) {
      body['contrasena'] = contrasena;
    }
    if (tidId != null) body['tidId'] = tidId;
    if (sorteoId != null) body['sorteoId'] = sorteoId;

    final response = await HttpClient.post(
      '${ApiConfig.baseUrl}/formularios',
      body: body,
      includeAuth: true,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    return FormularioModel.fromMap(Map<String, dynamic>.from(decoded));
  }

  Future<void> deleteFormulario(int id) async {
    final response = await HttpClient.delete(
      '${ApiConfig.baseUrl}/formularios/$id',
      includeAuth: true,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error ${response.statusCode}');
    }
  }
}
