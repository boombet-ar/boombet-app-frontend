import 'dart:async';
import 'dart:ui';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/games/game_01/game_01_page.dart';
import 'package:boombet_app/games/game_02/game_02_page.dart';
import 'package:boombet_app/models/affiliation_result.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:go_router/go_router.dart';
import 'package:boombet_app/views/pages/other/qr_scanner_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';

/// Página de inicio limitada que se muestra durante el proceso de afiliación
/// Escucha el WebSocket para detectar cuando la afiliación se completa
/// Mantiene un timer de 45 segundos como fallback
class LimitedHomePage extends StatefulWidget {
  final AffiliationService affiliationService;
  final bool preview;
  final String? previewStatusMessage;
  final String? wsUrl;

  const LimitedHomePage({
    super.key,
    required this.affiliationService,
    this.preview = false,
    this.previewStatusMessage,
    this.wsUrl,
  });

  @override
  State<LimitedHomePage> createState() => _LimitedHomePageState();
}

class _LimitedHomePageState extends State<LimitedHomePage> {
  StreamSubscription? _wsSubscription;
  bool _affiliationCompleted = false;
  String _statusMessage = 'Iniciando proceso de afiliación...';
  bool _isGameOpen = false;
  bool _wsRestored = false;

  static const _limitedGameRouteName = '/limited/game';

  @override
  void initState() {
    super.initState();
    // Resetear a la página de Home cuando se carga
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb || !selectedPageWasRestored) {
        saveSelectedPage(0);
      }
    });

    if (!widget.preview) {
      saveAffiliationFlowRoute('/limited-home');
      criticalFlowActive = true;
    }

    // // Timer de 15 segundos para mostrar resultados
    // Future.delayed(const Duration(seconds: 15), () {
    //   if (mounted && !_affiliationCompleted) {
    //     _affiliationCompleted = true;
    //     _navigateToResultsPage(null);
    //   }
    // });

    if (widget.preview) {
      final message = widget.previewStatusMessage;
      if (message != null && message.trim().isNotEmpty) {
        _statusMessage = message;
      }
      return;
    }

    _restoreWebSocketIfNeeded();

    // Escuchar mensajes del WebSocket
    _wsSubscription = widget.affiliationService.messageStream.listen(
      (message) {
        if (!mounted || _affiliationCompleted) return;

        // Verificar si el mensaje contiene playerData y responses
        if (message.containsKey('playerData') &&
            message.containsKey('responses')) {
          _affiliationCompleted = true;

          // Parsear el resultado
          try {
            final result = AffiliationResult.fromJson(message);
            _navigateToResultsPage(result);
          } catch (e) {
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
        if (mounted) {
          setState(() {
            _statusMessage = 'Error en la conexión. Reintentando...';
          });
        }
      },
    );
  }

  Future<void> _restoreWebSocketIfNeeded() async {
    if (_wsRestored) return;
    _wsRestored = true;

    final wsUrl = widget.wsUrl ?? await loadAffiliationWsUrl();
    if (wsUrl == null || wsUrl.trim().isEmpty) return;

    await widget.affiliationService.connectToWebSocket(wsUrl: wsUrl, token: '');
  }

  Future<void> _closeGameIfOpen() async {
    if (!_isGameOpen || !mounted) return;

    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.settings.name != _limitedGameRouteName);
    _isGameOpen = false;
  }

  Future<void> _navigateToResultsPage(AffiliationResult? result) async {
    if (!mounted) return;

    await _closeGameIfOpen();
    if (!mounted) return;

    if (context.mounted) context.go('/affiliation-results', extra: result);
  }

  Future<void> _openLimitedGame(WidgetBuilder builder) async {
    if (widget.preview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview: juegos deshabilitados (solo visual).'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_affiliationCompleted || !mounted) return;

    setState(() {
      _isGameOpen = true;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: _limitedGameRouteName),
        builder: builder,
      ),
    );

    if (mounted) {
      setState(() {
        _isGameOpen = false;
      });
    }
  }

  @override
  void dispose() {
    criticalFlowActive = false;
    _wsSubscription?.cancel();
    widget.affiliationService.closeWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        final safeIndex = selectedPage.clamp(0, 5);
        return Scaffold(
          body: ResponsiveWrapper(
            maxWidth: 1200,
            child: IndexedStack(
              index: safeIndex,
              children: [
                LimitedHomeContent(statusMessage: _statusMessage),
                const LimitedDiscountsContent(),
                const LimitedRafflesContent(),
                const LimitedForumContent(), // Foro limitado sin publicar
                LimitedGamesContent(onPlay: _openLimitedGame),
                const QrScannerPage(),
              ],
            ),
          ),
          bottomNavigationBar: NavbarWidget(
            showCasinos: false,
            hiddenIndexes: [6, 7],
            onTabTap: (index) {
              selectedPageNotifier.value = index;
            },
          ),
        );
      },
    );
  }
}

/// Contenido limitado del Home - Sin carrusel
class LimitedHomeContent extends StatelessWidget {
  final String statusMessage;

  const LimitedHomeContent({super.key, required this.statusMessage});

  static const List<_LimitedHomeBenefit> _benefits = [
    _LimitedHomeBenefit(
      Icons.stars,
      'Programa de Puntos',
      'Sumá puntos en tus apuestas y canjealos por beneficios exclusivos.',
    ),
    _LimitedHomeBenefit(
      Icons.local_offer,
      'Descuentos y Cupones',
      'Accedé a descuentos en comercios afiliados y promos especiales.',
    ),
    _LimitedHomeBenefit(
      Icons.card_giftcard,
      'Sorteos y Premios',
      'Participá en sorteos periódicos y ganá premios increíbles.',
    ),
    _LimitedHomeBenefit(
      Icons.sports_esports,
      'Juegos',
      'Minijuegos y experiencias rápidas mientras avanzás en la app.',
    ),
    _LimitedHomeBenefit(
      Icons.forum,
      'Foro y Comunidad',
      'Interactuá, compartí y enterate de novedades con la comunidad.',
    ),
    _LimitedHomeBenefit(
      Icons.verified_user,
      'Cuenta y Seguridad',
      'Verificación y controles para mantener tu cuenta protegida.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final progressBanner = _buildAffiliationProgressBanner(
      context,
      statusMessage: statusMessage,
      primaryGreen: primaryGreen,
      textColor: textColor,
      isDark: isDark,
    );

    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrowWeb = constraints.maxWidth < 900;

          if (isNarrowWeb) {
            // En web angosto (mobile browsers) usamos el layout vertical (tipo mobile)
            // para evitar overflows del layout en 2 columnas.
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        progressBanner,
                        const SizedBox(height: 22),
                        _buildWelcomeAndFeatures(
                          context,
                          isDark: isDark,
                          primaryGreen: primaryGreen,
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Desktop web: mantener 2 columnas con "squares".
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 720,
                                maxHeight: 460,
                              ),
                              child: AspectRatio(
                                aspectRatio: 1.35,
                                child: _buildWelcomeSquare(
                                  context,
                                  isDark: isDark,
                                  primaryGreen: primaryGreen,
                                  textColor: textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 560,
                                maxHeight: 380,
                              ),
                              child: AspectRatio(
                                aspectRatio: 1.55,
                                child: _buildProgressSquare(
                                  context,
                                  statusMessage: statusMessage,
                                  primaryGreen: primaryGreen,
                                  textColor: textColor,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner de afiliación en proceso
                progressBanner,
                const SizedBox(height: 26),
                _buildWelcomeAndFeatures(
                  context,
                  isDark: isDark,
                  primaryGreen: primaryGreen,
                  textColor: textColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeAndFeatures(
    BuildContext context, {
    required bool isDark,
    required Color primaryGreen,
    required Color textColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final maxWidth = constraints.maxWidth;
        const int columns = 3;
        final rawTileSize = (maxWidth - (gap * (columns - 1))) / columns;
        final tileSize = rawTileSize.clamp(92.0, 132.0).toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.20),
                  width: 0.8,
                ),
              ),
              child: Text(
                'BIENVENIDO',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: primaryGreen,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Bienvenido a BoomBet!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: textColor,
                height: 1.15,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Estamos preparando todo para que disfrutes de la mejor experiencia.',
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.52),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final benefit in _benefits)
                  SizedBox(
                    width: tileSize,
                    height: tileSize,
                    child: _buildFeatureSquareCard(
                      icon: benefit.icon,
                      title: benefit.title,
                      isDark: isDark,
                      primaryGreen: primaryGreen,
                      textColor: textColor,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeSquare(
    BuildContext context, {
    required bool isDark,
    required Color primaryGreen,
    required Color textColor,
  }) {
    final muted = textColor.withValues(alpha: 0.58);

    Widget benefitRow({
      required IconData icon,
      required String title,
      required String description,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryGreen.withValues(alpha: 0.12),
            width: 0.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.20),
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: primaryGreen, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: muted, height: 1.25),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryGreen.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.20),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'BIENVENIDO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: primaryGreen,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¡Bienvenido a BoomBet!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mientras se completa tu afiliación, conocé lo que vas a poder hacer:',
                  style: TextStyle(fontSize: 12, color: muted, height: 1.35),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (int i = 0; i < _benefits.length; i++) ...[
                            benefitRow(
                              icon: _benefits[i].icon,
                              title: _benefits[i].title,
                              description: _benefits[i].description,
                            ),
                            if (i != _benefits.length - 1)
                              const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffiliationProgressBanner(
    BuildContext context, {
    required String statusMessage,
    required Color primaryGreen,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.26),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.09),
            blurRadius: 22,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryGreen.withValues(alpha: 0.11),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryGreen.withValues(alpha: 0.24),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        color: primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Afiliación en proceso',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: primaryGreen,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'EN CURSO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: primaryGreen.withValues(alpha: 0.75),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.65),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : AppConstants.lightAccent,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSquare(
    BuildContext context, {
    required String statusMessage,
    required Color primaryGreen,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.26),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryGreen.withValues(alpha: 0.09),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.26),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    color: primaryGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'EN PROCESO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: primaryGreen.withValues(alpha: 0.75),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Afiliación en proceso',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryGreen,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  statusMessage,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.62),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : AppConstants.lightAccent,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSquareCard({
    required IconData icon,
    required String title,
    required bool isDark,
    required Color primaryGreen,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : AppConstants.lightCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.14),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.20),
                width: 0.8,
              ),
            ),
            child: Icon(icon, color: primaryGreen, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitedHomeBenefit {
  final IconData icon;
  final String title;
  final String description;

  const _LimitedHomeBenefit(this.icon, this.title, this.description);
}

/// Contenido limitado de Reclamados - Bloqueado
class LimitedClaimedContent extends StatelessWidget {
  const LimitedClaimedContent({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildLockedContent(
      context,
      Icons.check_circle_outline,
      'Reclamados',
      'Tus cupones reclamados se mostrarán aquí al completar la afiliación.',
    );
  }
}

/// Contenido limitado de Descuentos con mock de cupones (solo lectura)
class LimitedDiscountsContent extends StatefulWidget {
  const LimitedDiscountsContent({super.key});

  @override
  State<LimitedDiscountsContent> createState() =>
      _LimitedDiscountsContentState();
}

class _LimitedDiscountsContentState extends State<LimitedDiscountsContent> {
  final List<Cupon> _cupones = [];
  bool _loading = true;
  String? _error;
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMockCupones();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  void _loadMockCupones() {
    try {
      final empresaA = Empresa(
        id: '6071',
        nombre: 'Bonda Seguros',
        logoThumbnail: {
          'original':
              'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/coupons/693865920dc02.png',
          '90x90':
              'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/partners/6926f5486dbd5.png',
        },
        descripcion:
            '<p>En Bonda Seguros trabajamos con las mejores aseguradoras del país para ayudarte a encontrar un seguro de hogar, auto, moto, bicicleta y celular acorde a tus necesidades y con las mejores cotizaciones del mercado.</p>',
      );

      final empresaB = Empresa(
        id: '13371',
        nombre: 'Forleden',
        logoThumbnail: {
          'original':
              'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/partners/692a0c650f90c.png',
          '90x90':
              'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/partners/692a0c65348e5.png',
        },
        descripcion:
            '<p>Forlen es una marca de indumentaria deportiva que combina rendimiento, estilo y actitud. Diseñada para quienes viven el movimiento sin límites, ofrece prendas cómodas, funcionales y con las últimas tendencias en diseño...</p>',
      );

      final empresaC = Empresa(
        id: '13025',
        nombre: 'Bonda Viajes',
        logoThumbnail: {
          'original':
              'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/coupons/6929ec3e49794.png',
          '90x90':
              'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/partners/68dd75185ed99.png',
        },
        descripcion:
            '<p>Bonda Viajes te ayuda a planear tu viaje de principio a fin, ofreciéndote increíbles descuentos para que tu próxima aventura sea inolvidable.</p>',
      );

      _cupones
        ..clear()
        ..addAll([
          Cupon(
            id: '14547',
            codigo: '',
            descuento: 'Hasta 30%',
            nombre: 'Asistencia Mecánica',
            descripcionBreve: 'Descuentos en asistencia al hogar.',
            descripcionMicrositio:
                '<p>Ingresá a la URL que figura al solicitar el beneficio y disfrutá de hasta un 30% de descuento en ssistencia mecánica.</p><p></p><p></p><p></p><p><b><u>Pasos para acceder al beneficio</u></b>:</p><p></p><p>1- Hacé click en “Quiero este cupón” y luego en “Ir al sitio web”.</p><p></p><p>2- Hacé click en “Asistencia Mecánica”.</p><p></p><p>3- Completá los datos solicitados y hacé click en “Enviar”.</p><p></p><p>4- El sistema te brindará las coberturas que se ajustan a tus respuestas, selecciona la que prefieras y en breve un ejecutivo se estará contactando para asesorarte.</p><p></p><p>5- ¡Disfrutá el beneficio!</p>No acumulable con otras promociones.',
            legales: 'No acumulable con otras promociones.',
            instrucciones:
                '1- Hacé click en “Quiero este cupón” y luego en “Ir al sitio web”. 2- Hacé click en “Asistencia Mecánica”. 3- Completá los datos solicitados y hacé click en “Enviar”. 4- El sistema te brindará las coberturas que se ajustan a tus respuestas, selecciona la que prefieras y en breve un ejecutivo se estará contactando para asesorarte. 5- ¡Disfrutá el beneficio!',
            fechaVencimiento: '',
            precioPuntos: 0,
            permitirSms: true,
            usarEn: {
              'email': false,
              'phone': false,
              'online': true,
              'onsite': false,
              'whatsapp': false,
            },
            fotoThumbnail: {
              'original':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/coupons/693865920dc02.png',
              '90x90':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/partners/6926f5485fabd.png',
            },
            fotoPrincipal: {
              'original':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/assets/693865923132d.jpg',
              '280x190':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/assets/693865924b391.jpg',
            },
            categorias: [Categoria(id: 8, nombre: 'Servicios')],
            empresa: empresaA,
          ),
          Cupon(
            id: '14515',
            codigo: '',
            descuento: '15%',
            nombre: 'Forleden',
            descripcionBreve: '15% de descuento en toda la tienda.',
            descripcionMicrositio:
                '<p><b>¡Actitud que se mueve con vos!</b> Ingresá el código en <a href="https://www.forleden.com.ar/" rel="noopener noreferrer">www.forleden.com.ar</a> y disfrutá de un <b>15% de descuento en toda la tienda</b>.</p><p><br /></p><p><b><u>Pasos para acceder al beneficio:</u></b></p><p>1- Ingresá en <a href="https://www.forleden.com.ar/" rel="noopener noreferrer">www.forleden.com.ar</a></p><p>2- Seleccioná los productos de tu preferencia y hacé click en "Agregar al carrito".</p><p>3- Hacé click en "Finalizar compra" y luego ingresá el código promocional en en la solapa "Cupón". Para continuar, hacé click en "Agregar".</p><p>4- Seleccioná "Finalizar compra", completa los datos solicitados y hacé click en " Ir para el pago".</p><p>5- Seleccioná el método de envió y los medios de pago de tu preferencia.</p><p>6- ¡Disfrutá el beneficio!</p><p>Tope de descuento: 15.000. No válido para productos en oferta ni artículos de River, Boca y AFA. No acumulable con otras promociones.</p><p>Válido hasta 06/05/2026</p>',
            legales:
                '<p>Tope de descuento: 15.000. No válido para productos en oferta ni artículos de River, Boca y AFA. No acumulable con otras promociones.</p><p>Válido hasta 06/05/2026</p>',
            instrucciones:
                '1- Ingresá en www.forleden.com.ar. 2- Seleccioná productos y agregalos al carrito. 3- Ingresá el código en la solapa Cupón y hacé click en Agregar. 4- Finalizá la compra y seguí el pago. 5- Elegí método de envío y pago. 6- ¡Disfrutá el beneficio! Tope 15.000. No aplica a ofertas ni River/Boca/AFA.',
            fechaVencimiento: '2026-05-06 23:59:59',
            precioPuntos: 0,
            permitirSms: true,
            usarEn: {
              'email': false,
              'phone': true,
              'online': true,
              'onsite': false,
              'whatsapp': false,
            },
            fotoThumbnail: {
              'original':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/partners/692a0c650f90c.png',
              '90x90':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/partners/692a0c652d503.png',
            },
            fotoPrincipal: {
              'original':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/assets/692a159492014.png',
              '280x190':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/assets/692a1594d6d1f.png',
            },
            categorias: [
              Categoria(id: 6, nombre: 'Indumentaria, Calzado y Moda'),
            ],
            empresa: empresaB,
          ),
          Cupon(
            id: '14511',
            codigo: '',
            descuento: 'Hasta 30%',
            nombre: 'Paquete a Ushuaia & Calafate',
            descripcionBreve: 'Descuentos en paquetes turísticos.',
            descripcionMicrositio:
                '<p>Solicitá el beneficio y accedé a promociones exclusivas en la contratación de <b>paquetes turísticos a Ushuaia &amp; Calafate. Precio por persona 6 cuotas de 244.309</b> - Precio final - Incluye cupón Bonda.</p><p></p><p>Además, disfrutá de muchos más beneficios para tu próxima aventura por Argentina ingresando a <a href="https://viajes.bonda.com/" rel="noopener noreferrer">www.viajes.bonda.com</a>.</p>No acumulable con otras promociones.',
            legales: 'No acumulable con otras promociones.',
            instrucciones:
                '1- Hacé click en “Ir al sitio”. 2- Escribí por WhatsApp para cotizar tu paquete a Ushuaia & Calafate. 3- Un asesor te acompaña y arma la mejor opción. 4- ¡Disfrutá el beneficio!',
            fechaVencimiento: '',
            precioPuntos: 0,
            permitirSms: true,
            usarEn: {
              'email': false,
              'phone': false,
              'online': true,
              'onsite': false,
              'whatsapp': false,
            },
            fotoThumbnail: {
              'original':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/coupons/6929ec3e49794.png',
              '90x90':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/partners/68dd751858403.png',
            },
            fotoPrincipal: {
              'original':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/assets/6929ec3e70aab.jpg',
              '280x190':
                  'https://cuponstar-ar.s3.amazonaws.com/public/files/uploads/assets/6929ec3e7ae51.jpg',
            },
            categorias: [Categoria(id: 11, nombre: 'Turismo')],
            empresa: empresaC,
          ),
        ]);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No pudimos mostrar los cupones de prueba: $e';
      });
    }
  }

  void _showCuponDetails(Cupon cupon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;

    final dialogSurface = isDark
        ? const Color(0xFF0A1A1A)
        : AppConstants.lightCardBg;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.8 : 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          decoration: BoxDecoration(
            color: dialogSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: primaryGreen.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hero image con overlay
                      Stack(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            color: const Color(0xFF1A1A1A),
                            child: cupon.fotoUrl.isNotEmpty
                                ? Image.network(
                                    _imageUrlForPlatform(cupon.fotoUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, e, s) => Center(
                                      child: Icon(
                                        Icons.local_offer_outlined,
                                        size: 64,
                                        color: primaryGreen.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.local_offer_outlined,
                                      size: 64,
                                      color: primaryGreen.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                          ),
                          // Gradient overlay 3-stop
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.4),
                                    Colors.black.withValues(alpha: 0.88),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Badge descuento top-right (verde)
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryGreen,
                                    primaryGreen.withValues(alpha: 0.75),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryGreen.withValues(alpha: 0.50),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                cupon.descuento,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          // Logo + título overlaid bottom-left
                          Positioned(
                            bottom: 14,
                            left: 14,
                            right: 14,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: primaryGreen.withValues(
                                        alpha: 0.30,
                                      ),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryGreen.withValues(
                                          alpha: 0.22,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: cupon.logoUrl.isNotEmpty
                                        ? Image.network(
                                            _imageUrlForPlatform(cupon.logoUrl),
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, e, s) =>
                                                Container(
                                                  width: 52,
                                                  height: 52,
                                                  color: const Color(0xFF2A2A2A),
                                                  child: Center(
                                                    child: Text(
                                                      cupon.empresa.nombre
                                                          .substring(
                                                            0,
                                                            (cupon.empresa.nombre
                                                                    .length)
                                                                .clamp(0, 2),
                                                          )
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: primaryGreen,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                          )
                                        : Container(
                                            width: 52,
                                            height: 52,
                                            color: const Color(0xFF2A2A2A),
                                            child: Center(
                                              child: Text(
                                                cupon.empresa.nombre
                                                    .substring(
                                                      0,
                                                      (cupon.empresa.nombre
                                                              .length)
                                                          .clamp(0, 2),
                                                    )
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryGreen,
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        cupon.nombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          height: 1.15,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        cupon.empresa.nombre,
                                        style: TextStyle(
                                          color: primaryGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                      // Fila bonda + categorías
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Beneficio provisto por ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 18,
                                    width: 70,
                                    child: Image.asset(
                                      'assets/images/logo_bonda.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (cupon.categorias.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: cupon.categorias.map((cat) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryGreen.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: primaryGreen.withValues(
                                          alpha: 0.30,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      cat.nombre,
                                      style: TextStyle(
                                        color: primaryGreen,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLimitedDetailSection(
                              title: 'Cómo usar',
                              icon: Icons.info_outline,
                              primaryGreen: primaryGreen,
                              content: cupon.descripcionMicrositio,
                              textColor: textColor,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 18),
                            _buildLimitedDetailSection(
                              title: 'Términos y Condiciones',
                              icon: Icons.gavel,
                              primaryGreen: primaryGreen,
                              content: cupon.legales,
                              textColor: textColor.withValues(alpha: 0.8),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D0D0D),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryGreen.withValues(alpha: 0.20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryGreen.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: primaryGreen.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.schedule_rounded,
                                      color: primaryGreen,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Válido hasta',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: primaryGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          cupon.fechaVencimientoFormatted,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: AppConstants.textLight,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 8,
                                  shadowColor: primaryGreen.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                child: const Text(
                                  'CERRAR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppConstants.textLight,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : AppConstants.lightSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.darkBg : AppConstants.lightBg;
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;

    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildCuponPreviewSection(isDark, primaryGreen, textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCuponPreviewSection(
    bool isDark,
    Color primaryGreen,
    Color textColor,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 44, color: Colors.red.shade400),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade400),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _loadMockCupones,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cupones.isEmpty) {
      return Center(
        child: Text(
          'Aún no hay cupones para mostrar.',
          style: TextStyle(color: textColor.withValues(alpha: 0.7)),
        ),
      );
    }

    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final double maxExtent;
          if (width >= 1800) {
            maxExtent = 420;
          } else if (width >= 1400) {
            maxExtent = 460;
          } else {
            maxExtent = 520;
          }

          final double aspectRatio = width >= 1400 ? 0.92 : 0.9;

          return GridView.builder(
            controller: _listScrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxExtent,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: aspectRatio,
            ),
            itemCount: _cupones.length,
            itemBuilder: (context, index) {
              final cupon = _cupones[index];
              return _buildCuponCardPreview(
                context,
                cupon,
                primaryGreen,
                textColor,
                isDark,
              );
            },
          );
        },
      );
    }

    return ListView.builder(
      controller: _listScrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _cupones.length,
      itemBuilder: (context, index) {
        final cupon = _cupones[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _buildCuponCardPreview(
                context,
                cupon,
                primaryGreen,
                textColor,
                isDark,
              ),
            ),
          ),
        );
      },
    );
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

  String _imageUrlForPlatform(String url) {
    final safe = _safeImageUrl(url);
    if (!kIsWeb || safe.isEmpty) return safe;
    final proxyBase = ApiConfig.imageProxyBase;
    if (proxyBase.isEmpty) return safe;
    final encoded = Uri.encodeComponent(safe);
    return '$proxyBase$encoded';
  }

  Widget _buildCuponCardPreview(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCuponDetails(cupon),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryGreen.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1),
              child: Container(
                color: isDark ? const Color(0xFF111111) : AppConstants.lightCardBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: kIsWeb ? 140 : 160,
                          width: double.infinity,
                          color: const Color(0xFF1A1A1A),
                          child: cupon.fotoUrl.isNotEmpty
                              ? Image.network(
                                  _imageUrlForPlatform(cupon.fotoUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.local_offer,
                                        size: 64,
                                        color: primaryGreen.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Icon(
                                    Icons.local_offer,
                                    size: 64,
                                    color: primaryGreen.withValues(alpha: 0.3),
                                  ),
                                ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.12),
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryGreen,
                                  primaryGreen.withValues(alpha: 0.75),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryGreen.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              cupon.descuento,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryGreen.withValues(alpha: 0.30),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryGreen.withValues(alpha: 0.20),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: cupon.logoUrl.isNotEmpty
                                  ? Image.network(
                                      _imageUrlForPlatform(cupon.logoUrl),
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 56,
                                              height: 56,
                                              color: const Color(0xFF2A2A2A),
                                              child: Center(
                                                child: Text(
                                                  cupon.empresa.nombre
                                                      .substring(
                                                        0,
                                                        (cupon
                                                                .empresa
                                                                .nombre
                                                                .length)
                                                            .clamp(0, 2),
                                                      )
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryGreen,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            );
                                          },
                                    )
                                  : Container(
                                      width: 56,
                                      height: 56,
                                      color: const Color(0xFF2A2A2A),
                                      child: Center(
                                        child: Text(
                                          cupon.empresa.nombre
                                              .substring(
                                                0,
                                                (cupon.empresa.nombre.length)
                                                    .clamp(0, 2),
                                              )
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: primaryGreen,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cupon.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.storefront,
                                size: 14,
                                color: primaryGreen.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cupon.empresa.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _cleanHtml(
                              cupon.descripcionBreve.isNotEmpty
                                  ? cupon.descripcionBreve
                                  : cupon.descripcionMicrositio,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withValues(alpha: 0.7),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (cupon.categorias.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: cupon.categorias.take(2).map((cat) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: primaryGreen.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    cat.nombre,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: textColor.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Válido hasta: ${cupon.fechaVencimientoFormatted}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textColor.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildLockedAffiliationButton(
                            primaryGreen: primaryGreen,
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedAffiliationButton({
    required Color primaryGreen,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.lock_outline),
        label: const Text('Disponible al completar tu afiliación'),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.25),
          disabledForegroundColor: textColor.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLimitedDetailSection({
    required String title,
    required IconData icon,
    required Color primaryGreen,
    required String content,
    required Color textColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: primaryGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : AppConstants.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryGreen.withValues(alpha: 0.15)),
          ),
          child: Html(
            data: content,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(13),
                color: textColor,
                lineHeight: const LineHeight(1.5),
              ),
              'p': Style(margin: Margins.only(bottom: 8)),
              'ul': Style(margin: Margins.only(left: 16, bottom: 8)),
              'li': Style(margin: Margins.only(bottom: 4)),
            },
          ),
        ),
      ],
    );
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}

/// Contenido limitado de Sorteos - Bloqueado
class LimitedRafflesContent extends StatelessWidget {
  const LimitedRafflesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _buildLockedContent(
              context,
              Icons.card_giftcard,
              'Sorteos',
              'Podrás participar en sorteos una vez completada tu afiliación.',
            ),
          ),
        ],
      ),
    );
  }
}

class LimitedGamesContent extends StatelessWidget {
  const LimitedGamesContent({super.key, required this.onPlay});

  final Future<void> Function(WidgetBuilder builder) onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final isWeb = kIsWeb;
    final games = [
      (
        title: 'Space Runner',
        subtitle: 'Arcade de reflejos',
        description:
            'Esquiva columnas, suma puntos y pausa cuando necesites un respiro.',
        badge: 'Nuevo',
        onTap: () => onPlay((_) => const Game01Page()),
        asset: 'assets/icons/game_01_icon.png',
      ),
      (
        title: 'Tower Stack',
        subtitle: 'Equilibrio y ritmo',
        description:
            'Apila bloques en movimiento para construir la torre más alta posible.',
        badge: 'Arcade',
        onTap: () => onPlay((_) => const Game02Page()),
        asset: 'assets/icons/game_02_icon.png',
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: isWeb
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrowWeb = constraints.maxWidth < 900;
                      if (isNarrowWeb) {
                        return Column(
                          children: games
                              .map(
                                (g) => _GameCardLimited(
                                  title: g.title,
                                  subtitle: g.subtitle,
                                  description: g.description,
                                  badge: g.badge,
                                  primaryGreen: primaryGreen,
                                  textColor: textColor,
                                  isDark: isDark,
                                  onPlay: g.onTap,
                                  asset: g.asset,
                                ),
                              )
                              .toList(),
                        );
                      }

                      final maxExtent = (constraints.maxWidth * 0.33).clamp(
                        260.0,
                        420.0,
                      );

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: games.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: maxExtent,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final g = games[index];
                          return _LimitedGameGridCard(
                            title: g.title,
                            subtitle: g.subtitle,
                            badge: g.badge,
                            primaryGreen: primaryGreen,
                            onPlay: g.onTap,
                            isDark: isDark,
                            asset: g.asset,
                          );
                        },
                      );
                    },
                  )
                : Column(
                    children: games
                        .map(
                          (g) => _GameCardLimited(
                            title: g.title,
                            subtitle: g.subtitle,
                            description: g.description,
                            badge: g.badge,
                            primaryGreen: primaryGreen,
                            textColor: textColor,
                            isDark: isDark,
                            onPlay: g.onTap,
                            asset: g.asset,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LimitedGameGridCard extends StatelessWidget {
  const _LimitedGameGridCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.primaryGreen,
    required this.onPlay,
    required this.isDark,
    required this.asset,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color primaryGreen;
  final VoidCallback onPlay;
  final bool isDark;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final t = (((340 - w) / 140).clamp(0.0, 1.0));
        final s = 1.0 + 0.22 * t;

        final buttonHeight = (44 * s).clamp(44.0, 56.0);
        final chipIconSize = (13 * s).clamp(13.0, 16.0);
        final chipTextSize = (11 * s).clamp(11.0, 13.0);
        final titleSize = (18 * s).clamp(18.0, 20.0);
        final subtitleSize = (12 * s).clamp(12.0, 13.0);
        final ctaTextSize = (13 * s).clamp(13.0, 15.0);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPlay,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF111111),
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.08),
                    blurRadius: 22,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Badge chip — neon green
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: primaryGreen.withValues(alpha: 0.40),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videogame_asset,
                              size: chipIconSize,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              badge,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: chipTextSize,
                                color: primaryGreen,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Image container with neon glow
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF1A1A1A),
                        border: Border.all(
                          color: primaryGreen.withValues(alpha: 0.22),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: 0.14),
                            blurRadius: 16,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(asset, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // CTA neon green button
                  SizedBox(
                    height: buttonHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryGreen,
                            primaryGreen.withValues(alpha: 0.78),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: 0.42),
                            blurRadius: 16,
                            spreadRadius: 0,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sports_esports,
                            size: 17,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Jugar',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: ctaTextSize,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.north_east,
                            size: 15,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GameCardLimited extends StatelessWidget {
  const _GameCardLimited({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.badge,
    required this.primaryGreen,
    required this.textColor,
    required this.isDark,
    required this.onPlay,
    required this.asset,
  });

  final String title;
  final String subtitle;
  final String description;
  final String badge;
  final Color primaryGreen;
  final Color textColor;
  final bool isDark;
  final VoidCallback onPlay;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Neon left strip
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryGreen,
                      primaryGreen.withValues(alpha: 0.15),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.65),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Content area
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPlay,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        border: Border(
                          top: BorderSide(
                            color: primaryGreen.withValues(alpha: 0.15),
                            width: 1,
                          ),
                          right: BorderSide(
                            color: primaryGreen.withValues(alpha: 0.15),
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: primaryGreen.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: 0.05),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row: badge + subtitle pill
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: primaryGreen.withValues(alpha: 0.40),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.videogame_asset,
                                      size: 13,
                                      color: primaryGreen,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      badge,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        color: primaryGreen,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.60),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Body row: text column + image
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: Colors.white.withValues(
                                          alpha: 0.50,
                                        ),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    // CTA neon button
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            primaryGreen,
                                            primaryGreen.withValues(alpha: 0.78),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryGreen.withValues(
                                              alpha: 0.42,
                                            ),
                                            blurRadius: 16,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.14,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 9,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.sports_esports,
                                              size: 15,
                                              color: Colors.black,
                                            ),
                                            SizedBox(width: 7),
                                            Text(
                                              'Jugar ahora',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            SizedBox(width: 7),
                                            Icon(
                                              Icons.north_east,
                                              size: 13,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Container(
                                height: 74,
                                width: 74,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: const Color(0xFF1A1A1A),
                                  border: Border.all(
                                    color: primaryGreen.withValues(alpha: 0.22),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryGreen.withValues(alpha: 0.14),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Image.asset(asset, fit: BoxFit.contain),
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
            ],
          ),
        ),
      ),
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
  final isDark = theme.brightness == Brightness.dark;
  final textColor = isDark
      ? theme.colorScheme.onSurface
      : AppConstants.textLight;
  final primaryGreen = theme.colorScheme.primary;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111111) : AppConstants.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.22),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: textColor.withValues(alpha: 0.18),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : AppConstants.lightCardBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 13,
                      color: primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'BLOQUEADO',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: primaryGreen.withValues(alpha: 0.70),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.52),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111111) : AppConstants.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.24),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.22),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    color: primaryGreen,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Afiliación en proceso...',
                  style: TextStyle(
                    fontSize: 13,
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
    final accent = theme.colorScheme.primary;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : AppConstants.lightBg;

    // Posts de ejemplo (solo lectura) replicando la vista real del foro
    final posts = [
      _ForumPost(
        id: 101,
        username: 'JugadorPro',
        content:
            '¡Acabo de ganar en el casino! 🎰 ¿Alguien tiene tips para blackjack?',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      _ForumPost(
        id: 102,
        username: 'ApostadorExperto',
        content: '¿Cuál es su estrategia favorita para apuestas deportivas?',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      _ForumPost(
        id: 103,
        username: 'CasinoFan',
        content: 'Las slots están on fire hoy 🔥 ¡Buena suerte a todos!',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: 0.38,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: accent.withValues(alpha: 0.28),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const IconButton(
                            icon: Icon(Icons.add_rounded),
                            onPressed: null,
                            tooltip: 'Publicar (disponible tras afiliación)',
                            iconSize: 17,
                            padding: EdgeInsets.all(7),
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Opacity(
                        opacity: 0.35,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: accent.withValues(alpha: 0.28),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const IconButton(
                            icon: Icon(Icons.person_outline),
                            onPressed: null,
                            tooltip: 'Ver mis publicaciones (tras afiliación)',
                            iconSize: 17,
                            padding: EdgeInsets.all(7),
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: posts.length,
              itemBuilder: (context, index) => _LimitedPostCard(
                post: posts[index],
                isDark: isDark,
                accent: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _LimitedPostCard extends StatelessWidget {
  const _LimitedPostCard({
    required this.post,
    required this.isDark,
    required this.accent,
  });

  final _ForumPost post;
  final bool isDark;
  final Color accent;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              // Left accent strip
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
              // Card body
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _LimitedAvatarBubble(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (post.parentId != null) ...[
                                    Text(
                                      '↩ Respuesta a #${post.parentId}',
                                      style: TextStyle(
                                        color: accent.withValues(alpha: 0.7),
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
                                        color: accent.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _formatDate(post.createdAt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: accent.withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: accent.withValues(alpha: 0.30),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          post.content,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.80)
                                : AppConstants.textLight,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

class _LimitedAvatarBubble extends StatelessWidget {
  const _LimitedAvatarBubble({
    required this.radius,
    required this.borderGradient,
    required this.background,
    required this.avatarUrl,
    required this.fallbackLetter,
    required this.textColor,
  });

  final double radius;
  final List<Color> borderGradient;
  final Color background;
  final String avatarUrl;
  final String fallbackLetter;
  final Color textColor;

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
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                  errorBuilder: (_, __, ___) => _LimitedFallbackLetter(
                    letter: fallbackLetter,
                    color: textColor,
                    fontSize: radius,
                  ),
                )
              : _LimitedFallbackLetter(
                  letter: fallbackLetter,
                  color: textColor,
                  fontSize: radius,
                ),
        ),
      ),
    );
  }
}

class _LimitedFallbackLetter extends StatelessWidget {
  const _LimitedFallbackLetter({
    required this.letter,
    required this.color,
    required this.fontSize,
  });

  final String letter;
  final Color color;
  final double fontSize;

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

/// Modelo simple para posts del foro limitado
class _ForumPost {
  final int id;
  final String username;
  final String content;
  final DateTime createdAt;
  final int? parentId;
  final String avatarUrl;

  _ForumPost({
    required this.id,
    required this.username,
    required this.content,
    required this.createdAt,
    this.parentId,
    this.avatarUrl = '',
  });
}
