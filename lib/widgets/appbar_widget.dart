import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/views/pages/faq_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/views/pages/profile_page.dart';
import 'package:boombet_app/views/pages/settings_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final appBarBg = isDark ? Colors.black38 : const Color(0xFFE8E8E8);

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
                        : Colors.white,
                    title: Text(
                      '¿Cerrar sesión?',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFE0E0E0)
                            : Colors.black87,
                      ),
                    ),
                    content: Text(
                      '¿Estás seguro de que deseas cerrar sesión?',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFE0E0E0)
                            : Colors.black87,
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
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          if (showSettings)
            IconButton(
              icon: Icon(Icons.settings, color: greenColor),
              tooltip: 'Configuración',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return SettingsPage();
                    },
                  ),
                );
              },
            ),
          if (showProfileButton)
            IconButton(
              icon: Icon(Icons.person, color: greenColor),
              tooltip: "Perfil",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ProfilePage();
                    },
                  ),
                );
              },
            ),
          if (showFaqButton)
            IconButton(
              icon: Icon(Icons.help_outline, color: greenColor),
              tooltip: "Ayuda / FAQ",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const FaqPage();
                    },
                  ),
                );
              },
            ),
          if (showThemeToggle)
            RepaintBoundary(
              child: IconButton(
                icon: ValueListenableBuilder<bool>(
                  valueListenable: isLightModeNotifier,
                  builder: (context, isLightMode, child) {
                    return Icon(
                      isLightMode ? Icons.dark_mode : Icons.light_mode,
                      color: greenColor,
                    );
                  },
                ),
                tooltip: "Modo Claro",
                onPressed: () {
                  isLightModeNotifier.value = !isLightModeNotifier.value;
                },
              ),
            ),
          Spacer(),
          if (showLogo)
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Image.asset('assets/images/boombetlogo.png', height: 80),
            ),
        ],
      ),
      actions: [],
    );
  }
}
