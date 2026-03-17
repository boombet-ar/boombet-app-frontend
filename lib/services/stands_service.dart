import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/stand_model.dart';
import 'package:boombet_app/models/prize_canje_model.dart';
import 'package:boombet_app/models/stand_prize_model.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/utils/error_parser.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class StandsService {
  Future<StandModel?> fetchStandById(int id) async {
    final url = '${ApiConfig.baseUrl}/stands/$id';
    try {
      final response = await HttpClient.get(
        url,
        includeAuth: true,
        expireSessionOnAuthFailure: false,
        cacheTtl: const Duration(minutes: 5),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return StandModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

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
    String imageMimeType = 'image/jpeg',
  }) async {
    final url = '${ApiConfig.baseUrl}/stands/mi-stand/premios';
    final request = await _buildMultipartRequest('POST', url);

    request.files.add(
      http.MultipartFile.fromString(
        'datos',
        jsonEncode({'nombre': nombre.trim(), 'stock': stock}),
        filename: 'datos.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          imageBytes,
          filename: imageName ?? 'premio.jpg',
          contentType: MediaType.parse(imageMimeType),
        ),
      );
    }

    return _sendAndParsePrize(request, 'createStandPrize');
  }

  Future<StandPrizeModel> updateStandPrize({
    required int premioId,
    String? nombre,
    int? stock,
    Uint8List? imageBytes,
    String? imageName,
    String imageMimeType = 'image/jpeg',
  }) async {
    final url = '${ApiConfig.baseUrl}/stands/mi-stand/premios/$premioId';
    final request = await _buildMultipartRequest('PATCH', url);

    final datosMap = <String, dynamic>{};
    if (nombre != null) datosMap['nombre'] = nombre.trim();
    if (stock != null) datosMap['stock'] = stock;
    request.files.add(
      http.MultipartFile.fromString(
        'datos',
        jsonEncode(datosMap),
        filename: 'datos.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          imageBytes,
          filename: imageName ?? 'premio.jpg',
          contentType: MediaType.parse(imageMimeType),
        ),
      );
    }

    return _sendAndParsePrize(request, 'updateStandPrize');
  }

  Future<http.MultipartRequest> _buildMultipartRequest(
    String method,
    String url,
  ) async {
    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token no encontrado. Iniciá sesión nuevamente.');
    }
    final request = http.MultipartRequest(method, Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    return request;
  }

  Future<StandPrizeModel> _sendAndParsePrize(
    http.MultipartRequest request,
    String tag,
  ) async {
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) return StandPrizeModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }
    log('[StandsService] $tag error ${streamed.statusCode}: $body');
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

  /// GET /api/stands/mi-stand/canje/{idPremioUsuario}
  /// Devuelve los datos del premio sin marcarlo como canjeado.
  Future<PrizeCanjeModel> fetchCanjeInfo(int idPremioUsuario) async {
    final url = '${ApiConfig.baseUrl}/stands/mi-stand/canje/$idPremioUsuario';

    final response = await HttpClient.get(
      url,
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return PrizeCanjeModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    log(
      '[StandsService] fetchCanjeInfo error ${response.statusCode}: ${response.body}',
    );
    throw Exception(ErrorParser.parseResponse(response));
  }

  /// POST /api/stands/mi-stand/canje
  /// Confirma la entrega del premio.
  Future<void> confirmarCanje(int idPremioUsuario) async {
    final url = '${ApiConfig.baseUrl}/stands/mi-stand/canje';
    final body = <String, dynamic>{'idPremioUsuario': idPremioUsuario};

    final response = await HttpClient.post(url, includeAuth: true, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    log(
      '[StandsService] confirmarCanje error ${response.statusCode}: ${response.body}',
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
