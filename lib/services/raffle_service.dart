import 'dart:convert';
import 'dart:typed_data';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class RaffleService {
  // ── Listar sorteos del usuario (afiliados + globales) ────────────────────────
  Future<List<Map<String, dynamic>>> fetchMyRaffles() async {
    final response = await HttpClient.get(
      '${ApiConfig.baseUrl}/sorteos/participando',
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    List<dynamic> rawList = const [];
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      final content = decoded['content'];
      if (data is List) {
        rawList = data;
      } else if (content is List) {
        rawList = content;
      }
    }

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  // ── Listar casinos disponibles (para dropdown de creación) ───────────────────
  Future<List<Map<String, dynamic>>> fetchCasinos() async {
    final response = await HttpClient.get(
      '${ApiConfig.baseUrl}/publicidades/casinos',
      includeAuth: true,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final rawList = decoded is List ? decoded : <dynamic>[];

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  // ── Listar sorteos (admin: todos activos) ────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchRaffles() async {
    final response = await HttpClient.get(
      '${ApiConfig.baseUrl}/sorteos',
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    List<dynamic> rawList = const [];
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      final content = decoded['content'];
      if (data is List) {
        rawList = data;
      } else if (content is List) {
        rawList = content;
      }
    }

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  // ── Alternar estado activo ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> toggleRaffleActive(int id) async {
    final response = await HttpClient.patch(
      '${ApiConfig.baseUrl}/sorteos/$id/activo',
      body: {},
      includeAuth: true,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Respuesta inesperada del servidor');
  }

  // ── Obtener sorteo por id ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchRaffleById(int id) async {
    final response = await HttpClient.get(
      '${ApiConfig.baseUrl}/sorteos/$id',
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Respuesta inesperada del servidor');
  }

  // ── Crear sorteo (multipart: sorteo JSON + file opcional) ────────────────────
  Future<void> createRaffle({
    required String text,
    required DateTime fechaFin,
    required int cantidadGanadores,
    required List<Map<String, dynamic>> premios,
    int? casinoGralId,
    int? tidId,
    String? emailPresentador,
    bool activo = true,
    Uint8List? imageBytes,
    String? imageName,
    String imageMimeType = 'image/jpeg',
    String? tipo,
    String? instrucciones,
  }) async {
    final request = await _buildAuthorizedMultipartRequest(
      method: 'POST',
      url: '${ApiConfig.baseUrl}/sorteos',
    );

    final sorteoPayload = <String, dynamic>{
      'text': text,
      'fechaFin': _toIso8601WithOffset(fechaFin),
      'cantidadGanadores': cantidadGanadores,
      'premios': premios,
      'activo': activo,
      if (casinoGralId != null) 'casinoGralId': casinoGralId,
      if (tidId != null) 'tidId': tidId,
      if (emailPresentador != null && emailPresentador.isNotEmpty)
        'emailPresentador': emailPresentador,
      if (tipo != null) 'tipo': tipo,
      if (instrucciones != null && instrucciones.isNotEmpty)
        'instrucciones': instrucciones,
    };

    request.files.add(
      http.MultipartFile.fromString(
        'sorteo',
        jsonEncode(sorteoPayload),
        filename: 'sorteo.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageName ?? 'sorteo.jpg',
          contentType: MediaType.parse(imageMimeType),
        ),
      );
    }

    await _sendOrThrow(request);
  }

  // ── Actualizar sorteo (multipart/form-data) ─────────────────────────────────
  Future<void> updateRaffle({
    required int id,
    required String text,
    required DateTime fechaFin,
    required int cantidadGanadores,
    required List<Map<String, dynamic>> premios,
    int? casinoGralId,
    int? tidId,
    String? emailPresentador,
    bool activo = true,
    Uint8List? imageBytes,
    String? imageName,
    String imageMimeType = 'image/jpeg',
    String? instrucciones,
  }) async {
    final request = await _buildAuthorizedMultipartRequest(
      method: 'PATCH',
      url: '${ApiConfig.baseUrl}/sorteos/$id',
    );

    final sorteoPayload = <String, dynamic>{
      'text': text,
      'fechaFin': _toIso8601WithOffset(fechaFin),
      'cantidadGanadores': cantidadGanadores,
      'premios': premios,
      'activo': activo,
      if (casinoGralId != null) 'casinoGralId': casinoGralId,
      if (tidId != null) 'tidId': tidId,
      if (emailPresentador != null && emailPresentador.isNotEmpty)
        'emailPresentador': emailPresentador,
      if (instrucciones != null && instrucciones.isNotEmpty)
        'instrucciones': instrucciones,
    };

    request.files.add(
      http.MultipartFile.fromString(
        'sorteo',
        jsonEncode(sorteoPayload),
        filename: 'sorteo.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageName ?? 'sorteo.jpg',
          contentType: MediaType.parse(imageMimeType),
        ),
      );
    }

    await _sendOrThrow(request);
  }

  // ── Eliminar sorteo ──────────────────────────────────────────────────────────
  Future<void> deleteRaffle(int id) async {
    final response = await HttpClient.delete(
      '${ApiConfig.baseUrl}/sorteos/$id',
      includeAuth: true,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _toIso8601WithOffset(DateTime dateTime) {
    final local = dateTime.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final totalMinutes = offset.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');

    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');

    return '$year-$month-${day}T$hour:$minute:$second$sign$hours:$minutes';
  }

  Future<http.MultipartRequest> _buildAuthorizedMultipartRequest({
    required String method,
    required String url,
  }) async {
    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token no encontrado. Iniciá sesión nuevamente.');
    }

    final request = http.MultipartRequest(method, Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    return request;
  }

  Future<void> _sendOrThrow(http.MultipartRequest request) async {
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('HTTP ${streamed.statusCode}: $body');
    }
  }
}
