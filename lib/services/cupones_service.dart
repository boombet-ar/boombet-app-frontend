import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/utils/category_order.dart';
import 'dart:convert';

class CuponesService {
  static Future<Map<String, dynamic>> afiliarAfiliado() async {
    try {
      final url = '${ApiConfig.baseUrl}/cupones/afiliado';

      final response = await HttpClient.post(url, body: const {});

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as dynamic;
        return {'success': true, 'data': data};
      }

      throw Exception(
        'Error afiliando a Bonda: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCupones({
    required int page,
    required int pageSize,
    String? categoryId,
    String? categoryName,
    String? searchQuery,
    String? orderBy,
  }) async {
    try {
      final category = categoryId?.toString().trim();
      final categoryLabel = categoryName?.toString().trim();
      final categoryFilter = (category != null && category.isNotEmpty)
          ? category
          : categoryLabel;
      final normalizedSearch = searchQuery?.trim();
      final normalizedOrderBy = (orderBy?.trim().isNotEmpty ?? false)
          ? orderBy!.trim()
          : 'relevant';

      final url = Uri.parse('${ApiConfig.baseUrl}/cupones')
          .replace(
            queryParameters: {
              'page': page.toString(),
              'page_size': pageSize.toString(),
              'orderBy': normalizedOrderBy,
              'with_locations': 'false',
              // Incluir cupones en subcategorías (ej: Cines bajo Entretenimiento)
              'subcategories': 'true',
              // Enviar filtro de categoría si se especificó; priorizar clave 'categoria'
              if (categoryFilter != null && categoryFilter.isNotEmpty) ...{
                'categoria': categoryFilter,
              },
              if (normalizedSearch != null && normalizedSearch.isNotEmpty) ...{
                'query': normalizedSearch,
              },
            },
          )
          .toString();

      final response = await HttpClient.get(
        url,
        includeAuth: true,
        timeout: const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as dynamic;

        // El backend devuelve: { count, previous, next, results: [...] }
        List<dynamic> cuponList = [];
        int total = 0;
        bool hasMore = false;

        if (data is Map) {
          // Extraer los cupones de 'results'
          cuponList = data['results'] ?? data['data'] ?? data['cupones'] ?? [];
          total = data['count'] ?? cuponList.length;
          // Si el backend no envía 'next', inferimos con count; si la página viene vacía, no seguimos paginando
          hasMore =
              cuponList.isNotEmpty &&
              ((data['next'] != null) || (total > page * pageSize));
        }

        final cupones = cuponList
            .map((json) {
              try {
                return Cupon.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                // Retornar null para problematic cupones
                return null;
              }
            })
            .whereType<Cupon>()
            .toList();

        return {
          'cupones': cupones,
          'total': total,
          'page': page,
          'page_size': pageSize,
          'has_more': hasMore,
        };
      } else {
        throw Exception(
          'Error fetching cupones: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Categoria>> getCategorias() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/cupones/categorias',
      ).toString();

      final response = await HttpClient.get(
        url,
        includeAuth: true,
        timeout: const Duration(seconds: 40),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final parsed = data
              .map((item) {
                try {
                  return Categoria.fromJson(item as Map<String, dynamic>);
                } catch (e) {
                  return null;
                }
              })
              .whereType<Categoria>()
              .toList();

          return CategoryOrder.sortCategorias(parsed);
        }
        if (data is Map && data['data'] is List) {
          final parsed = (data['data'] as List)
              .map((item) {
                try {
                  return Categoria.fromJson(item as Map<String, dynamic>);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Categoria>()
              .toList();

          return CategoryOrder.sortCategorias(parsed);
        }
        return [];
      }

      throw Exception(
        'Error fetching categorias: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCuponesRecibidos({
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/cupones/recibidos')
          .replace(
            queryParameters: {
              'page': page.toString(),
              'page_size': pageSize.toString(),
            },
          )
          .toString();

      final response = await HttpClient.get(
        url,
        includeAuth: true,
        timeout: const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as dynamic;

        // El backend devuelve: { count, results: [...] }
        List<dynamic> cuponList = [];
        int total = 0;
        bool hasMore = false;

        if (data is Map) {
          // Extraer los cupones de 'results'
          cuponList = data['results'] ?? data['data'] ?? data['cupones'] ?? [];
          total = data['count'] ?? cuponList.length;
          hasMore =
              cuponList.isNotEmpty &&
              ((data['next'] != null) || (total > page * pageSize));
        }

        final cupones = cuponList
            .map((json) {
              try {
                return Cupon.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                // Retornar null para problematic cupones
                return null;
              }
            })
            .whereType<Cupon>()
            .toList();

        return {
          'cupones': cupones,
          'total': total,
          'has_more': hasMore,
          'page': page,
          'page_size': pageSize,
        };
      } else {
        throw Exception(
          'Error fetching cupones recibidos: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> claimCupon({
    required String cuponId,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/cupones/$cuponId/codigo';

      // Usar HttpClient que automáticamente agrega el token JWT
      final response = await HttpClient.post(
        url,
        body: {}, // Body vacío, pero el token JWT va en headers automáticamente
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        return {'success': true, 'data': data['success'] ?? data};
      } else {
        throw Exception(
          'Error claiming cupon: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
