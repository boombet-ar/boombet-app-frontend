import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class CuponesService {
  static Future<Map<String, dynamic>> afiliarAfiliado() async {
    try {
      final url = '${ApiConfig.baseUrl}/cupones/afiliado';
      developer.log('DEBUG CuponesService - URL: $url');

      final response = await HttpClient.post(url, body: const {});

      developer.log(
        'DEBUG CuponesService - Response status: ${response.statusCode}',
      );
      developer.log('DEBUG CuponesService - Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as dynamic;
        return {'success': true, 'data': data};
      }

      developer.log('ERROR CuponesService - Status: ${response.statusCode}');
      throw Exception(
        'Error afiliando a Bonda: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      developer.log('ERROR CuponesService - Exception: $e');
      developer.log(
        'ERROR CuponesService - Stack trace: ${StackTrace.current}',
      );
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

      developer.log(
        'DEBUG CuponesService - Fetching cupones (page: $page, category: ${categoryFilter ?? '-'}, query: ${normalizedSearch ?? '-'}, order: $normalizedOrderBy )',
      );

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

      developer.log('[CuponesService] URL final: $url');

      developer.log('DEBUG CuponesService - URL: $url');

      final response = await HttpClient.get(
        url,
        includeAuth: true,
        timeout: const Duration(seconds: 60),
      );

      developer.log(
        'DEBUG CuponesService - Response status: ${response.statusCode}',
      );
      developer.log('DEBUG CuponesService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as dynamic;

        developer.log(
          'DEBUG CuponesService - Decoded data type: ${data.runtimeType}',
        );

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

          developer.log(
            'DEBUG CuponesService - Total: $total, HasMore: $hasMore, List length: ${cuponList.length}',
          );

          if (cuponList.isNotEmpty) {
            developer.log(
              'DEBUG CuponesService - First cupon raw data: ${jsonEncode(cuponList.first)}',
            );
          }
        }

        final cupones = cuponList
            .map((json) {
              try {
                return Cupon.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                developer.log('ERROR CuponesService - Error parsing cupón: $e');
                developer.log('ERROR CuponesService - Cupón data: $json');
                // Retornar null para problematic cupones
                return null;
              }
            })
            .whereType<Cupon>()
            .toList();

        developer.log('DEBUG CuponesService - Got ${cupones.length} cupones');

        return {
          'cupones': cupones,
          'total': total,
          'page': page,
          'page_size': pageSize,
          'has_more': hasMore,
        };
      } else {
        developer.log('ERROR CuponesService - Status: ${response.statusCode}');
        throw Exception(
          'Error fetching cupones: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      developer.log('ERROR CuponesService - Exception: $e');
      developer.log(
        'ERROR CuponesService - Stack trace: ${StackTrace.current}',
      );
      rethrow;
    }
  }

  static Future<List<Categoria>> getCategorias() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/cupones/categorias',
      ).toString();

      developer.log('DEBUG CuponesService - Categorias URL: $url');

      final response = await HttpClient.get(
        url,
        includeAuth: true,
        timeout: const Duration(seconds: 40),
      );

      developer.log(
        'DEBUG CuponesService - Categorias status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((item) {
                try {
                  return Categoria.fromJson(item as Map<String, dynamic>);
                } catch (e) {
                  developer.log(
                    'WARN CuponesService - Skipping categoria parse error: $e',
                  );
                  return null;
                }
              })
              .whereType<Categoria>()
              .toList();
        }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((item) {
                try {
                  return Categoria.fromJson(item as Map<String, dynamic>);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Categoria>()
              .toList();
        }
        return [];
      }

      throw Exception(
        'Error fetching categorias: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      developer.log('ERROR CuponesService - Categorias exception: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCuponesRecibidos({
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      developer.log(
        'DEBUG CuponesService - Fetching cupones recibidos (page: $page)',
      );

      final url = Uri.parse('${ApiConfig.baseUrl}/cupones/recibidos')
          .replace(
            queryParameters: {
              'page': page.toString(),
              'page_size': pageSize.toString(),
            },
          )
          .toString();

      developer.log('DEBUG CuponesService - URL: $url');

      final response = await HttpClient.get(
        url,
        includeAuth: true,
        timeout: const Duration(seconds: 60),
      );

      developer.log(
        'DEBUG CuponesService - Response status: ${response.statusCode}',
      );
      developer.log('DEBUG CuponesService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as dynamic;

        developer.log(
          'DEBUG CuponesService - Decoded data type: ${data.runtimeType}',
        );

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

          developer.log(
            'DEBUG CuponesService - Total: $total, List length: ${cuponList.length}',
          );

          // Log detallado del primer cupón para ver estructura
          if (cuponList.isNotEmpty) {
            developer.log(
              'DEBUG CuponesService - First cupon raw data: ${jsonEncode(cuponList.first)}',
            );
          }
        }

        final cupones = cuponList
            .map((json) {
              try {
                return Cupon.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                developer.log(
                  'ERROR CuponesService - Error parsing cupón recibido: $e',
                );
                developer.log('ERROR CuponesService - Cupón data: $json');
                // Retornar null para problematic cupones
                return null;
              }
            })
            .whereType<Cupon>()
            .toList();

        developer.log(
          'DEBUG CuponesService - Got ${cupones.length} cupones recibidos',
        );

        // Log detallado del primer cupón parseado
        if (cupones.isNotEmpty) {
          developer.log(
            'DEBUG CuponesService - First cupon parsed - ID: ${cupones.first.id}, Fecha: ${cupones.first.fechaVencimiento}',
          );
        }

        return {
          'cupones': cupones,
          'total': total,
          'has_more': hasMore,
          'page': page,
          'page_size': pageSize,
        };
      } else {
        developer.log('ERROR CuponesService - Status: ${response.statusCode}');
        throw Exception(
          'Error fetching cupones recibidos: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      developer.log('ERROR CuponesService - Exception: $e');
      developer.log(
        'ERROR CuponesService - Stack trace: ${StackTrace.current}',
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> claimCupon({
    required String cuponId,
  }) async {
    try {
      developer.log('DEBUG CuponesService - Claiming cupon (id: $cuponId)');

      final url = '${ApiConfig.baseUrl}/cupones/$cuponId/codigo';

      developer.log('DEBUG CuponesService - URL: $url');

      // Usar HttpClient que automáticamente agrega el token JWT
      final response = await HttpClient.post(
        url,
        body: {}, // Body vacío, pero el token JWT va en headers automáticamente
      );

      developer.log(
        'DEBUG CuponesService - Response status: ${response.statusCode}',
      );
      developer.log('DEBUG CuponesService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        developer.log('DEBUG CuponesService - Cupon claimed successfully');

        return {'success': true, 'data': data['success'] ?? data};
      } else {
        developer.log('ERROR CuponesService - Status: ${response.statusCode}');
        throw Exception(
          'Error claiming cupon: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      developer.log('ERROR CuponesService - Exception: $e');
      developer.log(
        'ERROR CuponesService - Stack trace: ${StackTrace.current}',
      );
      rethrow;
    }
  }
}
