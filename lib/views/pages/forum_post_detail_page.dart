import 'package:boombet_app/models/forum_models.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/forum_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ForumPostDetailPage extends StatefulWidget {
  final int postId;

  /// Si es true, fuerza recarga desde backend evitando caché.
  /// Útil cuando se abre desde una notificación y podría faltar la respuesta más reciente.
  final bool forceRefresh;

  const ForumPostDetailPage({
    super.key,
    required this.postId,
    this.forceRefresh = false,
  });

  @override
  State<ForumPostDetailPage> createState() => _ForumPostDetailPageState();
}

class _ForumPostDetailPageState extends State<ForumPostDetailPage> {
  ForumPost? _post;
  List<ForumPost> _replies = [];
  bool _isLoading = true;
  bool _isSubmittingReply = false;
  String? _errorMessage;
  final _replyController = TextEditingController();
  String? _currentUsername;
  int _repliesPage = 0;
  bool _hasMoreReplies = true;

  @override
  void initState() {
    super.initState();
    _loadData(forceRefresh: widget.forceRefresh);
    _loadCurrentUsername();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUsername() async {
    final payload = await TokenService.getTokenData();
    if (payload != null && mounted) {
      setState(() => _currentUsername = payload['username'] as String?);
    }
  }

  void _goToNextRepliesPage() {
    if (!_hasMoreReplies || _isLoading) return;
    setState(() {
      _repliesPage++;
    });
    _loadReplies();
  }

  void _goToPreviousRepliesPage() {
    if (_repliesPage == 0 || _isLoading) return;
    setState(() {
      _repliesPage--;
    });
    _loadReplies();
  }

  Future<void> _loadReplies({bool forceRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (forceRefresh) {
        // Evitar servir respuestas viejas desde cache.
        // Esto aplica especialmente cuando entramos desde push.
        // Se fuerza la recarga mediante bypassCache en el service.
      }
      print(
        '🔄 [DetailPage] Loading replies page $_repliesPage for ${widget.postId}...',
      );
      final response = await ForumService.getReplies(
        widget.postId,
        page: _repliesPage,
        size: 10,
        bypassCache: forceRefresh,
      );
      print('✅ [DetailPage] Replies loaded: ${response.length} replies');

      if (!mounted) return;
      setState(() {
        _replies = response;
        _hasMoreReplies = response.length >= 10;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [DetailPage] Error loading replies: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar respuestas';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (forceRefresh) {
        // Se fuerza la recarga mediante bypassCache en el service.
      }
      print('🔄 [DetailPage] Loading post ${widget.postId}...');
      final post = await ForumService.getPostById(
        widget.postId,
        bypassCache: forceRefresh,
      );
      print('✅ [DetailPage] Post loaded: ${post.id} - ${post.username}');

      if (!mounted) return;
      setState(() {
        _post = post;
        _isLoading = false;
      });
      print('✅ [DetailPage] Post UI updated successfully');

      // Load replies with pagination
      await _loadReplies(forceRefresh: forceRefresh);
    } catch (e, stackTrace) {
      print('❌ [DetailPage] Error loading data: $e');
      print('📋 [DetailPage] Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar la publicación: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReply() async {
    if (_isSubmittingReply) return;
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmittingReply = true);
    try {
      print('📝 [DetailPage] Submitting reply with parentId: ${widget.postId}');
      final newReply = await ForumService.createPost(
        CreatePostRequest(content: content, parentId: widget.postId),
      );
      print('✅ [DetailPage] Reply created successfully: ${newReply.id}');

      _replyController.clear();
      FocusScope.of(context).unfocus();

      print('🔄 [DetailPage] Reloading data...');
      await _loadData();
      print('✅ [DetailPage] Data reloaded');
    } catch (e) {
      print('❌ [DetailPage] Error submitting reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingReply = false);
      }
    }
  }

  Future<void> _deletePost() async {
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
        await ForumService.deletePost(widget.postId);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _deleteReply(int replyId) async {
    try {
      await ForumService.deletePost(replyId);
      _loadData(forceRefresh: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : AppConstants.lightBg,
      appBar: AppBar(
        title: const Text(
          'Publicación',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark
            ? const Color(0xFF1A1A1A)
            : AppConstants.lightAccent,
        elevation: 0,
        actions: const [],
      ),
      body: ResponsiveWrapper(
        maxWidth: 1200,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: accent, strokeWidth: 3),
              )
            : _errorMessage != null
            ? _buildError()
            : _buildContent(isDark, accent),
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
          Text(_errorMessage ?? 'Error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, Color accent) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPostCard(isDark, accent),
              const SizedBox(height: 24),
              _buildRepliesHeader(isDark, accent),
              const SizedBox(height: 12),
              ..._replies.map(
                (reply) => _buildReplyCard(reply, isDark, accent),
              ),
              if (_replies.isNotEmpty) const SizedBox(height: 16),
              if (_replies.isNotEmpty)
                _buildRepliesPaginationBar(isDark, accent),
            ],
          ),
        ),
        _buildReplyInput(isDark, accent),
      ],
    );
  }

  Widget _buildPostCard(bool isDark, Color accent) {
    if (_post == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF121212), const Color(0xFF171717)]
              : [AppConstants.lightCardBg, AppConstants.lightSurfaceVariant],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: accent.withOpacity(0.18), width: 1.4),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarBubble(
                radius: 24,
                borderGradient: [accent, accent.withOpacity(0.6)],
                background: isDark
                    ? const Color(0xFF1A1A1A)
                    : AppConstants.lightSurfaceVariant,
                avatarUrl: _post?.avatarUrl ?? '',
                fallbackLetter: _post?.username.isNotEmpty == true
                    ? _post!.username[0].toUpperCase()
                    : '?',
                textColor: accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _post!.username,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: isDark ? Colors.white : AppConstants.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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
                            size: 14,
                            color: accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'yyyy-MM-dd HH:mm:ss',
                            ).format(_post!.createdAt.toLocal()),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white.withOpacity(0.82)
                                  : AppConstants.textLight.withOpacity(0.76),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _post!.content,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              letterSpacing: 0.2,
              color: isDark
                  ? Colors.white.withOpacity(0.9)
                  : AppConstants.textLight.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesHeader(bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.chat_bubble_rounded, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            '${_replies.length} ${_replies.length == 1 ? 'Respuesta' : 'Respuestas'}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppConstants.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(ForumPost reply, bool isDark, Color accent) {
    final currentUser = _currentUsername?.trim().toLowerCase();
    final replyUser = reply.username.trim().toLowerCase();
    final isOwnReply = currentUser != null && currentUser.isNotEmpty
        ? replyUser == currentUser
        : false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF141414), const Color(0xFF1B1B1B)]
              : [AppConstants.lightCardBg, AppConstants.lightSurfaceVariant],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: accent.withOpacity(isDark ? 0.18 : 0.14),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarBubble(
                radius: 18,
                borderGradient: [accent.withOpacity(0.4), accent],
                background: isDark
                    ? const Color(0xFF1A1A1A)
                    : AppConstants.lightSurfaceVariant,
                avatarUrl: reply.avatarUrl,
                fallbackLetter: reply.username.isNotEmpty
                    ? reply.username[0].toUpperCase()
                    : '?',
                textColor: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.username,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppConstants.textLight,
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat(
                              'yyyy-MM-dd HH:mm:ss',
                            ).format(reply.createdAt.toLocal()),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white.withOpacity(0.75)
                                  : AppConstants.textLight.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwnReply)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    onPressed: () => _deleteReply(reply.id),
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.shade400,
                    tooltip: 'Eliminar respuesta',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reply.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              letterSpacing: 0.1,
              color: isDark
                  ? Colors.white.withOpacity(0.85)
                  : AppConstants.textLight.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput(bool isDark, Color accent) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : AppConstants.lightCardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppConstants.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withOpacity(0.2), width: 1),
                ),
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: 'Escribe una respuesta...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  maxLines: null,
                  maxLength: 500,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitReply(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _isSubmittingReply ? null : _submitReply,
                icon: _isSubmittingReply
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: isDark ? Colors.white : AppConstants.textLight,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 22),
                color: isDark ? Colors.white : AppConstants.textLight,
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliesPaginationBar(bool isDark, Color accent) {
    final canGoBack = _repliesPage > 0;
    final canGoForward = _hasMoreReplies;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppConstants.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: canGoBack ? _goToPreviousRepliesPage : null,
            icon: const Icon(Icons.chevron_left),
            color: canGoBack ? accent : Colors.grey,
            tooltip: 'Respuestas anteriores',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Página ${_repliesPage + 1}',
              style: TextStyle(fontWeight: FontWeight.w600, color: accent),
            ),
          ),
          IconButton(
            onPressed: canGoForward ? _goToNextRepliesPage : null,
            icon: const Icon(Icons.chevron_right),
            color: canGoForward ? accent : Colors.grey,
            tooltip: 'Más respuestas',
          ),
        ],
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
      padding: const EdgeInsets.all(3),
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
