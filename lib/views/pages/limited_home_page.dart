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
import 'package:boombet_app/views/pages/affiliation_results_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
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
  bool _allowQrScanner = false;

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
    }

    _loadAffiliateType();

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

  Future<void> _loadAffiliateType() async {
    await loadAffiliateCodeUsage();
    await loadAffiliateType();
    if (!mounted) return;

    if (!affiliateCodeValidatedNotifier.value) {
      setState(() => _allowQrScanner = false);
      return;
    }

    final tipo = affiliateTypeNotifier.value.trim().toUpperCase();
    setState(() => _allowQrScanner = tipo == 'RULETA');
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AffiliationResultsPage(result: result),
      ),
    );
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
    _wsSubscription?.cancel();
    widget.affiliationService.closeWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        final safeIndex = selectedPage.clamp(0, 4);
        return Scaffold(
          // AppBar sin configuración ni perfil
          appBar: MainAppBar(
            showSettings: false,
            showLogo: true,
            showProfileButton: false,
            showLogoutButton: true,
            showExitButton: false,
            showQrScannerButton: _allowQrScanner,
          ),
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
              ],
            ),
          ),
          bottomNavigationBar: const NavbarWidget(showCasinos: false),
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
                  SectionHeaderWidget(
                    title: 'Inicio',
                    subtitle: 'Anuncios y novedades personalizadas',
                    icon: Icons.campaign,
                  ),
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
                SectionHeaderWidget(
                  title: 'Inicio',
                  subtitle: 'Anuncios y novedades personalizadas',
                  icon: Icons.campaign,
                ),
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
          SectionHeaderWidget(
            title: 'Inicio',
            subtitle: 'Anuncios y novedades personalizadas',
            icon: Icons.campaign,
          ),
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
                color: textColor.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
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
    final muted = textColor.withValues(alpha: 0.70);

    Widget benefitRow({
      required IconData icon,
      required String title,
      required String description,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryGreen.withValues(alpha: 0.16),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryGreen, size: 20),
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
                      fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryGreen.withValues(alpha: 0.22),
            primaryGreen.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Bienvenido a BoomBet!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mientras se completa tu afiliación, conocé lo que vas a poder hacer:',
            style: TextStyle(fontSize: 13, color: muted, height: 1.35),
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
                      if (i != _benefits.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryGreen.withValues(alpha: 0.18),
            primaryGreen.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.30),
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
              color: textColor.withValues(alpha: 0.8),
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
                  : AppConstants.lightAccent,
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryGreen.withValues(alpha: 0.22),
            primaryGreen.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, color: primaryGreen, size: 42),
          const SizedBox(height: 12),
          Text(
            'Afiliación en proceso',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
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
              color: textColor.withValues(alpha: 0.8),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              backgroundColor: isDark
                  ? const Color(0xFF2A2A2A)
                  : AppConstants.lightAccent,
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
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
        color: isDark ? Colors.grey[900] : AppConstants.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryGreen, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryGreen.withValues(alpha: 0.15),
                              Colors.red.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade500,
                                    Colors.red.shade600,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                cupon.descuento,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppConstants.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              cupon.nombre,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppConstants.textLight,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business,
                                  color: primaryGreen,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cupon.empresa.nombre,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              runSpacing: 6,
                              children: cupon.categorias.map((cat) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: primaryGreen.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 1,
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
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : AppConstants.lightSurfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Beneficio provisto por ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : AppConstants.textLight,
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
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.orange.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
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
                                            color: Colors.orange.shade700,
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
          SectionHeaderWidget(
            title: 'Descuentos Exclusivos',
            subtitle: _cupones.isNotEmpty
                ? '${_cupones.length} ofertas en vista previa'
                : 'Vista previa mientras completamos tu afiliación',
            icon: Icons.local_offer,
          ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1),
              child: Container(
                color: isDark ? Colors.grey[900] : AppConstants.lightCardBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: kIsWeb ? 140 : 160,
                          width: double.infinity,
                          color: primaryGreen.withValues(alpha: 0.1),
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
                                colors: [Colors.red.shade600, Colors.red],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              cupon.descuento,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppConstants.textLight,
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
                              color: isDark
                                  ? Colors.white
                                  : AppConstants.lightCardBg,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
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
                                              color: AppConstants
                                                  .lightSurfaceVariant,
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
                                      color: isDark
                                          ? Colors.grey[800]
                                          : AppConstants.lightSurfaceVariant,
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
          SectionHeaderWidget(
            title: 'Sorteos',
            subtitle: 'Próximamente disponibles',
            icon: Icons.card_giftcard,
          ),
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
          SectionHeaderWidget(
            title: 'Juegos',
            subtitle:
                'Explora los minijuegos de BoomBet y probalos mientras te afiliamos!',
            icon: Icons.videogame_asset,
          ),
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
    final fg = isDark ? Colors.white : AppConstants.textLight;
    final fgSoft = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppConstants.textLight;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : AppConstants.borderLight.withValues(alpha: 0.7);
    final surfaceVariant = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppConstants.lightSurfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final t = (((340 - w) / 140).clamp(0.0, 1.0));
        final s = 1.0 + 0.22 * t;

        final buttonHeight = (44 * s).clamp(44.0, 56.0);
        final chipIconSize = (18 * s).clamp(18.0, 22.0);
        final chipTextSize = (12 * s).clamp(12.0, 14.0);
        final titleSize = (18 * s).clamp(18.0, 20.0);
        final subtitleSize = (13 * s).clamp(13.0, 15.0);
        final ctaIconSize = (18 * s).clamp(18.0, 22.0);
        final ctaArrowSize = (16 * s).clamp(16.0, 20.0);
        final ctaTextSize = (13 * s).clamp(13.0, 16.0);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPlay,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryGreen.withValues(alpha: isDark ? 0.22 : 0.16),
                    primaryGreen.withValues(alpha: isDark ? 0.1 : 0.07),
                  ],
                ),
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videogame_asset,
                              size: chipIconSize,
                              color: fg,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              badge,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: chipTextSize,
                                color: fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        color: surfaceVariant,
                        child: Image.asset(asset, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fgSoft,
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppConstants.lightSurfaceVariant,
                      border: Border.all(color: borderColor, width: 0.9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_esports,
                          size: ctaIconSize,
                          color: fg,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Jugar',
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w800,
                            fontSize: ctaTextSize,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.north_east, size: ctaArrowSize, color: fg),
                      ],
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
    final accentBg = isDark
        ? Colors.black.withValues(alpha: 0.08)
        : AppConstants.lightSurfaceVariant;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : AppConstants.borderLight.withValues(alpha: 0.7);
    final fg = isDark ? Colors.white : AppConstants.textLight;
    final fgSoft = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppConstants.textLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPlay,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryGreen.withValues(alpha: isDark ? 0.24 : 0.18),
                primaryGreen.withValues(alpha: isDark ? 0.1 : 0.08),
              ],
            ),
            border: Border.all(
              color: primaryGreen.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.videogame_asset, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          badge,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.auto_awesome, color: fg, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: fgSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.38,
                            color: fgSoft,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : AppConstants.lightSurfaceVariant,
                            border: Border.all(color: borderColor, width: 0.9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sports_esports, size: 18, color: fg),
                              const SizedBox(width: 8),
                              Text(
                                'Jugar ahora',
                                style: TextStyle(
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.north_east, size: 16, color: fg),
                            ],
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
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppConstants.lightSurfaceVariant,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppConstants.borderLight.withValues(alpha: 0.7),
                        width: 0.9,
                      ),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.grey[900]
                  : AppConstants.lightSurfaceVariant,
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 64,
              color: textColor.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.lock_outline,
            size: 48,
            color: primaryGreen.withValues(alpha: 0.5),
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
              color: textColor.withValues(alpha: 0.6),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.3),
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
          _ForumHeaderLimited(
            accent: accent,
            isDark: isDark,
            postCount: posts.length,
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

class _ForumHeaderLimited extends StatelessWidget {
  const _ForumHeaderLimited({
    required this.accent,
    required this.isDark,
    required this.postCount,
  });

  final Color accent;
  final bool isDark;
  final int postCount;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppConstants.textLight;

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
                            '$postCount ${postCount == 1 ? 'publicación' : 'publicaciones'} • Vista previa (solo lectura)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textColor.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : AppConstants.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const IconButton(
                    icon: Icon(Icons.add_rounded),
                    onPressed: null,
                    tooltip: 'Publicar (disponible tras afiliación)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Opacity(
                opacity: 0.35,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : AppConstants.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: const IconButton(
                    icon: Icon(Icons.person_outline),
                    onPressed: null,
                    tooltip: 'Ver mis publicaciones (tras afiliación)',
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LimitedAvatarBubble(
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
                                color: isDark
                                    ? Colors.white.withOpacity(0.8)
                                    : AppConstants.textLight.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: accent.withOpacity(0.35),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              post.content,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark
                    ? Colors.white.withOpacity(0.85)
                    : AppConstants.textLight,
                letterSpacing: 0.2,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
