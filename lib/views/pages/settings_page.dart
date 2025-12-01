import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/views/pages/error_testing_page.dart';
import 'package:boombet_app/views/pages/faq_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/views/pages/profile_page.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final bool _notificacionesGenerales = true;
  final bool _notificacionesPromociones = true;
  final bool _notificacionesEventos = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppConstants.darkCardBg
        : AppConstants.lightCardBg;

    return Scaffold(
      appBar: const MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: true,
        showProfileButton: false,
        showFaqButton: false,
        showThemeToggle: false,
      ),
      body: ResponsiveWrapper(
        maxWidth: 800,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección: Cuenta y Perfil
              _buildSectionTitle('Cuenta y Perfil', Icons.person),
              const SizedBox(height: 8),
              _buildSettingsTile(
                context: context,
                icon: Icons.account_circle,
                title: 'Ver Perfil',
                subtitle: 'Información personal y documentación',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                surfaceColor: surfaceColor,
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.lock,
                title: 'Cambiar Contraseña',
                subtitle: 'Actualiza tu contraseña de acceso',
                onTap: null,
                surfaceColor: surfaceColor,
                enabled: false,
              ),
              const SizedBox(height: 24),

              // Sección: Apariencia
              _buildSectionTitle('Apariencia', Icons.palette),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: Card(
                  color: surfaceColor,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isLightModeNotifier,
                    builder: (context, isLightMode, _) {
                      return SwitchListTile(
                        secondary: Icon(
                          isLightMode ? Icons.light_mode : Icons.dark_mode,
                          color: AppConstants.primaryGreen,
                        ),
                        title: const Text('Modo Claro'),
                        subtitle: Text(
                          isLightMode ? 'Activado' : 'Desactivado',
                        ),
                        value: isLightMode,
                        activeThumbColor: AppConstants.primaryGreen,
                        onChanged: (value) {
                          isLightModeNotifier.value = value;
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: surfaceColor,
                child: ListTile(
                  enabled: false,
                  leading: Icon(
                    Icons.language,
                    color: AppConstants.primaryGreen.withValues(alpha: 0.5),
                  ),
                  title: const Text('Idioma'),
                  subtitle: const Text('Español'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: null,
                ),
              ),
              const SizedBox(height: 24),

              // Sección: Notificaciones
              _buildSectionTitle('Notificaciones', Icons.notifications),
              const SizedBox(height: 8),
              Card(
                color: surfaceColor,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        Icons.notifications_active,
                        color: AppConstants.primaryGreen.withValues(alpha: 0.5),
                      ),
                      title: const Text('Notificaciones Generales'),
                      subtitle: const Text('Alertas y actualizaciones'),
                      value: _notificacionesGenerales,
                      activeThumbColor: AppConstants.primaryGreen,
                      onChanged: null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(
                        Icons.local_offer,
                        color: AppConstants.primaryGreen.withValues(alpha: 0.5),
                      ),
                      title: const Text('Promociones'),
                      subtitle: const Text('Ofertas y descuentos especiales'),
                      value: _notificacionesPromociones,
                      activeThumbColor: AppConstants.primaryGreen,
                      onChanged: null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(
                        Icons.event,
                        color: AppConstants.primaryGreen.withValues(alpha: 0.5),
                      ),
                      title: const Text('Eventos y Sorteos'),
                      subtitle: const Text('Notificaciones de participación'),
                      value: _notificacionesEventos,
                      activeThumbColor: AppConstants.primaryGreen,
                      onChanged: null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sección: Privacidad y Seguridad
              _buildSectionTitle('Privacidad y Seguridad', Icons.security),
              const SizedBox(height: 8),
              _buildSettingsTile(
                context: context,
                icon: Icons.fingerprint,
                title: 'Autenticación Biométrica',
                subtitle: 'Usa huella digital o Face ID',
                onTap: null,
                surfaceColor: surfaceColor,
                enabled: false,
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.shield,
                title: 'Privacidad',
                subtitle: 'Gestiona tus datos personales',
                onTap: null,
                surfaceColor: surfaceColor,
                enabled: false,
              ),
              const SizedBox(height: 24),

              // Sección: Información y Soporte
              _buildSectionTitle('Información y Soporte', Icons.help_outline),
              const SizedBox(height: 8),
              _buildSettingsTile(
                context: context,
                icon: Icons.help_outline,
                title: 'Preguntas Frecuentes (FAQ)',
                subtitle: 'Encuentra respuestas a tus dudas',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FaqPage()),
                  );
                },
                surfaceColor: surfaceColor,
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.description,
                title: 'Términos y Condiciones',
                subtitle: 'Lee nuestros términos de uso',
                onTap: null,
                surfaceColor: surfaceColor,
                enabled: false,
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.info,
                title: 'Acerca de BoomBet',
                subtitle: 'Versión 1.0.0',
                onTap: () {
                  _showAboutDialog(context);
                },
                surfaceColor: surfaceColor,
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.bug_report,
                title: '🧪 Testing de Errores HTTP',
                subtitle: 'Probar sistema de manejo de errores',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ErrorTestingPage(),
                    ),
                  );
                },
                surfaceColor: surfaceColor,
              ),
              const SizedBox(height: 24),

              // Botón de Cerrar Sesión
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await _showLogoutConfirmation(context);
                    if (!confirmed || !context.mounted) return;
                    await TokenService.deleteToken();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: AppConstants.lightCardBg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppConstants.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required Color? surfaceColor,
    bool enabled = true,
  }) {
    return Card(
      color: surfaceColor,
      child: ListTile(
        enabled: enabled,
        leading: Icon(
          icon,
          color: enabled
              ? AppConstants.primaryGreen
              : AppConstants.primaryGreen.withValues(alpha: 0.5),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: enabled ? onTap : null,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark
        ? AppConstants.darkAccent
        : AppConstants.lightDialogBg;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('Acerca de BoomBet', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versión: 1.0.0', style: TextStyle(color: textColor)),
            const SizedBox(height: 8),
            Text(
              'BoomBet - Tu plataforma de afiliación a casinos de confianza.',
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2024 BoomBet. Todos los derechos reservados.',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(color: AppConstants.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark
        ? AppConstants.darkAccent
        : AppConstants.lightDialogBg;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('Cerrar Sesión', style: TextStyle(color: textColor)),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.primaryGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
