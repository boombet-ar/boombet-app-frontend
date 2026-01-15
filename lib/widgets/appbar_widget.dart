import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/faq_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/views/pages/profile_page.dart';
import 'package:boombet_app/views/pages/settings_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final bool showThemeToggle;

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
    this.showThemeToggle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final greenColor = theme.colorScheme.primary;
    final appBarBg = isDark ? Colors.black38 : AppConstants.lightSurfaceVariant;

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
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      backgroundColor: appBarBg,
      leading: null,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
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
                  Navigator.of(context).pop();
                } else {
                  SystemNavigator.pop();
                }
              },
            ),
          if (showLogoutButton)
            IconButton(
              icon: Icon(Icons.logout, color: greenColor),
              tooltip: 'Cerrar Sesión',
              onPressed: () async {
                // Mostrar diálogo de confirmación
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDark
                        ? const Color(0xFF1A1A1A)
                        : AppConstants.lightDialogBg,
                    title: Text(
                      '¿Cerrar sesión?',
                      style: TextStyle(
                        color: isDark
                            ? AppConstants.textDark
                            : AppConstants.lightLabelText,
                      ),
                    ),
                    content: Text(
                      '¿Estás seguro de que deseas cerrar sesión?',
                      style: TextStyle(
                        color: isDark
                            ? AppConstants.textDark
                            : AppConstants.lightLabelText,
                      ),
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
                icon: Icon(Icons.settings, color: greenColor),
                tooltip: '',
                onPressed: () {
                  Navigator.push(context, FadeRoute(page: SettingsPage()));
                },
              ),
            ),
          if (showProfileButton)
            Tooltip(
              message: 'Ver perfil',
              child: IconButton(
                icon: Icon(Icons.person, color: greenColor),
                tooltip: '',
                onPressed: () {
                  Navigator.push(context, ScaleRoute(page: ProfilePage()));
                },
              ),
            ),
          if (showFaqButton)
            Tooltip(
              message: 'Ayuda y preguntas frecuentes',
              child: IconButton(
                icon: Icon(Icons.help_outline, color: greenColor),
                tooltip: '',
                onPressed: () {
                  Navigator.push(context, FadeRoute(page: const FaqPage()));
                },
              ),
            ),
          if (showThemeToggle) const SizedBox.shrink(),
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
