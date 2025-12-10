import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/views/pages/error_testing_page.dart';
import 'package:boombet_app/views/pages/faq_page.dart';
import 'package:boombet_app/views/pages/forget_password_page.dart';
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
              const SizedBox(height: 12),

              // Accesibilidad - Tamaño de letra
              Card(
                color: surfaceColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.text_fields,
                            color: AppConstants.primaryGreen,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Tamaño de Letra',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<double>(
                        valueListenable: fontSizeMultiplierNotifier,
                        builder: (context, multiplier, _) {
                          return Row(
                            children: [
                              Text(
                                'A',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: multiplier,
                                  min: 0.8,
                                  max: 1.5,
                                  divisions: 7,
                                  activeColor: AppConstants.primaryGreen,
                                  inactiveColor: Colors.grey.shade300,
                                  onChanged: (value) {
                                    saveFontSizeMultiplier(value);
                                  },
                                ),
                              ),
                              Text(
                                'A',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Accesibilidad - Contraste
              Card(
                color: surfaceColor,
                child: SwitchListTile(
                  secondary: Icon(
                    Icons.contrast,
                    color: AppConstants.primaryGreen,
                  ),
                  title: const Text('Modo de Alto Contraste'),
                  subtitle: const Text('Mejora la legibilidad del texto'),
                  value: false,
                  activeThumbColor: AppConstants.primaryGreen,
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(height: 12),

              // Accesibilidad - Animaciones
              Card(
                color: surfaceColor,
                child: SwitchListTile(
                  secondary: Icon(
                    Icons.animation,
                    color: AppConstants.primaryGreen,
                  ),
                  title: const Text('Reducir Animaciones'),
                  subtitle: const Text('Desactiva efectos visuales'),
                  value: false,
                  activeThumbColor: AppConstants.primaryGreen,
                  onChanged: (value) {},
                ),
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
                title: 'Legales',
                subtitle: 'Consulta documentos legales',
                onTap: () {
                  _showLegalsDialog(context);
                },
                surfaceColor: surfaceColor,
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

  void _showLegalsDialog(BuildContext context) {
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
        title: Text(
          'Documentos Legales',
          style: TextStyle(
            color: AppConstants.primaryGreen,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecciona un documento para consultar:',
                style: TextStyle(color: textColor, fontSize: 14),
              ),
              const SizedBox(height: 16),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: AppConstants.primaryGreen),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppConstants.primaryGreen.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          color: AppConstants.primaryGreen.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.primaryGreen, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppConstants.primaryGreen.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  void _openLegalDocument(String documentType) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark
        ? AppConstants.darkAccent
        : AppConstants.lightDialogBg;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;

    // Obtener el contenido del documento
    final content = _getLegalDocumentContent(documentType);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: dialogBg,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadius),
                  topRight: Radius.circular(AppConstants.borderRadius),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                documentType,
                style: TextStyle(
                  color: AppConstants.primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
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
                      fontSize: 15,
                      height: 1.6,
                      letterSpacing: 0.2,
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
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Cerrar',
                  style: TextStyle(
                    color: AppConstants.primaryGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
