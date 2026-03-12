import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/stand_model.dart';
import 'package:boombet_app/models/stand_prize_model.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/utils/error_parser.dart';
import 'package:http/http.dart' as http;

class StandsService {
  Future<List<StandModel>> fetchStands() async {
    final url = '${ApiConfig.baseUrl}/stands';

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
            .map(StandModel.fromJson)
            .toList();
      }
      throw Exception('Formato inesperado de respuesta');
    }

    log(
      '[StandsService] fetchStands error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }

  Future<StandCreationResult> createStand({
    required String nombre,
    required String username,
    required String password,
    required String email,
  }) async {
    final url = '${ApiConfig.baseUrl}/stands';
    final body = <String, dynamic>{
      'nombre': nombre.trim(),
      'username': username.trim(),
      'password': password,
      'email': email.trim(),
    };

    final response = await HttpClient.post(url, includeAuth: true, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return StandCreationResult.fromJson(data);
      }
      throw Exception('Formato inesperado de respuesta');
    }

    log(
      '[StandsService] createStand error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }

  Future<StandModel> updateStand({
    required int id,
    required String nombre,
  }) async {
    final url = '${ApiConfig.baseUrl}/stands/$id';
    final body = <String, dynamic>{'nombre': nombre.trim()};

    final response = await HttpClient.patch(url, includeAuth: true, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return StandModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    log(
      '[StandsService] updateStand error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }

  Future<StandModel> toggleStandActivo({
    required int id,
    required bool activo,
  }) async {
    final url = '${ApiConfig.baseUrl}/stands/$id';
    final body = <String, dynamic>{'activo': activo};

    final response = await HttpClient.patch(url, includeAuth: true, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return StandModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    log(
      '[StandsService] toggleStandActivo error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }

  Future<void> deleteStand({required int id}) async {
    final url = '${ApiConfig.baseUrl}/stands/$id';

    final response = await HttpClient.delete(url, includeAuth: true);

    if (response.statusCode == 200 || response.statusCode == 204) return;

    log(
      '[StandsService] deleteStand error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }

  Future<StandPrizeModel> createStandPrize({
    required String nombre,
    required int stock,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final url = '${ApiConfig.baseUrl}/stands/mi-stand/premios';

    if (imageBytes == null) {
      // No file → plain JSON, avoids Dart's multipart charset=UTF-8 issue
      final response = await HttpClient.post(
        url,
        includeAuth: true,
        body: {'nombre': nombre.trim(), 'stock': stock},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return StandPrizeModel.fromJson(data);
        throw Exception('Formato inesperado de respuesta');
      }
      log(
        '[StandsService] createStandPrize error ${response.statusCode}: ${response.body}',
      );
      throw Exception(ErrorParser.parseResponse(response));
    }

    // Has file → multipart
    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token no encontrado. Iniciá sesión nuevamente.');
    }

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['nombre'] = nombre.trim();
    request.fields['stock'] = stock.toString();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: imageName ?? 'premio.jpg',
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) return StandPrizeModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    log('[StandsService] createStandPrize error ${streamed.statusCode}: $body');
    throw Exception('Error ${streamed.statusCode}: $body');
  }

  Future<StandPrizeModel> updateStandPrize({
    required int premioId,
    String? nombre,
    int? stock,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final url = '${ApiConfig.baseUrl}/stands/mi-stand/premios/$premioId';

    if (imageBytes == null) {
      // No file → plain JSON, avoids Dart's multipart charset=UTF-8 issue
      final jsonBody = <String, dynamic>{};
      if (nombre != null) jsonBody['nombre'] = nombre.trim();
      if (stock != null) jsonBody['stock'] = stock;
      final response = await HttpClient.patch(
        url,
        includeAuth: true,
        body: jsonBody,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return StandPrizeModel.fromJson(data);
        throw Exception('Formato inesperado de respuesta');
      }
      log(
        '[StandsService] updateStandPrize error ${response.statusCode}: ${response.body}',
      );
      throw Exception(ErrorParser.parseResponse(response));
    }

    // Has file → multipart
    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token no encontrado. Iniciá sesión nuevamente.');
    }

    final request = http.MultipartRequest('PATCH', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    if (nombre != null) request.fields['nombre'] = nombre.trim();
    if (stock != null) request.fields['stock'] = stock.toString();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: imageName ?? 'premio.jpg',
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) return StandPrizeModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    log('[StandsService] updateStandPrize error ${streamed.statusCode}: $body');
    throw Exception('Error ${streamed.statusCode}: $body');
  }

  Future<void> deleteStandPrize({required int premioId}) async {
    final url = '${ApiConfig.baseUrl}/stands/mi-stand/premios/$premioId';
    final response = await HttpClient.delete(url, includeAuth: true);
    if (response.statusCode == 200 || response.statusCode == 204) return;
    log(
      '[StandsService] deleteStandPrize error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }

  Future<List<StandPrizeModel>> fetchStandPrizes() async {
    final url = '${ApiConfig.baseUrl}/stands/mi-stand/premios';

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
            .map(StandPrizeModel.fromJson)
            .toList();
      }
      throw Exception('Formato inesperado de respuesta');
    }

    log(
      '[StandsService] fetchStandPrizes error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }

  Future<List<TidModel>> fetchStandRoulettes() async {
    final url = '${ApiConfig.baseUrl}/stands/mi-stand/ruletas';

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
      '[StandsService] fetchStandRoulettes error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }
}

class StandCreationResult {
  final StandModel stand;
  final String username;
  final String password;

  const StandCreationResult({
    required this.stand,
    required this.username,
    required this.password,
  });

  factory StandCreationResult.fromJson(Map<String, dynamic> json) {
    return StandCreationResult(
      stand: StandModel.fromJson(json['stand'] as Map<String, dynamic>),
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
    );
  }
}
