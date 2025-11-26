import 'dart:async';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/affiliation_result.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/views/pages/affiliation_results_page.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

/// Página de inicio limitada que se muestra durante el proceso de afiliación
/// Escucha el WebSocket para detectar cuando la afiliación se completa
/// Mantiene un timer de 45 segundos como fallback
class LimitedHomePage extends StatefulWidget {
  final AffiliationService affiliationService;

  const LimitedHomePage({super.key, required this.affiliationService});

  @override
  State<LimitedHomePage> createState() => _LimitedHomePageState();
}

class _LimitedHomePageState extends State<LimitedHomePage> {
  StreamSubscription? _wsSubscription;
  bool _affiliationCompleted = false;
  String _statusMessage = 'Iniciando proceso de afiliación...';

  @override
  void initState() {
    super.initState();
    // Resetear a la página de Home cuando se carga
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectedPageNotifier.value = 0;
    });

    // Escuchar mensajes del WebSocket
    _wsSubscription = widget.affiliationService.messageStream.listen(
      (message) {
        if (!mounted || _affiliationCompleted) return;

        print('[LimitedHomePage] 📩 Mensaje recibido del WebSocket');
        print('[LimitedHomePage] Contenido: $message');

        // Verificar si el mensaje contiene playerData y responses
        if (message.containsKey('playerData') &&
            message.containsKey('responses')) {
          print('[LimitedHomePage] ✅ Mensaje completo de afiliación recibido');
          _affiliationCompleted = true;

          // Parsear el resultado
          try {
            final result = AffiliationResult.fromJson(message);
            _navigateToResultsPage(result);
          } catch (e) {
            print('[LimitedHomePage] ❌ Error parseando resultado: $e');
            // Si hay error parseando, navegar igual pero sin resultados
            _navigateToResultsPage(null);
          }
        } else {
          // Actualizar mensaje de estado si viene en el WebSocket
          if (message.containsKey('status')) {
            setState(() {
              _statusMessage = message['status'] as String;
            });
          }
        }
      },
      onError: (error) {
        print('[LimitedHomePage] ❌ Error en WebSocket: $error');
        if (mounted) {
          setState(() {
            _statusMessage = 'Error en la conexión. Reintentando...';
          });
        }
      },
    );
  }

  void _navigateToResultsPage(AffiliationResult? result) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AffiliationResultsPage(result: result),
        ),
      );
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    widget.affiliationService.closeWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return Scaffold(
          // AppBar sin configuración ni perfil
          appBar: const MainAppBar(
            showSettings: false,
            showLogo: true,
            showProfileButton: false,
            showLogoutButton: true,
            showExitButton: false,
          ),
          body: IndexedStack(
            index: selectedPage,
            children: [
              LimitedHomeContent(statusMessage: _statusMessage),
              const LimitedPointsContent(),
              const LimitedDiscountsContent(),
              const LimitedRafflesContent(),
              const LimitedForumContent(), // Foro limitado sin publicar
            ],
          ),
          bottomNavigationBar: const NavbarWidget(),
        );
      },
    );
  }
}

/// Contenido limitado del Home - Sin carrusel
class LimitedHomeContent extends StatelessWidget {
  final String statusMessage;

  const LimitedHomeContent({super.key, required this.statusMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Banner de afiliación en proceso
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryGreen.withOpacity(0.2),
                  primaryGreen.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryGreen.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: primaryGreen, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Afiliación en proceso',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFE0E0E0),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Mensaje de bienvenida
          Text(
            '¡Bienvenido a BoomBet!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estamos preparando todo para que disfrutes de la mejor experiencia.',
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 30),

          // Información de funciones próximas
          _buildFeatureCard(
            context,
            Icons.stars,
            'Programa de Puntos',
            'Acumula puntos en cada apuesta y canjéalos por premios exclusivos.',
            isDark,
            primaryGreen,
            textColor,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            Icons.local_offer,
            'Descuentos Exclusivos',
            'Accede a ofertas especiales en comercios afiliados.',
            isDark,
            primaryGreen,
            textColor,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            Icons.card_giftcard,
            'Sorteos y Premios',
            'Participa en sorteos mensuales y gana increíbles premios.',
            isDark,
            primaryGreen,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    bool isDark,
    Color primaryGreen,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryGreen, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withOpacity(0.6),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenido limitado de Puntos - Bloqueado
class LimitedPointsContent extends StatelessWidget {
  const LimitedPointsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildLockedContent(
      context,
      Icons.stars,
      'Puntos',
      'El programa de puntos estará disponible una vez completada tu afiliación.',
    );
  }
}

/// Contenido limitado de Descuentos - Bloqueado
class LimitedDiscountsContent extends StatelessWidget {
  const LimitedDiscountsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildLockedContent(
      context,
      Icons.local_offer,
      'Descuentos',
      'Los descuentos exclusivos estarán disponibles una vez completada tu afiliación.',
    );
  }
}

/// Contenido limitado de Sorteos - Bloqueado
class LimitedRafflesContent extends StatelessWidget {
  const LimitedRafflesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildLockedContent(
      context,
      Icons.card_giftcard,
      'Sorteos',
      'Podrás participar en sorteos una vez completada tu afiliación.',
    );
  }
}

/// Widget reutilizable para mostrar contenido bloqueado
Widget _buildLockedContent(
  BuildContext context,
  IconData icon,
  String title,
  String message,
) {
  final theme = Theme.of(context);
  final textColor = theme.colorScheme.onSurface;
  final primaryGreen = theme.colorScheme.primary;
  final isDark = theme.brightness == Brightness.dark;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              border: Border.all(
                color: primaryGreen.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, size: 64, color: textColor.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.lock_outline,
            size: 48,
            color: primaryGreen.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: textColor.withOpacity(0.6),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: primaryGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_empty, color: primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Afiliación en proceso...',
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryGreen,
                    fontWeight: FontWeight.w600,
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

/// Contenido limitado del Foro - No permite publicar
class LimitedForumContent extends StatelessWidget {
  const LimitedForumContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE0E0E0) : Colors.black87;
    final greenColor = theme.colorScheme.primary;

    // Posts de ejemplo (solo lectura)
    final posts = [
      _ForumPost(
        username: 'JugadorPro',
        content:
            '¡Acabo de ganar en el casino! 🎰 ¿Alguien tiene tips para blackjack?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 15,
        replies: 3,
      ),
      _ForumPost(
        username: 'ApostadorExperto',
        content: '¿Cuál es su estrategia favorita para apuestas deportivas?',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        likes: 8,
        replies: 12,
      ),
      _ForumPost(
        username: 'CasinoFan',
        content: 'Las slots están on fire hoy 🔥 ¡Buena suerte a todos!',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        likes: 23,
        replies: 7,
      ),
    ];

    return ResponsiveWrapper(
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
          children: [
            // Header con mensaje de restricción
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                  // Mensaje de restricción
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: greenColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: greenColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_empty, color: greenColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Podrás publicar una vez completada tu afiliación',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de publicaciones (solo lectura)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
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
    );
  }

  Widget _buildForumPostCard(
    _ForumPost post,
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
            color: Colors.black.withOpacity(0.1),
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
                  backgroundColor: greenColor.withOpacity(0.2),
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
                          color: textColor.withOpacity(0.6),
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

            // Botones de interacción (deshabilitados)
            Row(
              children: [
                _buildDisabledActionButton(
                  Icons.thumb_up_outlined,
                  '${post.likes}',
                  textColor,
                ),
                const SizedBox(width: 16),
                _buildDisabledActionButton(
                  Icons.comment_outlined,
                  '${post.replies}',
                  textColor,
                ),
                const SizedBox(width: 16),
                _buildDisabledActionButton(
                  Icons.share_outlined,
                  'Compartir',
                  textColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledActionButton(
    IconData icon,
    String label,
    Color textColor,
  ) {
    return Opacity(
      opacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.5)),
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

/// Modelo simple para posts del foro limitado
class _ForumPost {
  final String username;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int replies;

  _ForumPost({
    required this.username,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.replies,
  });
}
