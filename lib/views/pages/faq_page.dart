import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    final maxWidth = kIsWeb ? 1400.0 : 800.0;

    Widget buildSingleColumnBody() {
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Ayuda',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildFaqSection(
            context,
            icon: Icons.home,
            title: 'Plataforma',
            cardColor: cardColor,
            textColor: textColor,
            items: _platformFaqs,
          ),
          const SizedBox(height: 12),
          _buildFaqSection(
            context,
            icon: Icons.local_offer,
            title: 'Beneficios',
            cardColor: cardColor,
            textColor: textColor,
            items: _benefitsFaqs,
          ),
          const SizedBox(height: 12),
          _buildFaqSection(
            context,
            icon: Icons.shield,
            title: 'Puntos',
            cardColor: cardColor,
            textColor: textColor,
            disabled: true,
          ),
          const SizedBox(height: 12),
          _buildFaqSection(
            context,
            icon: Icons.article,
            title: 'Actividades',
            cardColor: cardColor,
            textColor: textColor,
            disabled: true,
          ),
          const SizedBox(height: 12),
          _buildFaqSection(
            context,
            icon: Icons.thumb_up,
            title: 'Sorteos',
            cardColor: cardColor,
            textColor: textColor,
            disabled: true,
          ),
          const SizedBox(height: 32),
          _buildPoweredByPanel(
            context,
            cardColor: cardColor,
            textColor: textColor,
            isDark: isDark,
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

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildFaqListWeb(
                    context,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPoweredByPanel(
                    context,
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: const MainAppBar(
        showBackButton: true,
        showLogo: true,
        showFaqButton: false,
      ),
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ResponsiveWrapper(
          maxWidth: maxWidth,
          child: kIsWeb ? buildWebBody() : buildSingleColumnBody(),
        ),
      ),
    );
  }

  Widget _buildFaqListWeb(
    BuildContext context, {
    required Color cardColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ayuda',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildFaqCategoryWeb(
                context,
                icon: Icons.home,
                title: 'Plataforma',
                cardColor: cardColor,
                textColor: textColor,
                items: _platformFaqs,
              ),
              const SizedBox(height: 12),
              _buildFaqCategoryWeb(
                context,
                icon: Icons.local_offer,
                title: 'Beneficios',
                cardColor: cardColor,
                textColor: textColor,
                items: _benefitsFaqs,
              ),
              const SizedBox(height: 12),
              _buildFaqSection(
                context,
                icon: Icons.shield,
                title: 'Puntos',
                cardColor: cardColor,
                textColor: textColor,
                disabled: true,
              ),
              const SizedBox(height: 12),
              _buildFaqSection(
                context,
                icon: Icons.article,
                title: 'Actividades',
                cardColor: cardColor,
                textColor: textColor,
                disabled: true,
              ),
              const SizedBox(height: 12),
              _buildFaqSection(
                context,
                icon: Icons.thumb_up,
                title: 'Sorteos',
                cardColor: cardColor,
                textColor: textColor,
                disabled: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaqCategoryWeb(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color cardColor,
    required Color textColor,
    required List<Map<String, String>> items,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(icon, color: primary),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          iconColor: primary,
          collapsedIconColor: primary,
          children: [
            for (final item in items)
              Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : AppConstants.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
                  ),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  title: Text(
                    item['question'] ?? '',
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.25,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: textColor,
                          ),
                          children: _buildAnswerSpans(
                            item['answer'] ?? '',
                            textColor,
                          ),
                        ),
                        softWrap: true,
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

  Widget _buildPoweredByPanel(
    BuildContext context, {
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'POWERED BY',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openPoweredBySite(_bplayPoweredByUrl),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.transparent
                              : AppConstants.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/bplay_logo.webp',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openPoweredBySite(_sportsbetPoweredByUrl),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.transparent
                              : AppConstants.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/sportsbet_logo.webp',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            'Accede a nuestra pagina web!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openBoomBetSite,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Image.asset(
                  'assets/images/boombetlogo.png',
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color cardColor,
    required Color textColor,
    List<Map<String, String>> items = const [],
    bool disabled = false,
  }) {
    final hasItems = items.isNotEmpty;

    return Container(
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
      child: hasItems
          ? Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                leading: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                iconColor: Theme.of(context).colorScheme.primary,
                collapsedIconColor: Theme.of(context).colorScheme.primary,
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['question'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: textColor,
                                ),
                                children: _buildAnswerSpans(
                                  item['answer'] ?? '',
                                  textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
          : ListTile(
              leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              trailing: Icon(
                disabled ? Icons.lock_outline : Icons.chevron_right,
                color: textColor.withValues(alpha: disabled ? 0.3 : 0.5),
              ),
              subtitle: disabled
                  ? Text(
                      'Próximamente',
                      style: TextStyle(color: textColor, fontSize: 13),
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
}
