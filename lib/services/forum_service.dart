import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/forum_models.dart';
import 'package:boombet_app/services/http_client.dart';

class ForumService {
  static Future<PageableResponse<ForumPost>> getPosts({
    int page = 0,
    int size = 20,
  }) async {
    final url = '${ApiConfig.baseUrl}/publicaciones?page=$page&size=$size';
    final response = await HttpClient.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PageableResponse.fromJson(json, ForumPost.fromJson);
    }
    throw Exception('Error al cargar publicaciones: ${response.statusCode}');
  }

  static Future<ForumPost> getPostById(int id) async {
    final url = '${ApiConfig.baseUrl}/publicaciones/$id';
    final response = await HttpClient.get(url);

    if (response.statusCode == 200) {
      return ForumPost.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al cargar publicación: ${response.statusCode}');
  }

  static Future<List<ForumPost>> getReplies(int parentId) async {
    final url = '${ApiConfig.baseUrl}/publicaciones/$parentId/respuestas';
    final response = await HttpClient.get(url);

    if (response.statusCode == 200) {
      final pageableResponse = PageableResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        ForumPost.fromJson,
      );
      return pageableResponse.content;
    }
    throw Exception('Error al cargar respuestas: ${response.statusCode}');
  }

  static Future<ForumPost> createPost(CreatePostRequest request) async {
    final url = '${ApiConfig.baseUrl}/publicaciones';
    final response = await HttpClient.post(url, body: request.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final post = ForumPost.fromJson(jsonDecode(response.body));

      // Limpiar caché para forzar recarga de publicaciones y respuestas
      HttpClient.clearCache(urlPattern: '/publicaciones');

      return post;
    }
    throw Exception('Error al crear publicación: ${response.statusCode}');
  }

  static Future<void> deletePost(int id) async {
    final url = '${ApiConfig.baseUrl}/publicaciones/$id';
    final response = await HttpClient.delete(url);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar publicación: ${response.statusCode}');
    }
  }
}
