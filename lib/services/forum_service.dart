import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/forum_models.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:flutter/foundation.dart';

class ForumService {
  static Future<PageableResponse<ForumPost>> getPosts({
    int page = 0,
    int size = 20,
  }) async {
    final url = '${ApiConfig.baseUrl}/publicaciones?page=$page&size=$size';
    final response = await HttpClient.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PageableResponse.fromJson(
        json,
        (m) => _resolveAvatar(ForumPost.fromJson(m)),
      );
    }
    throw Exception('Error al cargar publicaciones: ${response.statusCode}');
  }

  static Future<PageableResponse<ForumPost>> getMyPosts({
    int page = 0,
    int size = 20,
  }) async {
    final url = '${ApiConfig.baseUrl}/publicaciones/me?page=$page&size=$size';
    // Evitar cache para no servir resultados viejos de este usuario
    final response = await HttpClient.get(url, cacheTtl: Duration.zero);

    // Debug detallado para diagnosticar vacío
    print('🛰️ [ForumService] GET /publicaciones/me page=$page size=$size');
    print('🛰️ Status: ${response.statusCode}');
    print('🛰️ Body length: ${response.body.length}');
    if (response.statusCode == 200) {
      print(
        '🛰️ Body preview: ${response.body.substring(0, response.body.length > 400 ? 400 : response.body.length)}',
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PageableResponse.fromJson(
        json,
        (m) => _resolveAvatar(ForumPost.fromJson(m)),
      );
    }
    throw Exception(
      'Error al cargar mis publicaciones: ${response.statusCode}',
    );
  }

  static Future<List<ForumPost>> getReplies(
    int parentId, {
    int page = 0,
    int size = 20,
    bool bypassCache = false,
  }) async {
    final url =
        '${ApiConfig.baseUrl}/publicaciones/$parentId/respuestas?page=$page&size=$size';
    final response = await HttpClient.get(
      url,
      cacheTtl: bypassCache ? Duration.zero : null,
    );

    if (response.statusCode == 200) {
      final pageableResponse = PageableResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        (m) => _resolveAvatar(ForumPost.fromJson(m)),
      );
      return pageableResponse.content;
    }
    throw Exception('Error al cargar respuestas: ${response.statusCode}');
  }

  static Future<ForumPost> getPostById(
    int id, {
    bool bypassCache = false,
  }) async {
    final url = '${ApiConfig.baseUrl}/publicaciones/$id';
    final response = await HttpClient.get(
      url,
      cacheTtl: bypassCache ? Duration.zero : null,
    );

    if (response.statusCode == 200) {
      return _resolveAvatar(ForumPost.fromJson(jsonDecode(response.body)));
    }
    throw Exception('Error al cargar publicación: ${response.statusCode}');
  }

  static Future<ForumPost> createPost(CreatePostRequest request) async {
    final url = '${ApiConfig.baseUrl}/publicaciones';
    final response = await HttpClient.post(url, body: request.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final post = _resolveAvatar(
        ForumPost.fromJson(jsonDecode(response.body)),
      );

      // Limpiar caché para forzar recarga de publicaciones y respuestas
      HttpClient.clearCache(urlPattern: '/publicaciones');

      return post;
    }
    throw Exception('Error al crear publicación: ${response.statusCode}');
  }

  static Future<void> deletePost(int id) async {
    final url = '${ApiConfig.baseUrl}/publicaciones/$id';
    print('🗑️ [ForumService] DELETE -> $url');

    final response = await HttpClient.delete(url);

    print('🗑️ [ForumService] DELETE Response: ${response.statusCode}');
    print('🗑️ [ForumService] Response body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      print(
        '❌ [ForumService] Delete failed with status ${response.statusCode}',
      );

      // Detectar intento de eliminar publicación de otro usuario (403)
      if (response.statusCode == 403) {
        throw Exception(
          'No se pueden eliminar publicaciones de otros usuarios.',
        );
      }

      // Parsear mensaje del backend cuando es error 500
      if (response.statusCode == 500) {
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final message = errorJson['message'] as String?;

          // Detectar error de permisos
          if (message != null && message.toLowerCase().contains('permiso')) {
            throw Exception(
              'No se pueden eliminar publicaciones de otros usuarios.',
            );
          }

          // Detectar error de foreign key (publicación con respuestas)
          if (message != null &&
              (message.contains('foreign key') ||
                  response.body.contains('foreign key constraint'))) {
            throw Exception(
              'No se puede eliminar una publicación que tiene respuestas. Elimina primero las respuestas.',
            );
          }

          // Mostrar mensaje del backend si está disponible
          if (message != null && message.isNotEmpty) {
            throw Exception(message);
          }
        } catch (e) {
          // Si no se puede parsear, continuar con el mensaje genérico
          if (e is Exception) rethrow;
        }
      }

      throw Exception('Error al eliminar publicación: ${response.statusCode}');
    }

    print('✅ [ForumService] Post deleted successfully');

    // Limpiar caché para forzar recarga de publicaciones y respuestas
    HttpClient.clearCache(urlPattern: '/publicaciones');
  }

  static ForumPost _resolveAvatar(ForumPost post) {
    final resolved = _resolveAvatarUrl(post.avatarUrl);
    if (resolved == post.avatarUrl) return post;
    return post.copyWith(avatarUrl: resolved);
  }

  static String _resolveAvatarUrl(String raw) {
    if (raw.isEmpty) return '';

    String encode(String url) {
      try {
        final uri = Uri.parse(url);
        return Uri(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.port,
          pathSegments: uri.pathSegments,
        ).toString();
      } catch (_) {
        return url.replaceAll(' ', '%20');
      }
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _proxyImageForWeb(encode(raw));
    }

    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final path = baseUri.path.replaceFirst(RegExp(r'/api/?$'), '');
    final joined = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port,
      path: raw.startsWith('/') ? raw : '$path/$raw',
    );
    return _proxyImageForWeb(joined.toString());
  }

  static String _proxyImageForWeb(String url) {
    if (!kIsWeb) return url;
    final proxyBase = ApiConfig.imageProxyBase;
    if (proxyBase.isEmpty) return url;
    return '$proxyBase$url';
  }
}
