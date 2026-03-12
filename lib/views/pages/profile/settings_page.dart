import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/views/pages/other/faq_page.dart';
import 'package:boombet_app/views/pages/other/debug_views_menu_page.dart';
import 'package:boombet_app/views/pages/auth/forget_password_page.dart';
import 'package:boombet_app/views/pages/home/limited_home_page.dart';
import 'package:boombet_app/views/pages/auth/login_page.dart';
import 'package:boombet_app/views/pages/profile/profile_page.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/biometric_service.dart';
import 'package:boombet_app/services/notification_service.dart';
import 'package:boombet_app/services/push_notification_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _bioEnabled = false;
  bool _bioAvailable = true;
  bool _bioLoading = true;
  bool _bioToggling = false;

  bool _pushEnabled = true;
  bool _adsPushEnabled = true;
  bool _forumPushEnabled = true;
  bool _pushLoading = true;
  bool _pushToggling = false;
  bool _pushSubToggling = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    _loadPushState();
  }

  Future<void> _loadPushState() async {
    final results = await Future.wait<bool>([
      PushNotificationService.isNotificationsEnabled(),
      PushNotificationService.isAdsNotificationsEnabled(),
      PushNotificationService.isForumNotificationsEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _pushEnabled = results[0];
      _adsPushEnabled = results[1];
      _forumPushEnabled = results[2];
      _pushLoading = false;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _togglePushNotifications(bool nextEnabled) async {
    if (_pushLoading || _pushToggling) return;

    final previousEnabled = _pushEnabled;
    setState(() {
      _pushToggling = true;
      _pushEnabled = nextEnabled;
    });

    try {
      await PushNotificationService.setNotificationsEnabled(nextEnabled);

      // Si se habilita, reenviar token al backend (si hay sesión/JWT).
      if (nextEnabled) {
        await const NotificationService().saveFcmTokenToBackend();
      }

      _showSnack(
        nextEnabled
            ? 'Notificaciones activadas'
            : 'Notificaciones desactivadas',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _pushEnabled = previousEnabled);
      _showSnack('Error actualizando notificaciones: $e');
    } finally {
      if (mounted) setState(() => _pushToggling = false);
    }
  }

  Future<void> _toggleAdsNotifications(bool nextEnabled) async {
    if (_pushLoading || _pushToggling || _pushSubToggling || !_pushEnabled) {
      return;
    }

    setState(() => _pushSubToggling = true);

    try {
      await PushNotificationService.setAdsNotificationsEnabled(nextEnabled);
      if (!mounted) return;
      setState(() => _adsPushEnabled = nextEnabled);
      _showSnack(
        nextEnabled
            ? 'Notificaciones de publicidades activadas'
            : 'Notificaciones de publicidades desactivadas',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error actualizando publicidades: $e');
    } finally {
      if (mounted) setState(() => _pushSubToggling = false);
    }
  }

  Future<void> _toggleForumNotifications(bool nextEnabled) async {
    if (_pushLoading || _pushToggling || _pushSubToggling || !_pushEnabled) {
      return;
    }

    setState(() => _pushSubToggling = true);

    try {
      await PushNotificationService.setForumNotificationsEnabled(nextEnabled);
      if (!mounted) return;
      setState(() => _forumPushEnabled = nextEnabled);
      _showSnack(
        nextEnabled
            ? 'Notificaciones de foro activadas'
            : 'Notificaciones de foro desactivadas',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error actualizando foro: $e');
    } finally {
      if (mounted) setState(() => _pushSubToggling = false);
    }
  }

  Future<void> _loadBiometricState() async {
    final available = await BiometricService.isDeviceEligible();
    final enabled = available ? await BiometricService.isEnabled() : false;
    if (!mounted) return;
    setState(() {
      _bioAvailable = available;
      _bioEnabled = enabled;
      _bioLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_bioAvailable) return;
    setState(() => _bioToggling = true);

    if (value) {
      final ok = await BiometricService.enableWithPrompt(
        reason: 'Confirma para activar biometría',
      );
      if (mounted) setState(() => _bioEnabled = ok);
    } else {
      await BiometricService.disableBiometric();
      if (mounted) setState(() => _bioEnabled = false);
    }

    if (mounted) setState(() => _bioToggling = false);
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppConstants.darkCardBg;

    return Scaffold(
      appBar: const MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: true,
        showProfileButton: false,
        showFaqButton: false,
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
                icon: Icons.account_circle_outlined,
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
              const SizedBox(height: 8),
              _buildSettingsTile(
                context: context,
                icon: Icons.lock_outline_rounded,
                title: 'Cambiar Contraseña',
                subtitle: 'Actualiza tu contraseña de acceso',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgetPasswordPage(),
                    ),
                  );
                },
                surfaceColor: surfaceColor,
              ),
              // _buildSettingsTile(
              //   context: context,
              //   icon: Icons.visibility,
              //   title: 'Preview Limited Home',
              //   subtitle: 'Abrir vista limitada sin proceso de afiliación',
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => LimitedHomePage(
              //            affiliationService: AffiliationService(),
              //           preview: true,
              //           previewStatusMessage:
              //                'Vista previa para edición visual',
              //         ),
              //        ),
              //     );
              //   },
              //   surfaceColor: surfaceColor,
              //  ), //Descomentar para activar boton a preview de limited home
              const SizedBox(height: 24),
              _buildSectionTitle('Seguridad', Icons.shield_outlined),
              const SizedBox(height: 8),

              // Biometría
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.primaryGreen.withValues(
                      alpha: _bioAvailable ? 0.14 : 0.07,
                    ),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    splashColor: AppConstants.primaryGreen.withValues(
                      alpha: 0.06,
                    ),
                    onTap: _bioToggling || !_bioAvailable
                        ? null
                        : () => _toggleBiometric(!_bioEnabled),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryGreen.withValues(
                                alpha: _bioAvailable ? 0.12 : 0.05,
                              ),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: AppConstants.primaryGreen.withValues(
                                  alpha: _bioAvailable ? 0.22 : 0.08,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.fingerprint,
                              color: _bioAvailable
                                  ? AppConstants.primaryGreen
                                  : AppConstants.primaryGreen.withValues(
                                      alpha: 0.4,
                                    ),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Biometría',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: _bioAvailable
                                        ? AppConstants.textDark
                                        : AppConstants.textDark.withValues(
                                            alpha: 0.5,
                                          ),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _bioAvailable
                                      ? (_bioEnabled
                                            ? 'Activada'
                                            : 'Desactivada')
                                      : 'No disponible en este dispositivo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppConstants.textDark.withValues(
                                      alpha: _bioAvailable ? 0.50 : 0.30,
                                    ),
                                    letterSpacing: 0.05,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _bioLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppConstants.primaryGreen.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                )
                              : Switch(
                                  value: _bioEnabled,
                                  activeColor: AppConstants.primaryGreen,
                                  onChanged: _bioToggling || !_bioAvailable
                                      ? null
                                      : _toggleBiometric,
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sección: Notificaciones
              _buildSectionTitle('Notificaciones', Icons.notifications),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.14),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryGreen.withValues(alpha: 0.05),
                      blurRadius: 14,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pushLoading || _pushToggling
                            ? null
                            : () {
                                _togglePushNotifications(!_pushEnabled);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppConstants.primaryGreen.withValues(
                                  alpha: 0.1,
                                ),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryGreen.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppConstants.primaryGreen.withValues(
                                      alpha: 0.22,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  _pushEnabled
                                      ? Icons.notifications_active_outlined
                                      : Icons.notifications_off_outlined,
                                  color: AppConstants.primaryGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notificaciones',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppConstants.textDark,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _pushEnabled
                                          ? 'Todas las notificaciones activadas'
                                          : 'Todas las notificaciones desactivadas',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppConstants.textDark.withValues(
                                          alpha: 0.65,
                                        ),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 50,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: _pushEnabled
                                      ? AppConstants.primaryGreen
                                      : Colors.grey.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Align(
                                  alignment: _pushEnabled
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Publicidades
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            (_pushLoading ||
                                _pushToggling ||
                                _pushSubToggling ||
                                !_pushEnabled)
                            ? null
                            : () {
                                _toggleAdsNotifications(!_adsPushEnabled);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppConstants.primaryGreen.withValues(
                                  alpha: 0.10,
                                ),
                                width: 1,
                              ),
                            ),
                            color: _pushEnabled
                                ? Colors.transparent
                                : Colors.grey.withValues(alpha: 0.02),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _pushEnabled
                                      ? AppConstants.primaryGreen.withValues(
                                          alpha: 0.12,
                                        )
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _pushEnabled
                                        ? AppConstants.primaryGreen.withValues(
                                            alpha: 0.22,
                                          )
                                        : Colors.grey.withValues(alpha: 0.12),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.campaign_outlined,
                                  color: _pushEnabled
                                      ? AppConstants.primaryGreen
                                      : Colors.grey.withValues(alpha: 0.4),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Publicidades y promociones',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _pushEnabled
                                            ? AppConstants.textDark
                                            : AppConstants.textDark.withValues(
                                                alpha: 0.4,
                                              ),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Recibí avisos de promos y descuentos',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _pushEnabled
                                            ? AppConstants.textDark.withValues(
                                                alpha: 0.50,
                                              )
                                            : AppConstants.textDark.withValues(
                                                alpha: 0.22,
                                              ),
                                        letterSpacing: 0.05,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (!_pushEnabled)
                                Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Colors.grey.withValues(alpha: 0.5),
                                )
                              else
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 48,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: _adsPushEnabled
                                        ? AppConstants.primaryGreen
                                        : Colors.grey.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Align(
                                    alignment: _adsPushEnabled
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(1.5),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Foro
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            (_pushLoading ||
                                _pushToggling ||
                                _pushSubToggling ||
                                !_pushEnabled)
                            ? null
                            : () {
                                _toggleForumNotifications(!_forumPushEnabled);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _pushEnabled
                                ? Colors.transparent
                                : Colors.grey.withValues(alpha: 0.02),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _pushEnabled
                                      ? AppConstants.primaryGreen.withValues(
                                          alpha: 0.12,
                                        )
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _pushEnabled
                                        ? AppConstants.primaryGreen.withValues(
                                            alpha: 0.22,
                                          )
                                        : Colors.grey.withValues(alpha: 0.12),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.forum_outlined,
                                  color: _pushEnabled
                                      ? AppConstants.primaryGreen
                                      : Colors.grey.withValues(alpha: 0.4),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Foro',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _pushEnabled
                                            ? AppConstants.textDark
                                            : AppConstants.textDark.withValues(
                                                alpha: 0.4,
                                              ),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Recibí respuestas y actividad del foro',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _pushEnabled
                                            ? AppConstants.textDark.withValues(
                                                alpha: 0.50,
                                              )
                                            : AppConstants.textDark.withValues(
                                                alpha: 0.22,
                                              ),
                                        letterSpacing: 0.05,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (!_pushEnabled)
                                Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Colors.grey.withValues(alpha: 0.5),
                                )
                              else
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 48,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: _forumPushEnabled
                                        ? AppConstants.primaryGreen
                                        : Colors.grey.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Align(
                                    alignment: _forumPushEnabled
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(1.5),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Sección: Información y Soporte
              _buildSectionTitle('Información y Soporte', Icons.help_outline),
              const SizedBox(height: 8),
              _buildSettingsTile(
                context: context,
                icon: Icons.help_outline_rounded,
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
              const SizedBox(height: 8),
              _buildSettingsTile(
                context: context,
                icon: Icons.description_outlined,
                title: 'Legales',
                subtitle: 'Consulta documentos legales',
                onTap: () {
                  _showLegalsDialog(context);
                },
                surfaceColor: surfaceColor,
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                context: context,
                icon: Icons.info_outline_rounded,
                title: 'Acerca de BoomBet',
                subtitle: 'Versión 1.0.0',
                onTap: () {
                  _showAboutDialog(context);
                },
                surfaceColor: surfaceColor,
              ),
              if (AppConstants.debugViewsMenuEnabled) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Debug', Icons.bug_report_outlined),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.developer_mode_outlined,
                  title: 'Debug Views Menu',
                  subtitle: 'Acceso rapido a vistas de pages con mocks',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DebugViewsMenuPage(),
                      ),
                    );
                  },
                  surfaceColor: surfaceColor,
                ),
              ],
              const SizedBox(height: 24),

              // Botón de Cerrar Sesión
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade700],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final confirmed = await _showLogoutConfirmation(
                            context,
                          );
                          if (!confirmed || !context.mounted) return;
                          await AuthService().logout();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, size: 20, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                'Cerrar Sesión',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
    const accent = AppConstants.primaryGreen;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
                color: accent.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Icon(icon, size: 17, color: accent),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 0.3,
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

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required Color? surfaceColor,
    bool enabled = true,
  }) {
    const accent = AppConstants.primaryGreen;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: enabled ? 0.14 : 0.07),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          splashColor: accent.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: enabled ? 0.12 : 0.05),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: accent.withValues(alpha: enabled ? 0.22 : 0.08),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? accent : accent.withValues(alpha: 0.4),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? AppConstants.textDark
                              : AppConstants.textDark.withValues(alpha: 0.5),
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: enabled
                              ? AppConstants.textDark.withValues(alpha: 0.50)
                              : AppConstants.textDark.withValues(alpha: 0.25),
                          letterSpacing: 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: enabled
                      ? accent.withValues(alpha: 0.50)
                      : accent.withValues(alpha: 0.18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    const dialogBg = AppConstants.darkAccent;
    const textColor = AppConstants.textDark;
    const surface = AppConstants.darkAccent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Image.asset(
                  'assets/images/boombetlogo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Acerca de BoomBet',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppConstants.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Versión 1.0',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'BoomBet es el primer portal de Casinos Online en Argentina.',
              style: TextStyle(
                color: textColor,
                height: 1.5,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2025 BoomBet. Todos los derechos reservados.',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 12,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    child: Text(
                      'Cerrar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppConstants.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    const dialogBg = AppConstants.darkAccent;
    const textColor = AppConstants.textDark;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_outlined, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            Text(
              'Cerrar Sesión',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión? Tendrás que iniciar sesión nuevamente.',
          style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: AppConstants.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade700],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context, true),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showLegalsDialog(BuildContext context) {
    const dialogBg = AppConstants.darkAccent;
    const textColor = AppConstants.textDark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description,
                color: AppConstants.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Documentos Legales',
              style: TextStyle(
                color: AppConstants.primaryGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consulta nuestros documentos legales:',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    height: 1.4,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 18),
                _buildLegalsButton(
                  context,
                  title: 'Términos y Condiciones',
                  icon: Icons.description,
                  onTap: () {
                    Navigator.pop(context);
                    _openLegalDocument('Términos y Condiciones');
                  },
                ),
                const SizedBox(height: 12),
                _buildLegalsButton(
                  context,
                  title: 'Políticas de Privacidad',
                  icon: Icons.lock,
                  onTap: () {
                    Navigator.pop(context);
                    _openLegalDocument('Políticas de Privacidad');
                  },
                ),
                const SizedBox(height: 12),
                _buildLegalsButton(
                  context,
                  title: 'Uso de Datos Personales',
                  icon: Icons.data_usage,
                  onTap: () {
                    Navigator.pop(context);
                    _openLegalDocument('Uso de Datos Personales');
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    child: Text(
                      'Cerrar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppConstants.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalsButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    const textColor = AppConstants.textDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppConstants.primaryGreen.withValues(alpha: 0.25),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
            color: AppConstants.primaryGreen.withValues(alpha: 0.06),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppConstants.primaryGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppConstants.primaryGreen.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLegalDocument(String documentType) {
    const dialogBg = AppConstants.darkAccent;
    const textColor = AppConstants.textDark;

    // Obtener el contenido del documento
    final content = _getLegalDocumentContent(documentType);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: dialogBg,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.primaryGreen.withValues(alpha: 0.15),
                    AppConstants.primaryGreen.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: AppConstants.primaryGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          documentType,
                          style: TextStyle(
                            color: AppConstants.primaryGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      height: 1.7,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            color: AppConstants.primaryGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cerrar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppConstants.primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLegalDocumentContent(String documentType) {
    switch (documentType) {
      case 'Términos y Condiciones':
        return '''TÉRMINOS Y CONDICIONES

1. Objeto
El presente documento regula los términos bajo los cuales los usuarios (“Jugadores”) se afilian voluntariamente a la comunidad boombet (www.boombet-ar.com), administrada por WEST DIGITAL ALLIANCE SRL, en adelante “BoomBet”. BoomBet actúa como portal de afiliación e intermediario autorizado para registrar a sus miembros en casinos online y casas de apuestas legales que operen dentro de la República Argentina bajo licencias otorgadas por las autoridades competentes.

2. Afiliación y autorización
Al completar y enviar el formulario de registro, el Jugador:
  - Declara que los datos ingresados son reales, completos y verificables.
  - Acepta afiliarse a la comunidad BoomBet, participar en sus programas, beneficios, sorteos y promociones.
  - Autoriza expresamente a BoomBet a efectuar, en su nombre, en la actualidad y a futuro, los registros o afiliaciones en todos los casinos online y casas de apuestas legales con los que BoomBet mantenga convenios vigentes, incluyendo pero no limitándose a Bplay, Sportsbet y otros operadores licenciados.
  - Reconoce y acepta que dicha autorización implica también la aceptación, en su nombre, de los Términos y Condiciones, Políticas de Privacidad y normas de cada operador, conforme a su jurisdicción.
  - Reconoce y acepta que dicha autorización implica también la aceptación, en su nombre, de los Términos y Condiciones, Políticas de Privacidad y normas de cada operador, conforme a su jurisdicción.

3. Alcance de la representación
BoomBet realiza la gestión administrativa del registro de los Jugadores, sin intervenir en la operación, el juego ni la administración de fondos.
El Jugador entiende y acepta que:
  - Cada casino u operador es único responsable del manejo de cuentas, depósitos, retiros, promociones, límites de juego y cumplimiento normativo.
  - BoomBet no presta servicios de apuestas ni gestiona fondos, sino que actúa únicamente como intermediario de registro y beneficios.
  - Las condiciones de cada casino podrán variar y están sujetas a las políticas propias de cada operador y a la normativa provincial correspondiente.

4. Protección de datos personales
El Jugador autoriza a BoomBet a recopilar, almacenar, usar y transferir sus datos personales exclusivamente para:
  - Gestionar el proceso de afiliación a casinos y operadores asociados.
  - Ofrecer beneficios, sorteos y promociones vinculadas a la comunidad.
Los datos serán tratados conforme a la Ley 25.326 de Protección de Datos Personales y las políticas de privacidad publicadas en www.boombet-ar.com/form .

5. Gratuito y sin obligación
La afiliación a BoomBet es gratuita, legal y sin obligación de compra ni permanencia. El Jugador podrá solicitar su baja de la comunidad BoomBet en cualquier momento escribiendo a info@boombet-ar.com.

6. Bajas y cancelaciones
El Jugador entiende y acepta que:
  - BoomBet solo puede gestionar la baja de la comunidad BoomBet, lo que implica dejar de recibir beneficios, promociones o comunicaciones.
  - La baja de los casinos u operadores afiliados debe ser realizada directamente por el Jugador ante cada entidad, siguiendo los procedimientos establecidos por dichas plataformas.
  - BoomBet no tiene acceso ni autoridad para eliminar, suspender o modificar cuentas dentro de los casinos, ya que cada uno opera bajo su propia licencia y autonomía administrativa.

7. Responsabilidad limitada
BoomBet no asume responsabilidad por:
  - Interrupciones, suspensiones, bloqueos o decisiones tomadas por los casinos u operadores.
  - Errores, demoras o inconvenientes en las acreditaciones, retiros o promociones gestionadas por terceros.
  - Cualquier acción u omisión del Jugador dentro de las plataformas de apuestas.
BoomBet garantiza únicamente la correcta tramitación de las afiliaciones y la gestión de beneficios dentro de su propia comunidad.

8. Comunicaciones y promociones
El Jugador acepta recibir información y comunicaciones relacionadas con beneficios, eventos, novedades o sorteos de la comunidad BoomBet a través de correo electrónico, WhatsApp, Instagram u otros medios digitales. Podrá darse de baja de dichas comunicaciones en cualquier momento mediante los canales habilitados.

9. Modificaciones
BoomBet podrá modificar estos Términos y Condiciones cuando sea necesario.
Las actualizaciones serán publicadas en www.boombet-ar.com/form y entrarán en vigencia a partir de su publicación, considerándose aceptadas si el Jugador continúa participando en la comunidad.

10. Legislación aplicable
Estos Términos y Condiciones se rigen por las leyes de la República Argentina. Para cualquier controversia, las partes se someten a los tribunales ordinarios con jurisdicción en la Ciudad Autónoma de Buenos Aires.
''';
      case 'Políticas de Privacidad':
        return '''POLÍTICAS DE PRIVACIDAD

1. Alcance general
La presente Política de Privacidad complementa los Términos y Condiciones de Afiliación y establece cómo boombet protege la información personal de los usuarios de su comunidad. El solo hecho de registrarse o mantenerse afiliado implica la aceptación de esta política en su totalidad.

2. Finalidad del tratamiento
Los datos personales brindados por los Jugadores son utilizados exclusivamente para:
  - Gestionar su afiliación y registro en casinos online y casas de apuestas legales asociadas.
  - Brindar beneficios, promociones y sorteos dentro de la comunidad BoomBet.
  - Comunicarse con los Jugadores respecto de novedades, cambios y eventos.
  - Cumplir con obligaciones legales o requerimientos regulatorios.
BoomBet no realiza ningún otro tratamiento ajeno a estos fines ni comparte información con terceros fuera de los convenios operativos estrictamente necesarios.

3. Cesión a operadores asociados
El Jugador autoriza a BoomBet a transferir sus datos únicamente a casinos y operadores licenciados con los cuales mantenga acuerdos vigentes, a los fines de procesar su registro y habilitar su cuenta. Cada operador será responsable del uso que haga de dicha información conforme a sus propias políticas, las cuales el Jugador acepta al ser afiliado.

4. Seguridad de la información
BoomBet adopta medidas técnicas y administrativas razonables para preservar la confidencialidad e integridad de la información almacenada. No obstante, los usuarios reconocen que ningún sistema es infalible y liberan a BoomBet de toda responsabilidad por incidentes de seguridad que excedan su control razonable o dependan de terceros operadores.

5. Derechos del usuario
Los Jugadores podrán, en cualquier momento:
  - Acceder a los datos que BoomBet conserva sobre ellos.
  - Solicitar su actualización o corrección.
  - Pedir su eliminación o baja de la comunidad.
  - Revocar el consentimiento para el envío de comunicaciones promocionales.
Dichas solicitudes podrán realizarse mediante correo a info@boombet-ar.com, conforme a los plazos establecidos por la Ley 25.326.

6. Vigencia y modificaciones
BoomBet podrá actualizar esta Política de Privacidad para adaptarla a cambios normativos o tecnológicos. La versión vigente estará siempre disponible en esta misma página, reemplazando automáticamente a las anteriores.
''';
      case 'Uso de Datos Personales':
        return '''USO DE DATOS PERSONALES

1. Principios generales
BoomBet respeta los principios de licitud, finalidad, proporcionalidad, veracidad, seguridad y confidencialidad establecidos por la Ley 25.326 y las buenas prácticas internacionales (RGPD). El tratamiento de datos personales se realiza de manera transparente y con consentimiento informado.

2. Naturaleza de los datos tratados
BoomBet únicamente recopila los datos estrictamente necesarios para cumplir los fines detallados en los Términos y Condiciones y en la Política de Privacidad. Esto incluye información de identificación básica y, eventualmente, datos técnicos mínimos derivados del uso del sitio.

3. Almacenamiento y conservación
Los datos se almacenan en bases seguras administradas por BoomBet y/o proveedores tecnológicos que mantienen acuerdos de confidencialidad. Serán conservados durante el tiempo que dure la relación del usuario con BoomBet o mientras sea necesario para cumplir obligaciones legales o contractuales.

4. Cesión y confidencialidad
BoomBet no vende ni comercializa los datos personales de sus usuarios. Las únicas cesiones permitidas son las necesarias para ejecutar el proceso de afiliación o cumplir requerimientos legales o judiciales. Todo acceso o tratamiento por parte de terceros se rige por acuerdos de confidencialidad y uso limitado a la finalidad específica.

5. Ejercicio de derechos ARCO
Los usuarios pueden ejercer los derechos de Acceso, Rectificación, Cancelación y Oposición (ARCO) en cualquier momento enviando una solicitud formal a info@boombet-ar.com. BoomBet responderá dentro del plazo legal previsto por la normativa argentina.

6. Autoridad de control
El titular de los datos puede, en caso de disconformidad, dirigirse a la Agencia de Acceso a la Información Pública (www.argentina.gob.ar/aaip), organismo responsable del cumplimiento de la Ley 25.326 en la República Argentina.
''';
      default:
        return 'Contenido no disponible';
    }
  }
}
