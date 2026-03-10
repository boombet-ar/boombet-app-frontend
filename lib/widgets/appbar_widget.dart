import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/other/faq_page.dart';
import 'package:boombet_app/views/pages/auth/login_page.dart';
import 'package:boombet_app/views/pages/profile/profile_page.dart';
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greenColor = theme.colorScheme.primary;
    const appBarBg = Colors.black38;

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

    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: appBarBg,
      leading: null,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          if (showMenuButton)
            IconButton(
              icon: Icon(Icons.menu, color: greenColor),
              tooltip: 'Menú',
              onPressed: onMenuPressed,
            ),
          // Solo mostrar botón de volver o salir si no es web o si es botón de volver
          if (showBackButton || (!kIsWeb && showExitButton))
            IconButton(
              icon: Icon(
                showBackButton ? Icons.arrow_back : Icons.exit_to_app,
                color: greenColor,
              ),
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
          if (showLogoutButton)
            IconButton(
              key: logoutTutorialTargetKey,
              icon: Icon(Icons.logout, color: greenColor),
              tooltip: 'Cerrar Sesión',
              onPressed: () async {
                // Mostrar diálogo de confirmación
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: Text(
                      '¿Cerrar sesión?',
                      style: const TextStyle(color: AppConstants.textDark),
                    ),
                    content: Text(
                      '¿Estás seguro de que deseas cerrar sesión?',
                      style: const TextStyle(color: AppConstants.textDark),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(color: greenColor),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: greenColor),
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
          if (showSettings && !kIsWeb)
            Tooltip(
              message: 'Configuración',
              child: IconButton(
                key: settingsTutorialTargetKey,
                icon: Icon(Icons.settings, color: greenColor),
                tooltip: '',
                onPressed: () {
                  Navigator.push(context, FadeRoute(page: SettingsPage()));
                },
              ),
            ),
          if (showQrScannerButton && !kIsWeb)
            Tooltip(
              message: 'Escanear QR',
              child: IconButton(
                icon: Icon(Icons.qr_code_scanner, color: greenColor),
                tooltip: '',
                onPressed: () {
                  Navigator.push(
                    context,
                    FadeRoute(page: const QrScannerPage()),
                  );
                },
              ),
            ),
          if (showProfileButton)
            Tooltip(
              message: 'Ver perfil',
              child: IconButton(
                key: profileTutorialTargetKey,
                icon: Icon(Icons.person, color: greenColor),
                tooltip: '',
                onPressed: () {
                  Navigator.push(context, ScaleRoute(page: ProfilePage()));
                },
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
                return Tooltip(
                  message: 'Herramientas admin',
                  child: IconButton(
                    icon: Icon(Icons.build, color: greenColor),
                    tooltip: '',
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
                return Tooltip(
                  message: 'Herramientas afiliador',
                  child: IconButton(
                    icon: Icon(Icons.insights_outlined, color: greenColor),
                    tooltip: '',
                    onPressed: () {
                      context.go('/affiliates-tools');
                    },
                  ),
                );
              },
            ),
          if (showFaqButton)
            Tooltip(
              message: 'Ayuda y preguntas frecuentes',
              child: IconButton(
                key: faqTutorialTargetKey,
                icon: Icon(Icons.help_outline, color: greenColor),
                tooltip: '',
                onPressed: () {
                  Navigator.push(context, FadeRoute(page: const FaqPage()));
                },
              ),
            ),
          Spacer(),
          if (showLogo)
            Padding(
              padding: EdgeInsets.only(right: 8.0),
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
      actions: [],
    );
  }
}
