import 'package:boombet_app/models/forum_models.dart';
import 'package:boombet_app/services/forum_service.dart';
import 'package:boombet_app/views/pages/forum_post_detail_page.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
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
    _loadPosts();
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
        response = _showMine
            ? await ForumService.getMyPosts(page: page, size: 10)
            : await ForumService.getPosts(page: page, size: 10);

        if (!mounted) return;

        parsedContent = _showMine
            ? response
                  .content // incluir también respuestas propias
            : response.content.where((p) => p.parentId == null).toList();

        if (parsedContent.isEmpty && !response.last) {
          page++;
          continue;
        }
        break;
      }

      // Si la última página está vacía, intentar retroceder hasta hallar datos
      while (parsedContent.isEmpty && page > 0) {
        page--;
        response = _showMine
            ? await ForumService.getMyPosts(page: page, size: 10)
            : await ForumService.getPosts(page: page, size: 10);

        if (!mounted) return;

        parsedContent = _showMine
            ? response.content
            : response.content.where((p) => p.parentId == null).toList();

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
            await ForumService.createPost(CreatePostRequest(content: content));
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

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(accent, isDark),
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
                ? _buildEmpty(isDark, accent)
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

  Widget _buildHeader(Color accent, bool isDark) {
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
                      'Foro BoomBet',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
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
                              color: (isDark ? Colors.white : Colors.black87)
                                  .withOpacity(0.6),
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
                      : Colors.black.withOpacity(0.03),
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
                      : Colors.black.withOpacity(0.03),
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

  Widget _buildEmpty(bool isDark, Color accent) {
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
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Todavía no hay publicaciones.\nSé el primero en compartir algo con la comunidad.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: (isDark ? Colors.white : Colors.black87).withOpacity(
                  0.6,
                ),
              ),
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
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
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
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: isDark ? 8 : 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? accent.withOpacity(0.15)
              : Colors.black.withOpacity(0.05),
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
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                        child: Text(
                          post.username[0].toUpperCase(),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: (isDark ? Colors.white : Colors.black87)
                                    .withOpacity(0.4),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(post.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      (isDark ? Colors.white : Colors.black87)
                                          .withOpacity(0.5),
                                ),
                              ),
                            ],
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
                    color: (isDark ? Colors.white : Colors.black87).withOpacity(
                      0.85,
                    ),
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

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                      color: isDark ? Colors.white : Colors.black87,
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
                      : Colors.black.withOpacity(0.02),
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
