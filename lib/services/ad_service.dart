import 'dart:convert';
import 'dart:typed_data';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AdService {
  Future<void> createAd({
    required Uint8List imageBytes,
    required String text,
    required DateTime endAt,
    int? casinoGralId,
    String? imageName,
    String imageMimeType = 'image/jpeg',
  }) async {
    final request = await _buildAuthorizedMultipartRequest(
      method: 'POST',
      url: '${ApiConfig.baseUrl}/publicidades',
    );

    final publicidadPayload = <String, dynamic>{
      'casinoGralId': casinoGralId,
      'endAt': _toIso8601WithOffset(endAt),
      'text': text,
    };

    request.files.add(
      http.MultipartFile.fromString(
        'publicidad',
        jsonEncode(publicidadPayload),
        filename: 'publicidad.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: imageName ?? 'publicidad.jpg',
        contentType: MediaType.parse(imageMimeType),
      ),
    );

    await _sendOrThrow(request);
  }

  Future<void> updateAd({
    required int id,
    required String text,
    required DateTime endAt,
    int? casinoGralId,
    Uint8List? imageBytes,
    String? imageName,
    String imageMimeType = 'image/jpeg',
  }) async {
    final request = await _buildAuthorizedMultipartRequest(
      method: 'PATCH',
      url: '${ApiConfig.baseUrl}/publicidades/$id',
    );

    final publicidadPayload = <String, dynamic>{
      'casinoGralId': casinoGralId,
      'endAt': _toIso8601WithOffset(endAt),
      'text': text,
    };

    request.files.add(
      http.MultipartFile.fromString(
        'publicidad',
        jsonEncode(publicidadPayload),
        filename: 'publicidad.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageName ?? 'publicidad.jpg',
          contentType: MediaType.parse(imageMimeType),
        ),
      );
    }

    await _sendOrThrow(request);
  }

  Future<void> deleteAd(int id) async {
    final response = await HttpClient.delete(
      '${ApiConfig.baseUrl}/publicidades/$id',
      includeAuth: true,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

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
    final millisecond = local.millisecond.toString().padLeft(3, '0');

    return '$year-$month-$day\T$hour:$minute:$second.$millisecond$sign$hours:$minutes';
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
