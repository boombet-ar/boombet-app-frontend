import 'dart:convert';

import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/forum_models.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/utils/inappropriate_content_guard.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/forum_service.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class _ForumDescriptor {
  final String id;
  final String label;
  final int? casinoId;
  final String? logoAsset;
  final String? logoUrl;

  const _ForumDescriptor({
    required this.id,
    required this.label,
    this.casinoId,
    this.logoAsset,
    this.logoUrl,
  });
}

class _AffiliatedCasino {
  final int? id;
  final String url;
  final String nombreGral;
  final String logoUrl;

  const _AffiliatedCasino({
    required this.id,
    required this.url,
    required this.nombreGral,
    required this.logoUrl,
  });

  factory _AffiliatedCasino.fromJson(Map<String, dynamic> json) {
    dynamic pick(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k];
      }
      return null;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v > 0 ? v : null;
      final parsed = int.tryParse('${v ?? ''}');
      if (parsed == null) return null;
      return parsed > 0 ? parsed : null;
    }

    String parseString(dynamic v) => (v ?? '').toString();

    // Algunos backends devuelven el casino anidado (o anidado dentro de `casino`).
    final nestedCasino = (json['casino'] is Map)
        ? (json['casino'] as Map).cast<String, dynamic>()
        : null;
    final nestedCasinoGral =
        (nestedCasino != null && nestedCasino['casinoGral'] is Map)
        ? (nestedCasino['casinoGral'] as Map).cast<String, dynamic>()
        : (nestedCasino != null && nestedCasino['casino_gral'] is Map)
        ? (nestedCasino['casino_gral'] as Map).cast<String, dynamic>()
        : null;
    final nested = (json['casinoGral'] is Map)
        ? (json['casinoGral'] as Map).cast<String, dynamic>()
        : (json['casino_gral'] is Map)
        ? (json['casino_gral'] as Map).cast<String, dynamic>()
        : nestedCasinoGral ?? nestedCasino;

    final source = nested ?? json;

    dynamic pickFromEither(List<String> keys) {
      return pick(source, keys) ?? pick(json, keys);
    }

    // Algunos backends envían el ID como `casino_gral` / `casinoGral` (valor directo)
    // en vez de `casino_gral_id`.
    final directCasinoGral = pickFromEither(const [
      'casinoGral',
      'casino_gral',
    ]);
    final idValue =
        pickFromEither(const [
          'casinoGralId',
          'casinoGralID',
          'casino_gral_id',
          'casino_gralId',
          'casino_general_id',
          'casinoGeneralId',
          'casino_general',
          'casinoGeneral',
          'idCasinoGral',
          'id_casino_gral',
          'idGral',
          'id_gral',
          'casinoId',
          'casino_id',
          'id',
        ]) ??
        directCasinoGral;

    return _AffiliatedCasino(
      id: parseInt(idValue),
      url: parseString(
        pickFromEither(const ['url', 'casinoUrl', 'casino_url', 'link']),
      ),
      nombreGral: parseString(
        pickFromEither(const [
          'nombreGral',
          'nombre_gral',
          'nombre',
          'name',
          'titulo',
        ]),
      ),
      logoUrl: parseString(
        pickFromEither(const [
          'logoUrl',
          'logo_url',
          'logo',
          'logoURL',
          'logoGral',
          'logo_gral',
          'imagen',
          'imagen_url',
          'imageUrl',
          'image_url',
          'img',
          'iconUrl',
          'icon_url',
          'icono',
          'icono_url',
        ]),
      ),
    );
  }
}

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  static const String _boomBetForumId = 'boombet';
  static const int _forumTabIndex = 3;

  VoidCallback? _selectedPageListener;
  int? _lastSelectedPage;

  List<_AffiliatedCasino> _affiliatedCasinos = const [];
  String _selectedForumId = _boomBetForumId;


  List<ForumPost> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  int _totalPages = 0;
  bool _showMine = false;

  void _openPost(BuildContext context, int postId) {
    context.push('/forum/post/$postId');
  }

  @override
  void initState() {
    super.initState();

    // En HomePage, el ForumPage vive dentro de un IndexedStack.
    // Eso significa que initState puede correr antes de que el usuario abra el tab de Foro.
    // Si en ese momento el token aún no está listo, la llamada a /users/casinos_afiliados puede fallar
    // y el selector queda "pegado" mostrando solo BoomBet. Reintentamos al entrar al tab.
    _lastSelectedPage = selectedPageNotifier.value;
    _selectedPageListener = () {
      final current = selectedPageNotifier.value;
      final wasForum = _lastSelectedPage == _forumTabIndex;
      final isForum = current == _forumTabIndex;
      _lastSelectedPage = current;

      if (!mounted) return;
      if (!isForum || wasForum) return;

      // Al entrar al tab, reintentar cargar casinos (y refrescar posts para el foro seleccionado).
      _loadAffiliatedCasinos();
      _loadPosts(refresh: true);
    };
    selectedPageNotifier.addListener(_selectedPageListener!);

    _loadAffiliatedCasinos();
    _loadPosts();
  }

  @override
  void dispose() {
    if (_selectedPageListener != null) {
      selectedPageNotifier.removeListener(_selectedPageListener!);
    }
    pageBackCallbacks.remove(_forumTabIndex);
    super.dispose();
  }

  List<_ForumDescriptor> get _forums {
    // Foro general BoomBet: hardcodeado (casinoId == null)
    final items = <_ForumDescriptor>[
      const _ForumDescriptor(
        id: _boomBetForumId,
        label: 'BoomBet',
        casinoId: null,
        logoAsset: 'assets/images/boombetlogo.png',
      ),
    ];

    // Foros de casinos: vienen del backend.
    // Nota: si algún casino viene sin id, lo seguimos mostrando (pero no se podrá filtrar por casino_gral_id).
    for (var i = 0; i < _affiliatedCasinos.length; i++) {
      final casino = _affiliatedCasinos[i];
      final idPart = casino.id != null
          ? 'id_${casino.id}'
          : (casino.url.isNotEmpty ? 'url_${casino.url.hashCode}' : 'idx_$i');

      items.add(
        _ForumDescriptor(
          id: 'casino_$idPart',
          label: casino.nombreGral.isNotEmpty ? casino.nombreGral : 'Casino',
          casinoId: casino.id,
          logoUrl: casino.logoUrl,
        ),
      );
    }

    // Dedupe por id (por si el backend repite casinos)
    final byId = <String, _ForumDescriptor>{};
    for (final f in items) {
      byId.putIfAbsent(f.id, () => f);
    }
    return byId.values.toList();
  }

  bool _looksLikeCasinoMap(Map<String, dynamic> m) {
    // Heurística: basta con que tenga un id (directo o dentro de objetos anidados típicos).
    final directKeys = <String>{
      'id',
      'casinoGralId',
      'casino_gral_id',
      'casino_general_id',
      'casinoGeneralId',
      'idGral',
      'id_gral',
      'casinoId',
      'casino_id',
    };
    if (m.keys.any(directKeys.contains)) return true;
    final nested = m['casino'] ?? m['casinoGral'] ?? m['casino_gral'];
    if (nested is Map) {
      final nestedMap = nested.cast<String, dynamic>();
      if (nestedMap.keys.any(directKeys.contains)) return true;
      final nested2 = nestedMap['casinoGral'] ?? nestedMap['casino_gral'];
      if (nested2 is Map) {
        final nested2Map = nested2.cast<String, dynamic>();
        if (nested2Map.keys.any(directKeys.contains)) return true;
      }
    }
    return false;
  }

  List<Map<String, dynamic>> _extractAffiliatedCasinoItems(
    dynamic decoded, {
    int depth = 0,
  }) {
    if (decoded is List) {
      final maps = decoded
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      // El endpoint que usa la pestaña "Casinos" devuelve directamente una lista.
      // No forzamos heurísticas acá: si es lista de mapas, la intentamos parsear.
      return maps;
    }

    if (decoded is! Map) return const [];
    if (depth >= 3) return const [];

    final map = decoded.cast<String, dynamic>();

    // Primero: claves esperables.
    const candidateKeys = <String>[
      'content',
      'data',
      'casinos',
      'casinosAfiliados',
      'casinos_afiliados',
      'afiliados',
      'rows',
      'result',
      'results',
      'items',
      'payload',
    ];

    for (final key in candidateKeys) {
      if (!map.containsKey(key)) continue;
      final extracted = _extractAffiliatedCasinoItems(
        map[key],
        depth: depth + 1,
      );
      if (extracted.isNotEmpty) return extracted;
    }

    // Fallback: buscar recursivamente en valores (por si el backend cambió los nombres).
    for (final v in map.values) {
      final extracted = _extractAffiliatedCasinoItems(v, depth: depth + 1);
      if (extracted.isNotEmpty) return extracted;
    }

    return const [];
  }

  Future<void> _loadAffiliatedCasinos() async {
    if (!mounted) return;
    try {
      final url = '${ApiConfig.baseUrl}/users/casinos_afiliados';
      final response = await HttpClient.get(
        url,
        includeAuth: true,
        cacheTtl: const Duration(seconds: 45),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        final items = _extractAffiliatedCasinoItems(decoded);
        if (items.isNotEmpty) {
          final casinos = items.map(_AffiliatedCasino.fromJson).toList();

          if (kDebugMode) {
            debugPrint(
              '[Forum] casinos_afiliados parsed=${casinos.length} status=${response.statusCode}',
            );

            final missingIdCount = casinos.where((c) => c.id == null).length;
            if (missingIdCount > 0) {
              debugPrint(
                '[Forum] casinos_afiliados warning: $missingIdCount items have id==null (cannot filter posts by casino_gral_id). FirstKeys=${items.first.keys.take(25).toList()}',
              );
            }
          }

          setState(() {
            _affiliatedCasinos = casinos;
          });

          // Si el seleccionado ya no existe (cambió afiliación), volver al foro general.
          final forumIds = _forums.map((f) => f.id).toSet();
          if (!forumIds.contains(_selectedForumId)) {
            setState(() {
              _selectedForumId = _boomBetForumId;
            });
          }
          return;
        }

        if (kDebugMode) {
          final decodedType = decoded.runtimeType;
          final keys = decoded is Map
              ? (decoded as Map).keys.take(20).toList()
              : null;
          debugPrint(
            '[Forum] casinos_afiliados: no list found type=$decodedType keys=$keys status=${response.statusCode}',
          );
        }
      }

      setState(() {
        _affiliatedCasinos = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _affiliatedCasinos = const [];
      });
    }
  }

  String _safeImageUrl(String url) {
    if (url.isEmpty) return url;
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;
    final scheme = uri.scheme.isEmpty
        ? 'https'
        : (uri.scheme == 'http' ? 'https' : uri.scheme);
    return uri.replace(scheme: scheme).toString();
  }

  String _imageUrlForWeb(String url) {
    final safe = _safeImageUrl(url);
    if (!kIsWeb || safe.isEmpty) return safe;
    final proxyBase = ApiConfig.imageProxyBase;
    if (proxyBase.isEmpty) return safe;
    return '$proxyBase${Uri.encodeComponent(safe)}';
  }

  _ForumDescriptor get _selectedForum {
    final forums = _forums;
    if (forums.isEmpty) {
      return const _ForumDescriptor(id: 'empty', label: '', casinoId: null);
    }
    return forums.firstWhere(
      (f) => f.id == _selectedForumId,
      orElse: () => forums.first,
    );
  }

  int? get _selectedCasinoGralId => _selectedForum.casinoId;

  bool get _isBoomBetForum => _selectedForumId == _boomBetForumId;

  void _selectForum(_ForumDescriptor forum) {
    if (_selectedForumId == forum.id) return;

    setState(() {
      _selectedForumId = forum.id;
    });

    // Mantener ids y logos siempre actualizados al cambiar de foro.
    // (El usuario pidió re-fetch al alternar entre casinos.)
    _loadAffiliatedCasinos();
    _loadPosts(refresh: true);
  }

  void _goToNextPage() {
    final lastIndex = _totalPages > 0 ? _totalPages - 1 : _currentPage;
    if (!_hasMore || _isLoading || _currentPage >= lastIndex) return;
    setState(() {
      _currentPage++;
    });
    _loadPosts();
  }

  void _goToPreviousPage() {
    if (_currentPage == 0 || _isLoading) return;
    setState(() {
      _currentPage--;
    });
    _loadPosts();
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (!mounted) return;

    const newestFirstSort = ['createdAt,desc'];

    if (refresh) {
      HttpClient.clearCache(urlPattern: '/publicaciones/me');
      setState(() {
        _currentPage = 0;
        _hasMore = true;
        _posts.clear();
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      int page = _currentPage;
      PageableResponse<ForumPost> response;
      List<ForumPost> parsedContent;

      // Avanzar hacia delante hasta encontrar página con contenido
      while (true) {
        final casinoGralId = _selectedCasinoGralId;
        response = _showMine
            ? await ForumService.getMyPosts(
                page: page,
                size: 10,
                casinoId: casinoGralId,
                sort: newestFirstSort,
              )
            : await ForumService.getPosts(
                page: page,
                size: 10,
                casinoId: casinoGralId,
                sort: newestFirstSort,
              );

        if (!mounted) return;

        final baseList = _showMine
            // incluir también respuestas propias
            ? response.content
            : response.content.where((p) => p.parentId == null).toList();

        // Importante: cuando estamos en el foro general BoomBet, no queremos
        // mezclar publicaciones de casinos (casinoGralId != null).
        // El backend, sin filtro, suele devolver “todo”, así que filtramos acá.
        if (_isBoomBetForum) {
          parsedContent = baseList
              .where((p) => p.casinoGralId == null)
              .toList();
        } else if (casinoGralId != null) {
          parsedContent = baseList
              .where((p) => p.casinoGralId == casinoGralId)
              .toList();
        } else {
          parsedContent = baseList;
        }

        if (parsedContent.isEmpty && !response.last) {
          page++;
          continue;
        }
        break;
      }

      // Si la última página está vacía, intentar retroceder hasta hallar datos
      while (parsedContent.isEmpty && page > 0) {
        page--;
        final casinoGralId = _selectedCasinoGralId;
        response = _showMine
            ? await ForumService.getMyPosts(
                page: page,
                size: 10,
                casinoId: casinoGralId,
                sort: newestFirstSort,
              )
            : await ForumService.getPosts(
                page: page,
                size: 10,
                casinoId: casinoGralId,
                sort: newestFirstSort,
              );

        if (!mounted) return;

        final baseList = _showMine
            ? response.content
            : response.content.where((p) => p.parentId == null).toList();

        if (_isBoomBetForum) {
          parsedContent = baseList
              .where((p) => p.casinoGralId == null)
              .toList();
        } else if (casinoGralId != null) {
          parsedContent = baseList
              .where((p) => p.casinoGralId == casinoGralId)
              .toList();
        } else {
          parsedContent = baseList;
        }

        if (parsedContent.isNotEmpty || response.first) {
          break;
        }
      }

      if (!mounted) return;

      // Calcular páginas efectivas evitando saltar a páginas vacías
      final effectiveTotalPages = parsedContent.isEmpty
          ? page + 1
          : (response.last ? page + 1 : response.totalPages);
      final hasMore =
          parsedContent.isNotEmpty && page < effectiveTotalPages - 1;

      setState(() {
        _currentPage = page;
        _posts = parsedContent;
        _hasMore = hasMore;
        _totalPages = effectiveTotalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar publicaciones';
        _isLoading = false;
      });
    }
  }

  void _showCreatePostDialog() {
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _CreatePostDialog(
        contentController: contentController,
        onSubmit: () async {
          final content = contentController.text.trim();

          if (content.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Escribe algo para publicar')),
              );
            }
            return;
          }

          final blocked =
              await InappropriateContentGuard.blockIfContainsInappropriateContent(
                context: context,
                text: content,
              );
          if (blocked) return;

          try {
            // BoomBet (foro general) = casino_gral_id null.
            // Casino = requiere id válido desde /users/casinos_afiliados.
            final int? casinoGralIdToSend;
            if (_isBoomBetForum) {
              casinoGralIdToSend = null;
            } else {
              final id = _selectedCasinoGralId;
              if (id == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No se pudo publicar: este casino no tiene id válido.',
                      ),
                    ),
                  );
                }
                return;
              }
              casinoGralIdToSend = id;
            }

            await ForumService.createPost(
              CreatePostRequest(
                content: content,
                casinoGralId: casinoGralIdToSend,
              ),
            );
            if (mounted) {
              Navigator.pop(context);
              _loadPosts(refresh: true);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildForumSelector(isDark, accent),
            _buildActionBar(accent, isDark),
            Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: accent,
                      strokeWidth: 3,
                    ),
                  )
                : _errorMessage != null
                ? _buildError()
                : _posts.isEmpty
                ? _buildEmpty(isDark, accent, textColor)
                : Column(
                    children: [
                      Expanded(
                        child: _buildPostsList(
                          isDark,
                          accent,
                          showDelete: _showMine,
                        ),
                      ),
                      _buildPaginationBar(isDark, accent),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildActionBar(Color accent, bool isDark) {
    final textMuted = isDark
        ? Colors.white.withValues(alpha: 0.40)
        : Colors.black.withValues(alpha: 0.38);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          // ── Toggle Todos / Mis posts ─────────────────────────────
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: accent.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildToggleTab(
                    label: 'Todos',
                    icon: Icons.forum_outlined,
                    isSelected: !_showMine,
                    accent: accent,
                    isDark: isDark,
                    textMuted: textMuted,
                    widgetKey: null,
                    onTap: () {
                      if (_showMine) {
                        setState(() {
                          _showMine = false;
                          _currentPage = 0;
                        });
                        _loadPosts(refresh: true);
                      }
                    },
                  ),
                  _buildToggleTab(
                    label: 'Mis posts',
                    icon: Icons.person_outline,
                    isSelected: _showMine,
                    accent: accent,
                    isDark: isDark,
                    textMuted: textMuted,
                    widgetKey: null,
                    onTap: () {
                      if (!_showMine) {
                        setState(() {
                          _showMine = true;
                          _currentPage = 0;
                        });
                        _loadPosts(refresh: true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Botón publicar ────────────────────────────────────────
          GestureDetector(
            onTap: _showCreatePostDialog,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: accent.withValues(alpha: 0.38),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.14),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: accent, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    'Publicar',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accent,
    required bool isDark,
    required Color textMuted,
    required Key? widgetKey,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        key: widgetKey,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: isDark ? 0.16 : 0.11)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? accent.withValues(alpha: 0.28)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? accent : textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? accent : textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForumSelector(bool isDark, Color accent) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        scrollDirection: Axis.horizontal,
        itemCount: _forums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final forum = _forums[index];
          final selected = forum.id == _selectedForumId;
          final bgColor = selected
              ? accent.withValues(alpha: isDark ? 0.14 : 0.10)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppConstants.lightSurfaceVariant);
          final borderColor = selected
              ? accent
              : accent.withValues(alpha: 0.18);
          final labelColor = selected
              ? accent
              : (isDark
                    ? Colors.white.withValues(alpha: 0.50)
                    : AppConstants.textLight.withValues(alpha: 0.50));

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _selectForum(forum),
              child: Ink(
                width: 82,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor,
                    width: selected ? 1.4 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.32),
                            blurRadius: 16,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: _buildForumLogo(forum, accent),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      forum.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: labelColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForumLogo(_ForumDescriptor forum, Color accent) {
    final asset = forum.logoAsset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        width: 68,
        height: 68,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.forum, color: accent, size: 28),
      );
    }

    final url = forum.logoUrl ?? '';
    final effective = _imageUrlForWeb(url);
    if (effective.isEmpty) {
      return Icon(Icons.casino, color: accent, size: 28);
    }

    return CachedNetworkImage(
      imageUrl: effective,
      width: 68,
      height: 68,
      fit: BoxFit.contain,
      placeholder: (_, __) => SizedBox(
        width: 68,
        height: 68,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Icon(Icons.casino, color: accent, size: 28),
    );
  }

  Widget _buildForumPlaceholder(
    bool isDark,
    Color accent,
    _ForumDescriptor forum,
  ) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.2), accent.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(Icons.forum_outlined, size: 64, color: accent),
            ),
            const SizedBox(height: 24),
            Text(
              'Foro de ${forum.label}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Estamos armando este foro. Muy pronto vas a poder participar y ver publicaciones por casino.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white70 : AppConstants.lightHintText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error desconocido',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPosts,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color accent, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [AppConstants.primaryGreen, Color(0xFF00E5FF)],
              ).createShader(r),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SIN PUBLICACIONES',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ThaleahFat',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Todavía no hay publicaciones.\nSé el primero en compartir algo con la comunidad.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(
    bool isDark,
    Color accent, {
    required bool showDelete,
  }) {
    return RefreshIndicator(
      onRefresh: () => _loadPosts(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _posts.length,
        itemBuilder: (context, index) => _PostCard(
          post: _posts[index],
          isDark: isDark,
          accent: accent,
          showDelete: showDelete,
          onDelete: _deletePost,
          onTap: () => _openPost(context, _posts[index].id),
        ),
      ),
    );
  }

  Future<void> _deletePost(int postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Publicación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta publicación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ForumService.deletePost(postId);
        _loadPosts(refresh: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildPaginationBar(bool isDark, Color accent) {
    // No mostrar paginación si no hay posts
    if (_posts.isEmpty) {
      return const SizedBox.shrink();
    }

    final lastIndex = _totalPages > 0 ? _totalPages - 1 : _currentPage;
    final canGoBack = _currentPage > 0;
    final canGoForward = _hasMore && _currentPage < lastIndex;
    final textColor = isDark ? AppConstants.textDark : AppConstants.textLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppConstants.lightAccent,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : AppConstants.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: PaginationBar(
          currentPage: _currentPage + 1,
          canGoPrevious: canGoBack,
          canGoNext: canGoForward,
          onPrev: _goToPreviousPage,
          onNext: _goToNextPage,
          primaryColor: accent,
          textColor: textColor,
        ),
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final double radius;
  final List<Color> borderGradient;
  final Color background;
  final String avatarUrl;
  final String fallbackLetter;
  final Color textColor;

  const _AvatarBubble({
    required this.radius,
    required this.borderGradient,
    required this.background,
    required this.avatarUrl,
    required this.fallbackLetter,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: borderGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: background,
        child: ClipOval(
          child: hasAvatar
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  key: ValueKey(avatarUrl),
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => _FallbackLetter(
                    letter: fallbackLetter,
                    color: textColor,
                    fontSize: radius,
                  ),
                )
              : _FallbackLetter(
                  letter: fallbackLetter,
                  color: textColor,
                  fontSize: radius,
                ),
        ),
      ),
    );
  }
}

class _FallbackLetter extends StatelessWidget {
  final String letter;
  final Color color;
  final double fontSize;

  const _FallbackLetter({
    required this.letter,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ForumPost post;
  final bool isDark;
  final Color accent;
  final Function(int) onDelete;
  final bool showDelete;
  final VoidCallback? onTap;

  const _PostCard({
    required this.post,
    required this.isDark,
    required this.accent,
    required this.onDelete,
    required this.showDelete,
    this.onTap,
  });

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Barra de acento izquierda ──────────────────────────
              Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent, accent.withValues(alpha: 0.15)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // ── Cuerpo de la card ──────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF141414)
                        : AppConstants.lightCardBg,
                    border: Border(
                      top: BorderSide(
                        color: accent.withValues(alpha: 0.10),
                        width: 1,
                      ),
                      right: BorderSide(
                        color: accent.withValues(alpha: 0.10),
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: accent.withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _AvatarBubble(
                                  radius: 18,
                                  borderGradient: [
                                    accent,
                                    accent.withValues(alpha: 0.5),
                                  ],
                                  background: isDark
                                      ? const Color(0xFF1A1A1A)
                                      : AppConstants.lightSurfaceVariant,
                                  avatarUrl: post.avatarUrl,
                                  fallbackLetter: post.username.isNotEmpty
                                      ? post.username[0].toUpperCase()
                                      : '?',
                                  textColor: accent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (post.parentId != null) ...[
                                        Text(
                                          '↩ Respuesta a #${post.parentId}',
                                          style: TextStyle(
                                            color: accent.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                      ],
                                      Text(
                                        post.username,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 11,
                                            color: textColor.withValues(
                                              alpha: 0.38,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(post.createdAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textColor.withValues(
                                                alpha: 0.45,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (showDelete)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.35,
                                        ),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 17,
                                      ),
                                      onPressed: () => onDelete(post.id),
                                      padding: const EdgeInsets.all(6),
                                      color: Colors.red.shade400,
                                      tooltip: 'Eliminar',
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 13,
                                  color: accent.withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              post.content,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.55,
                                color: textColor.withValues(alpha: 0.88),
                                letterSpacing: 0.1,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 13,
                                  color: accent.withValues(alpha: 0.55),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Ver publicación',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: accent.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatePostDialog extends StatefulWidget {
  final TextEditingController contentController;
  final Future<void> Function() onSubmit;

  const _CreatePostDialog({
    required this.contentController,
    required this.onSubmit,
  });

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    final accent = theme.colorScheme.primary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : AppConstants.lightDialogBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: 0.20),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.18),
                    accent.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: accent.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.32),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.create_rounded,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nueva Publicación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Compartí algo con la comunidad',
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor.withValues(alpha: 0.40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── TextField ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: TextField(
                controller: widget.contentController,
                decoration: InputDecoration(
                  hintText: '¿Qué querés compartir?',
                  hintStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.30),
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: accent.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: accent.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : AppConstants.lightInputBg,
                  contentPadding: const EdgeInsets.all(14),
                ),
                maxLines: 6,
                maxLength: 500,
                autofocus: true,
                enabled: !_isSubmitting,
              ),
            ),

            // ── Acciones ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(
                          color: accent.withValues(alpha: 0.35),
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 16,
                              color: Colors.black,
                            ),
                      label: Text(
                        _isSubmitting ? 'Publicando...' : 'Publicar',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
