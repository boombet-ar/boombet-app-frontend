import 'dart:convert';

import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/forum_models.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/forum_service.dart';
import 'package:boombet_app/views/pages/forum_post_detail_page.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
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
        cacheTtl: Duration.zero,
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
      _showMine = false;
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

  void _goToPage(int page) {
    final lastIndex = _totalPages > 0 ? _totalPages - 1 : null;
    if (_isLoading || page < 0) return;
    if (lastIndex != null && page > lastIndex) return;
    setState(() {
      _currentPage = page;
    });
    _loadPosts();
  }

  void _jumpBackPages(int pages) {
    final newPage = (_currentPage - pages).clamp(0, double.infinity).toInt();
    _goToPage(newPage);
  }

  void _jumpForwardPages(int pages) {
    if (!_hasMore && pages > 0) return;
    final lastIndex = _totalPages > 0 ? _totalPages - 1 : null;
    final target = lastIndex != null
        ? (_currentPage + pages).clamp(0, lastIndex)
        : _currentPage + pages;
    if (target == _currentPage) return;
    _goToPage(target);
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (!mounted) return;

    if (refresh) {
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
              )
            : await ForumService.getPosts(
                page: page,
                size: 10,
                casinoId: casinoGralId,
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
              )
            : await ForumService.getPosts(
                page: page,
                size: 10,
                casinoId: casinoGralId,
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
      body: Column(
        children: [
          _buildHeader(accent, isDark, textColor),
          _buildForumSelector(isDark, accent),
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
    );
  }

  Widget _buildHeader(Color accent, bool isDark, Color textColor) {
    final selectedForum = _selectedForum;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.15),
            accent.withOpacity(0.05),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.forum_rounded, color: accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedForum.label.isNotEmpty
                          ? 'Foro ${selectedForum.label}'
                          : 'Foro',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${_posts.length} ${_posts.length == 1 ? 'publicación' : 'publicaciones'}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppConstants.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: _showCreatePostDialog,
                  color: accent,
                  tooltip: 'Nueva publicación',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _showMine
                      ? accent.withOpacity(0.15)
                      : isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppConstants.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withOpacity(_showMine ? 0.6 : 0.15),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(_showMine ? Icons.person : Icons.person_outline),
                  onPressed: () {
                    setState(() {
                      _showMine = !_showMine;
                      _currentPage = 0;
                    });
                    _loadPosts(refresh: true);
                  },
                  color: accent,
                  tooltip: _showMine
                      ? 'Ver todas las publicaciones'
                      : 'Ver mis publicaciones',
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
      height: 94,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: _forums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final forum = _forums[index];
          final selected = forum.id == _selectedForumId;

          final bgColor = selected
              ? accent.withOpacity(isDark ? 0.18 : 0.14)
              : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : AppConstants.lightSurfaceVariant);
          final borderColor = selected
              ? accent.withOpacity(0.7)
              : accent.withOpacity(0.18);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _selectForum(forum),
              child: Ink(
                width: 92,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withOpacity(0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildForumLogo(forum, accent),
                  ),
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
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: accent,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '¡Comienza la conversación!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Todavía no hay publicaciones.\nSé el primero en compartir algo con la comunidad.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5, color: textColor),
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
    final canJumpBack5 = _currentPage >= 5;
    final canJumpBack10 = _currentPage >= 10;
    final canJumpForward5 = _totalPages > 0 && _currentPage + 5 <= lastIndex;
    final canJumpForward10 = _totalPages > 0 && _currentPage + 10 <= lastIndex;
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
          canJumpBack5: canJumpBack5,
          canJumpBack10: canJumpBack10,
          canJumpForward: canJumpForward5,
          onPrev: _goToPreviousPage,
          onNext: _goToNextPage,
          onJumpBack5: () => _jumpBackPages(5),
          onJumpBack10: () => _jumpBackPages(10),
          onJumpForward5: () => _jumpForwardPages(5),
          onJumpForward10: () => _jumpForwardPages(10),
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

  const _PostCard({
    required this.post,
    required this.isDark,
    required this.accent,
    required this.onDelete,
    required this.showDelete,
  });

  String _formatDate(DateTime date) {
    // Mostrar fecha/hora exacta según viene del backend
    final local = date.toLocal();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF121212), const Color(0xFF161616)]
              : [AppConstants.lightCardBg, AppConstants.lightSurfaceVariant],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: accent.withOpacity(isDark ? 0.2 : 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumPostDetailPage(postId: post.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AvatarBubble(
                      radius: 20,
                      borderGradient: [accent, accent.withOpacity(0.6)],
                      background: isDark
                          ? const Color(0xFF1A1A1A)
                          : AppConstants.lightSurfaceVariant,
                      avatarUrl: post.avatarUrl,
                      fallbackLetter: post.username.isNotEmpty
                          ? post.username[0].toUpperCase()
                          : '?',
                      textColor: accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (post.parentId != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Respuesta a #${post.parentId}',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            post.username,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(post.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showDelete)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
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
                      size: 16,
                      color: accent.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : AppConstants.lightDialogBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.create_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Nueva Publicación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: widget.contentController,
                decoration: InputDecoration(
                  labelText: 'Contenido',
                  hintText: '¿Qué quieres compartir con la comunidad?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.03)
                      : AppConstants.lightInputBg,
                ),
                maxLines: 6,
                maxLength: 500,
                autofocus: true,
                enabled: !_isSubmitting,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'Publicando...' : 'Publicar',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      backgroundColor: theme.colorScheme.primary,
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
