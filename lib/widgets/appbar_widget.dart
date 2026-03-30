import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/auth/login_page.dart';
import 'package:boombet_app/views/pages/home/home_keys.dart';
import 'package:boombet_app/views/pages/other/qr_scanner_page.dart';
import 'package:boombet_app/views/pages/profile/settings_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showSettings;
  final bool showLogo;
  final bool showBackButton;
  final bool showProfileButton;
  final bool showLogoutButton;
  final bool showFaqButton;
  final bool showExitButton;
  final bool showAdminTools;
  final bool showAffiliatesTools;
  final bool showQrScannerButton;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBackPressed;
  final GlobalKey? faqTutorialTargetKey;
  final GlobalKey? profileTutorialTargetKey;
  final GlobalKey? settingsTutorialTargetKey;
  final GlobalKey? logoutTutorialTargetKey;

  const MainAppBar({
    super.key,
    this.title,
    this.showSettings = false,
    this.showLogo = false,
    this.showBackButton = false,
    this.showProfileButton = false,
    this.showLogoutButton = false,
    this.showFaqButton = true,
    this.showExitButton = true,
    this.showAdminTools = true,
    this.showAffiliatesTools = true,
    this.showQrScannerButton = false,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.onBackPressed,
    this.faqTutorialTargetKey,
    this.profileTutorialTargetKey,
    this.settingsTutorialTargetKey,
    this.logoutTutorialTargetKey,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greenColor = theme.colorScheme.primary;

    // Helper: icono de navegación con contenedor oscuro y borde neon
    Widget navBtn({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
      Key? widgetKey,
      double iconSize = 19,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: widgetKey,
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: greenColor.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(icon, color: greenColor, size: iconSize),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> openBoomBetSite() async {
      final uri = Uri.parse('https://boombet-ar.bet');
      final ok = await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_blank' : null,
      );
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo abrir el sitio.'),
            backgroundColor: AppConstants.warningOrange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backgroundColor: const Color(0xFF080808),
          elevation: 0,
          leading: null,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              if (showMenuButton)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: navBtn(
                    icon: Icons.menu_rounded,
                    tooltip: 'Menú',
                    onPressed: onMenuPressed,
                  ),
                ),
              if (showBackButton || (!kIsWeb && showExitButton))
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: navBtn(
                    icon: showBackButton
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.exit_to_app_rounded,
                    tooltip: showBackButton ? 'Volver' : 'Salir',
                    onPressed: () {
                      if (showBackButton) {
                        if (onBackPressed != null) {
                          onBackPressed!();
                          return;
                        }
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      } else {
                        SystemNavigator.pop();
                      }
                    },
                  ),
                ),
              if (showLogoutButton)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: navBtn(
                    widgetKey: logoutTutorialTargetKey,
                    icon: Icons.logout_rounded,
                    tooltip: 'Cerrar Sesión',
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF0E0E0E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: greenColor.withValues(alpha: 0.20),
                              width: 1,
                            ),
                          ),
                          title: const Text(
                            '¿Cerrar sesión?',
                            style: TextStyle(
                              color: AppConstants.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: const Text(
                            '¿Estás seguro de que deseas cerrar sesión?',
                            style: TextStyle(
                              color: AppConstants.textDark,
                              fontSize: 13,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: greenColor.withValues(alpha: 0.70),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(
                                right: 8,
                                bottom: 4,
                              ),
                              decoration: BoxDecoration(
                                color: greenColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: greenColor.withValues(alpha: 0.30),
                                  width: 1,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Cerrar Sesión',
                                  style: TextStyle(
                                    color: greenColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        final authService = AuthService();
                        await authService.logout();

                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            FadeRoute(page: const LoginPage()),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ),
              if (showSettings && !kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: navBtn(
                    widgetKey: settingsTutorialTargetKey,
                    icon: Icons.settings_rounded,
                    tooltip: 'Configuración',
                    onPressed: () {
                      Navigator.push(
                        context,
                        FadeRoute(page: SettingsPage()),
                      );
                    },
                  ),
                ),
              if (showQrScannerButton)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: navBtn(
                    icon: Icons.qr_code_scanner_rounded,
                    tooltip: 'Escanear QR',
                    onPressed: () {
                      Navigator.push(
                        context,
                        FadeRoute(page: const QrScannerPage()),
                      );
                    },
                  ),
                ),
              if (showProfileButton)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: navBtn(
                    widgetKey: profileTutorialTargetKey,
                    icon: Icons.person_rounded,
                    tooltip: 'Ver perfil',
                    onPressed: () => context.go(HomePageKeys.profile),
                  ),
                ),
              if (showAdminTools)
                FutureBuilder<List<bool>>(
                  future: Future.wait([
                    TokenService.hasActiveSession(),
                    TokenService.isAdmin(),
                  ]),
                  builder: (context, snapshot) {
                    final results = snapshot.data;
                    final hasSession = results != null && results.isNotEmpty
                        ? results[0]
                        : false;
                    final isAdmin = results != null && results.length > 1
                        ? results[1]
                        : false;
                    if (!hasSession || !isAdmin) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: navBtn(
                        icon: Icons.build_rounded,
                        tooltip: 'Herramientas admin',
                        onPressed: () {
                          context.go('/admin-tools');
                        },
                      ),
                    );
                  },
                ),
              if (showAffiliatesTools)
                FutureBuilder<List<dynamic>>(
                  future: Future.wait<dynamic>([
                    TokenService.hasActiveSession(),
                    TokenService.getUserRole(),
                  ]),
                  builder: (context, snapshot) {
                    final results = snapshot.data;
                    final hasSession = results != null && results.isNotEmpty
                        ? (results[0] as bool? ?? false)
                        : false;
                    final role = results != null && results.length > 1
                        ? (results[1] as String?)
                        : null;
                    final isAffiliator =
                        role != null && role.toUpperCase() == 'AFILIADOR';
                    if (!hasSession || !isAffiliator) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: navBtn(
                        icon: Icons.insights_outlined,
                        tooltip: 'Herramientas afiliador',
                        onPressed: () {
                          context.go('/affiliates-tools');
                        },
                      ),
                    );
                  },
                ),
              if (showFaqButton)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: navBtn(
                    widgetKey: faqTutorialTargetKey,
                    icon: Icons.help_outline_rounded,
                    tooltip: 'Ayuda y preguntas frecuentes',
                    onPressed: () => context.push(HomePageKeys.faq),
                  ),
                ),
              const Spacer(),
              if (showLogo)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Hero(
                    tag: 'boombet_logo',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: openBoomBetSite,
                        child: Image.asset(
                          'assets/images/boombetlogo.png',
                          height: 80,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          actions: const [],
        ),
        // Línea separadora neon
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                greenColor.withValues(alpha: 0.25),
                greenColor.withValues(alpha: 0.50),
                greenColor.withValues(alpha: 0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
