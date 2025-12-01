import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  bool _isLoggedIn = false;
  final _postController = TextEditingController();
  final List<ForumPost> _posts = [
    ForumPost(
      username: 'JugadorPro',
      content:
          '¡Acabo de ganar en el casino! 🎰 ¿Alguien tiene tips para blackjack?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 15,
      replies: 3,
    ),
    ForumPost(
      username: 'ApostadorExperto',
      content: '¿Cuál es su estrategia favorita para apuestas deportivas?',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      likes: 8,
      replies: 12,
    ),
    ForumPost(
      username: 'CasinoFan',
      content: 'Las slots están on fire hoy 🔥 ¡Buena suerte a todos!',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      likes: 23,
      replies: 7,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final isValid = await TokenService.isTokenValid();
    if (mounted) {
      setState(() {
        _isLoggedIn = isValid;
      });
    }
  }

  void _createPost() {
    if (_postController.text.trim().isEmpty) return;

    setState(() {
      _posts.insert(
        0,
        ForumPost(
          username: 'Tú',
          content: _postController.text.trim(),
          timestamp: DateTime.now(),
          likes: 0,
          replies: 0,
        ),
      );
    });

    _postController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Publicación creada exitosamente!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.darkBg : AppConstants.lightBg;
    final cardColor = isDark
        ? AppConstants.darkCardBg
        : AppConstants.lightCardBg;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;
    final greenColor = theme.colorScheme.primary;

    return ResponsiveWrapper(
      maxWidth: 900,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: bgColor,
          body: Column(
            children: [
              // Área de crear publicación
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.forum, color: greenColor, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Foro de la Comunidad',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_isLoggedIn) ...[
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppConstants.darkAccent
                              : AppConstants.lightDivider,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade400,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: textColor.withValues(alpha: 0.5)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Inicia sesión para publicar',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenColor,
                                foregroundColor: AppConstants.lightCardBg,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text('Iniciar sesión'),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: greenColor,
                            child: Icon(
                              Icons.person,
                              color: isDark
                                  ? AppConstants.darkBg
                                  : AppConstants.lightCardBg,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Semantics(
                              label: 'Campo para crear publicación',
                              hint:
                                  'Escribe qué deseas compartir con la comunidad',
                              child: TextField(
                                controller: _postController,
                                maxLines: 3,
                                maxLength: 500,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  hintText:
                                      '¿Qué quieres compartir con la comunidad?',
                                  hintStyle: TextStyle(
                                    color: textColor.withValues(alpha: 0.5),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? AppConstants.darkCardBg
                                      : AppConstants.lightInputBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? AppConstants.borderDark
                                          : AppConstants.lightInputBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? AppConstants.borderDark
                                          : AppConstants.lightInputBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: greenColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _createPost,
                          icon: const Icon(Icons.send),
                          label: const Text('Publicar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenColor,
                            foregroundColor: isDark
                                ? Colors.black
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Lista de publicaciones
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return _buildForumPostCard(
                      post,
                      cardColor,
                      textColor,
                      greenColor,
                      isDark,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForumPostCard(
    ForumPost post,
    Color cardColor,
    Color textColor,
    Color greenColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con avatar y username
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: greenColor.withValues(alpha: 0.2),
                  child: Text(
                    post.username[0].toUpperCase(),
                    style: TextStyle(
                      color: greenColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        _formatTimestamp(post.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Contenido del post
            Text(
              post.content,
              style: TextStyle(fontSize: 15, color: textColor, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Botones de interacción
            Row(
              children: [
                _buildActionButton(
                  Icons.thumb_up_outlined,
                  '${post.likes}',
                  greenColor,
                  textColor,
                  isDark,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  Icons.comment_outlined,
                  '${post.replies}',
                  greenColor,
                  textColor,
                  isDark,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  Icons.share_outlined,
                  'Compartir',
                  greenColor,
                  textColor,
                  isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color greenColor,
    Color textColor,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Función de $label en desarrollo'),
            duration: AppConstants.snackbarDuration,
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class ForumPost {
  final String username;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int replies;

  ForumPost({
    required this.username,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.replies,
  });
}
