import 'dart:async';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/affiliation_result.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/views/pages/affiliation_results_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

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

    // // Timer de 15 segundos para mostrar resultados
    // Future.delayed(const Duration(seconds: 15), () {
    //   if (mounted && !_affiliationCompleted) {
    //     _affiliationCompleted = true;
    //     _navigateToResultsPage(null);
    //   }
    // });

    // Escuchar mensajes del WebSocket
    _wsSubscription = widget.affiliationService.messageStream.listen(
      (message) {
        if (!mounted || _affiliationCompleted) return;

        debugPrint('[LimitedHomePage] 📩 Mensaje recibido del WebSocket');
        debugPrint('[LimitedHomePage] Contenido: $message');

        // Verificar si el mensaje contiene playerData y responses
        if (message.containsKey('playerData') &&
            message.containsKey('responses')) {
          debugPrint(
            '[LimitedHomePage] ✅ Mensaje completo de afiliación recibido',
          );
          _affiliationCompleted = true;

          // Parsear el resultado
          try {
            final result = AffiliationResult.fromJson(message);
            _navigateToResultsPage(result);
          } catch (e) {
            debugPrint('[LimitedHomePage] ❌ Error parseando resultado: $e');
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
        debugPrint('[LimitedHomePage] ❌ Error en WebSocket: $error');
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
                  primaryGreen.withValues(alpha: 0.2),
                  primaryGreen.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.3),
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
              color: textColor.withValues(alpha: 0.7),
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
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
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
                    color: textColor.withValues(alpha: 0.6),
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

  @override
  void initState() {
    super.initState();
    _loadMockCupones();
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cupon.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cupon.empresa.nombre,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Descuento: ${cupon.descuento}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (cupon.descripcionMicrositio.isNotEmpty) ...[
                    const Text(
                      'Cómo usarlo:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Html(data: cupon.descripcionMicrositio),
                    const SizedBox(height: 12),
                  ],
                  if (cupon.legales.isNotEmpty) ...[
                    const Text(
                      'Términos y condiciones:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Html(data: cupon.legales),
                  ],
                ],
              ),
            ),
          ],
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

    return ResponsiveWrapper(
      child: Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer, color: primaryGreen),
                  const SizedBox(width: 10),
                  Text(
                    'Cupones disponibles (vista previa)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Vista de solo lectura mientras completamos tu afiliación. Podrás reclamarlos cuando termines.',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.75),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              _buildCuponPreviewSection(isDark, primaryGreen, textColor),
            ],
          ),
        ),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!, style: TextStyle(color: Colors.red.shade400)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadMockCupones,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_cupones.isEmpty) {
      return Text(
        'Aún no hay cupones para mostrar.',
        style: TextStyle(color: textColor.withValues(alpha: 0.7)),
      );
    }

    return Column(
      children: _cupones
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCuponCardPreview(c, isDark, primaryGreen, textColor),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCuponCardPreview(
    Cupon cupon,
    bool isDark,
    Color primaryGreen,
    Color textColor,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showCuponDetails(cupon),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: primaryGreen.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: cupon.fotoUrl.isNotEmpty
                  ? Image.network(
                      cupon.fotoUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 140,
                          color: primaryGreen.withValues(alpha: 0.12),
                          child: Center(
                            child: Icon(
                              Icons.local_offer,
                              size: 48,
                              color: primaryGreen.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 140,
                      color: primaryGreen.withValues(alpha: 0.12),
                      child: Center(
                        child: Icon(
                          Icons.local_offer,
                          size: 48,
                          color: primaryGreen.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cupon.nombre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cupon.empresa.nombre,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cleanHtml(
                      cupon.descripcionBreve.isNotEmpty
                          ? cupon.descripcionBreve
                          : cupon.descripcionMicrositio,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.75),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Válido hasta: ${cupon.fechaVencimientoFormatted}',
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text(
                        'Disponible al completar tu afiliación',
                      ),
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: primaryGreen.withValues(
                          alpha: 0.25,
                        ),
                        disabledForegroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  String _cleanHtml(String html) {
    final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return html.replaceAll(regex, '').trim();
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
    final bgColor = isDark ? AppConstants.darkBg : AppConstants.lightBg;
    final cardColor = isDark ? AppConstants.darkCardBg : Colors.white;
    final textColor = isDark ? AppConstants.textDark : Colors.black87;
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
                  // Mensaje de restricción
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: greenColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: greenColor.withValues(alpha: 0.3),
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
                              color: textColor.withValues(alpha: 0.8),
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
            Icon(icon, size: 20, color: textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.5),
              ),
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
