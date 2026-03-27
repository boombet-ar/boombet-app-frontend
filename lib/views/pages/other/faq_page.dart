import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  bool _isLoggedIn = false;
  static const String _bplayPoweredByUrl = 'https://www.bplay.bet.ar/';
  static const String _sportsbetPoweredByUrl = 'https://sportsbet.bet.ar/';
  static const String _betssonPoweredByUrl = 'https://www.betsson.bet.ar/';
  final List<Map<String, String>> _platformFaqs = [
    {
      'question': '¿Que es BoomBet?',
      'answer':
          'BoomBet es el primer portal de Casinos Online en Argentina. Se trata de un solo lugar donde podes registrarte rápido y acceder a los mejores Casinos legales del país, con todas sus promociones y beneficios al alcance de tu mano.',
    },
    {
      'question': '¿Como funciona la afiliacion?',
      'answer':
          'Al completar el formulario, nuestro equipo gestiona tu alta en los Casinos Online Legales según tu lugar de residencia. Durante el proceso vas a recibir e-mails oficiales de cada casino. Una vez finalizada la afiliación, te informaremos en qué casinos fuiste dado de alta, qué beneficios recibiste y los datos necesarios para comenzar a jugar. Es importante esperar nuestra confirmación antes de validar tus cuentas, ya que podrías necesitar información específica que te enviaremos. El proceso es simple, seguro, legal y suele completarse en menos de 24 horas.',
    },
    {
      'question': '¿Puedo afiliarme siendo menor de 18 años?',
      'answer':
          'No, porque la ley solo permite el acceso a Casinos Online Legales a personas mayores de 18 años. Esta medida protege a los menores y garantiza un juego responsable.',
    },
    {
      'question': '¿Que puedo hacer desde esta plataforma una vez afiliado?',
      'answer':
          'Podes acceder a promociones exclusivas para nuestros casinos, beneficios aplicables a diferentes negocios y categorias, juegos con rankings, sorteos, etc.',
    },
    {
      'question': '¿Puedo desafiliarme de BoomBet?',
      'answer':
          'Si! Desde la vista de perfil (icono de perfil) encontras el boton para desafiliarte, nosotros hacemos el proceso por vos. Recorda que desafiliarte de BoomBet no te desafilia de nuestros casinos asociados.',
    },
  ];
  final List<Map<String, String>> _benefitsFaqs = [
    {
      'question': '¿Como obtengo un beneficio?',
      'answer':
          'Afiliandote con nosotros podes acceder a la pestaña de beneficios (icono de beneficio) de nuestra aplicacion para reclamar tus cupones y empezar a usarlos.',
    },
    {
      'question': '¿Donde puedo ver mis beneficios disponibles?',
      'answer':
          'En la misma pestaña donde los reclamas, vas a ver un icono con un tilde (icono de reclamados). Al presionarlo, vas a pasar a la vista de los cupones reclamados donde vas a poder ver el codigo correspondiente al cupon, su fecha de vencimiento y como utilizarlo.',
    },
    {
      'question': '¿Los beneficios tienen vencimiento?',
      'answer':
          'Sí. Cada beneficio tiene una fecha de expiración que se muestra en su tarjeta dentro de la app.',
    },
  ];
  final List<Map<String, String>> _forumFaqs = [
    {
      'question': '¿Cómo publico en el foro?',
      'answer':
          'Entrá a la pestaña Foro, tocá el botón para crear publicación, escribí tu título y mensaje, y confirmá para publicarlo. Tu post quedará visible para la comunidad.',
    },
    {
      'question': '¿Puedo borrar una publicación mía?',
      'answer':
          'Sí. En tus publicaciones (icono de perfil) vas a ver la opción para eliminar. Si borrás una publicación, se elimina del foro y ya no podrá ser vista por otros usuarios.',
    },
    {
      'question': '¿Cómo respondo a otro usuario en el foro?',
      'answer':
          'Abrí la publicación, escribí tu comentario en la sección de respuestas y enviá. También podés volver a entrar después para seguir la conversación.',
    },
    {
      'question': '¿Me llegan notificaciones de actividad del foro?',
      'answer':
          'Sí, podés recibir notificaciones cuando hay actividad relevante. Desde Configuración > Notificaciones podés activar o desactivar la subcategoría Foro cuando quieras.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    // Verificar si hay un token válido (persistente O temporal)
    final isValid = await TokenService.isTokenValid();

    debugPrint('DEBUG FAQ - Token valid: $isValid');

    if (mounted) {
      setState(() {
        _isLoggedIn = isValid;
      });
      debugPrint('DEBUG FAQ - _isLoggedIn set to: $_isLoggedIn');
    }
  }

  Future<void> _openBoomBetSite() async {
    final uri = Uri.parse('https://boombet-ar.bet');
    final ok = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo abrir el sitio.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _openPoweredBySite(String rawUrl) async {
    final url = rawUrl.trim();
    if (url.isEmpty || url.contains('REEMPLAZAR_')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configura la URL del logo en faq_page.dart'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('La URL configurada no es válida.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    final ok = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo abrir el enlace.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _openWhatsAppSupport() async {
    final rawPhone = AppConstants.supportWhatsappNumber.trim();
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Configura AppConstants.supportWhatsappNumber para habilitar WhatsApp.',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    final message = Uri.encodeComponent(AppConstants.supportWhatsappMessage);
    final uri = Uri.parse('https://wa.me/$phone?text=$message');

    final ok = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo abrir WhatsApp.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  List<InlineSpan> _buildAnswerSpans(String text, Color textColor) {
    final replacements = <String, Widget>{
      '(icono de perfil)': Icon(
        Icons.person_outline,
        size: 18,
        color: textColor,
      ),
      '(icono de beneficio)': Icon(
        Icons.local_offer_outlined,
        size: 18,
        color: textColor,
      ),
      '(icono de reclamados)': Icon(
        Icons.check_circle_outline,
        size: 18,
        color: textColor,
      ),
    };

    final spans = <InlineSpan>[];
    var remaining = text;

    while (remaining.isNotEmpty) {
      int? firstIndex;
      String? foundToken;

      for (final token in replacements.keys) {
        final idx = remaining.indexOf(token);
        if (idx != -1 && (firstIndex == null || idx < firstIndex)) {
          firstIndex = idx;
          foundToken = token;
        }
      }

      if (firstIndex == null || foundToken == null) {
        spans.add(TextSpan(text: remaining));
        break;
      }

      if (firstIndex > 0) {
        spans.add(TextSpan(text: remaining.substring(0, firstIndex)));
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: replacements[foundToken]!,
          ),
        ),
      );

      remaining = remaining.substring(firstIndex + foundToken.length);
    }

    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const primaryGreen = AppConstants.primaryGreen;
    const textMuted = Colors.white;
    final maxWidth = kIsWeb ? 1400.0 : 800.0;

    Widget buildSingleColumnBody() {
      return Stack(
        children: [
          // Radial glow — top left
          Positioned(
            top: -60,
            left: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryGreen.withValues(alpha: 0.055),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Radial glow — bottom right
          Positioned(
            bottom: -40,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryGreen.withValues(alpha: 0.038),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _buildPageHeader(),
              const SizedBox(height: 14),
              _buildWhatsAppContactButton(),
              const SizedBox(height: 20),
              _buildFaqSection(
                context,
                icon: Icons.home_outlined,
                title: 'Plataforma',
                items: _platformFaqs,
              ),
              const SizedBox(height: 10),
              _buildFaqSection(
                context,
                icon: Icons.local_offer_outlined,
                title: 'Beneficios',
                items: _benefitsFaqs,
              ),
              const SizedBox(height: 10),
              _buildFaqSection(
                context,
                icon: Icons.forum_outlined,
                title: 'Foro',
                items: _forumFaqs,
              ),
              const SizedBox(height: 24),
              _buildPoweredByPanel(context),
            ],
          ),
        ],
      );
    }

    Widget buildWebBody() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrowWeb = constraints.maxWidth < 900;
          if (isNarrowWeb) {
            return buildSingleColumnBody();
          }

          return Stack(
            children: [
              // Radial glow — top left
              Positioned(
                top: -60,
                left: -50,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryGreen.withValues(alpha: 0.055),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                right: -50,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryGreen.withValues(alpha: 0.038),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFaqListWeb(context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPoweredByPanel(context)),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ResponsiveWrapper(
          maxWidth: maxWidth,
          child: kIsWeb ? buildWebBody() : buildSingleColumnBody(),
        ),
      ),
    );
  }

  // ─── PAGE HEADER ─────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    const primaryGreen = AppConstants.primaryGreen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon-box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.16),
                    blurRadius: 14,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pill "SOPORTE"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'SOPORTE',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Ayuda',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.2,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Accent divider
        Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryGreen,
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.75),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryGreen.withValues(alpha: 0.38),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Todo lo que necesitas saber sobre BoomBet.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.40),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsAppContactButton() {
    const primaryGreen = AppConstants.primaryGreen;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _openWhatsAppSupport,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.black.withValues(alpha: 0.10),
        highlightColor: Colors.black.withValues(alpha: 0.05),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.42),
                blurRadius: 22,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.16),
                blurRadius: 44,
                spreadRadius: 0,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.whatsapp,
                size: 22,
                color: Colors.black,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 1,
                height: 18,
                color: Colors.black.withValues(alpha: 0.18),
              ),
              const Text(
                'Comunicate con nosotros',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.black,
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black.withValues(alpha: 0.65),
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WEB FAQ LIST ─────────────────────────────────────────────────────────

  Widget _buildFaqListWeb(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 14),
        _buildWhatsAppContactButton(),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildFaqCategoryWeb(
                context,
                icon: Icons.home_outlined,
                title: 'Plataforma',
                items: _platformFaqs,
              ),
              const SizedBox(height: 10),
              _buildFaqCategoryWeb(
                context,
                icon: Icons.local_offer_outlined,
                title: 'Beneficios',
                items: _benefitsFaqs,
              ),
              const SizedBox(height: 10),
              _buildFaqCategoryWeb(
                context,
                icon: Icons.forum_outlined,
                title: 'Foro',
                items: _forumFaqs,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── FAQ SECTION (mobile) ─────────────────────────────────────────────────

  Widget _buildFaqSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    List<Map<String, String>> items = const [],
    bool disabled = false,
  }) {
    const primaryGreen = AppConstants.primaryGreen;
    final hasItems = items.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasItems
          ? Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: primaryGreen.withValues(alpha: 0.06),
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: primaryGreen, size: 16),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
                iconColor: primaryGreen,
                collapsedIconColor: primaryGreen.withValues(alpha: 0.55),
                children: _buildMobileFaqItems(items),
              ),
            )
          : ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: primaryGreen, size: 16),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              trailing: Icon(
                disabled ? Icons.lock_outline : Icons.chevron_right,
                color: disabled
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.35),
              ),
              subtitle: disabled
                  ? Text(
                      'Próximamente',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                      ),
                    )
                  : null,
              onTap: disabled
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Abriendo sección: $title'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
            ),
    );
  }

  List<Widget> _buildMobileFaqItems(List<Map<String, String>> items) {
    const primaryGreen = AppConstants.primaryGreen;
    final result = <Widget>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      result.add(
        Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryGreen.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 5, right: 9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryGreen,
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withValues(alpha: 0.70),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['question'] ?? '',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.50),
                    ),
                    children: _buildAnswerSpans(
                      item['answer'] ?? '',
                      Colors.white.withValues(alpha: 0.50),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return result;
  }

  // ─── FAQ CATEGORY (web) ───────────────────────────────────────────────────

  Widget _buildFaqCategoryWeb(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Map<String, String>> items,
  }) {
    const primaryGreen = AppConstants.primaryGreen;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: primaryGreen.withValues(alpha: 0.06),
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Icon(icon, color: primaryGreen, size: 16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.1,
            ),
          ),
          iconColor: primaryGreen,
          collapsedIconColor: primaryGreen.withValues(alpha: 0.55),
          children: [
            for (int i = 0; i < items.length; i++)
              Container(
                margin: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: primaryGreen.withValues(alpha: 0.06),
                    highlightColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    iconColor: primaryGreen,
                    collapsedIconColor: primaryGreen.withValues(alpha: 0.40),
                    title: Text(
                      items[i]['question'] ?? '',
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              color: Colors.white.withValues(alpha: 0.50),
                            ),
                            children: _buildAnswerSpans(
                              items[i]['answer'] ?? '',
                              Colors.white.withValues(alpha: 0.50),
                            ),
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── POWERED BY PANEL ─────────────────────────────────────────────────────

  Widget _buildPoweredByPanel(BuildContext context) {
    const primaryGreen = AppConstants.primaryGreen;
    final isAndroid =
        !kIsWeb && Theme.of(context).platform == TargetPlatform.android;
    final logoHeight = isAndroid ? 48.0 : 54.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // "POWERED BY" with accent decoration
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        primaryGreen.withValues(alpha: 0.40),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'POWERED BY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryGreen.withValues(alpha: 0.40),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Casino logos
          LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth > 1200
                  ? 20.0
                  : 8.0;
              return Row(
                children: [
                  Expanded(
                    child: _buildPoweredByLogoTile(
                      assetPath: 'assets/images/bplay_logo.webp',
                      url: _bplayPoweredByUrl,
                      logoHeight: logoHeight,
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                  Expanded(
                    child: _buildPoweredByLogoTile(
                      assetPath: 'assets/images/sportsbet_logo.webp',
                      url: _sportsbetPoweredByUrl,
                      logoHeight: logoHeight,
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                  Expanded(
                    child: _buildPoweredByLogoTile(
                      assetPath: 'assets/images/betsson_logo.svg',
                      url: _betssonPoweredByUrl,
                      logoHeight: logoHeight,
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Section divider
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: primaryGreen.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryGreen.withValues(alpha: 0.40),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.50),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: primaryGreen.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Accede a nuestra pagina web',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          // BoomBet logo tap
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _openBoomBetSite,
              borderRadius: BorderRadius.circular(12),
              splashColor: primaryGreen.withValues(alpha: 0.10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  'assets/images/boombetlogo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoweredByLogoTile({
    required String assetPath,
    required String url,
    required double logoHeight,
    required double horizontalPadding,
  }) {
    const primaryGreen = AppConstants.primaryGreen;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _openPoweredBySite(url),
          borderRadius: BorderRadius.circular(12),
          splashColor: primaryGreen.withValues(alpha: 0.10),
          child: Container(
            height: 84,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: assetPath.toLowerCase().endsWith('.svg')
                ? SvgPicture.asset(
                    assetPath,
                    height: logoHeight,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    assetPath,
                    height: logoHeight,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }
}
