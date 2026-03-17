import 'dart:convert';
import 'dart:developer';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:boombet_app/services/http_client.dart';

class EventosService {
  Future<EventoModel> createEvento({
    required String nombre,
    required DateTime fechaFin,
  }) async {
    final url = '${ApiConfig.baseUrl}/eventos';
    final body = <String, dynamic>{
      'nombre': nombre.trim(),
      'activo': true,
      'fechaFin': fechaFin.toUtc().toIso8601String(),
    };

    final response = await HttpClient.post(url, includeAuth: true, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return EventoModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<EventoModel> toggleEventoActivo({required int id}) async {
    final url = '${ApiConfig.baseUrl}/eventos/$id';

    final response = await HttpClient.patch(url, includeAuth: true);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return EventoModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<void> deleteEvento({required int id}) async {
    final url = '${ApiConfig.baseUrl}/eventos/$id';

    final response = await HttpClient.delete(url, includeAuth: true);

    if (response.statusCode == 200 || response.statusCode == 204) return;

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<List<EventoModel>> fetchEventos() async {
    final url = '${ApiConfig.baseUrl}/eventos';

    final response = await HttpClient.get(
      url,
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      List<dynamic>? rawList;

      if (data is List) {
        rawList = data;
      } else if (data is Map) {
        final raw = data['content'];
        if (raw is List) rawList = raw;
      }

      if (rawList == null) {
        throw Exception('Formato inesperado de respuesta');
      }

      final result = <EventoModel>[];
      for (final item in rawList) {
        if (item is Map) {
          result.add(EventoModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return result;
    }

    log('[EventosService] fetchEventos error ${response.statusCode}: ${response.body}');
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<int> fetchEventoTotalAfiliaciones({required int id}) async {
    final url = '${ApiConfig.baseUrl}/eventos/$id/afiliaciones';

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
}
