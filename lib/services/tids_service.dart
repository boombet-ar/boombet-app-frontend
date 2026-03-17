import 'dart:convert';
import 'dart:developer';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/utils/error_parser.dart';

class TidsService {
  Future<List<TidModel>> fetchTids() async {
    final url = '${ApiConfig.baseUrl}/tid';

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
            .map(TidModel.fromJson)
            .toList();
      }
      throw Exception('Formato inesperado de respuesta');
    }

    log(
      '[TidsService] fetchTids error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }

  Future<TidModel> fetchTidById({required int id}) async {
    final url = '${ApiConfig.baseUrl}/tid/$id';

    final response = await HttpClient.get(
      url,
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return TidModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<TidModel> createTid({
    required String tid,
    int? idEvento,
    int? idStand,
  }) async {
    final url = '${ApiConfig.baseUrl}/tid';
    final body = <String, dynamic>{'tid': tid.trim()};
    if (idEvento != null) body['idEvento'] = idEvento;
    if (idStand != null) body['idStand'] = idStand;

    final response = await HttpClient.post(url, includeAuth: true, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return TidModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<TidModel> updateTid({
    required int id,
    required String tid,
    int? idEvento,
    int? idStand,
    bool sendIdStand = false,
  }) async {
    final url = '${ApiConfig.baseUrl}/tid/$id';
    final body = <String, dynamic>{'tid': tid.trim()};
    if (idEvento != null) body['idEvento'] = idEvento;
    if (sendIdStand) body['idStand'] = idStand;

    final response = await HttpClient.patch(url, includeAuth: true, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return TidModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<TidModel> removeTidFromEvento({
    required int id,
    required String tidCode,
  }) async {
    final url = '${ApiConfig.baseUrl}/tid/$id';
    final body = <String, dynamic>{'tid': tidCode.trim(), 'idEvento': null};

    final response = await HttpClient.patch(url, includeAuth: true, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return TidModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<void> deleteTid({required int id}) async {
    final url = '${ApiConfig.baseUrl}/tid/$id';

    final response = await HttpClient.delete(url, includeAuth: true);

    if (response.statusCode == 200 || response.statusCode == 204) return;

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<int> fetchTidTotalJugadores({required int id}) async {
    final url = '${ApiConfig.baseUrl}/tid/$id/afiliaciones';

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
