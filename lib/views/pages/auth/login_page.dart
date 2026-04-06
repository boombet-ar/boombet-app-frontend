import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/password_validation_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/auth/email_confirmation_page.dart';
import 'package:boombet_app/views/pages/home/home_keys.dart';
import 'package:go_router/go_router.dart';
import 'package:boombet_app/views/pages/auth/is_not_affiliated_page.dart';
import 'package:boombet_app/widgets/form_fields.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:boombet_app/services/biometric_service.dart';
import 'package:boombet_app/services/email_verification_service.dart';
import 'package:boombet_app/widgets/casino_logo_carousel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController _identifierController;
  late TextEditingController _passwordController;
  late FocusNode _identifierFocusNode;
  late FocusNode _passwordFocusNode;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _identifierError = false;
  bool _passwordError = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _identifierFocused = false;
  bool _passwordFocused = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController();
    _passwordController = TextEditingController();
    _identifierFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _identifierFocusNode.addListener(() {
      if (mounted)
        setState(() => _identifierFocused = _identifierFocusNode.hasFocus);
    });
    _passwordFocusNode.addListener(() {
      if (mounted)
        setState(() => _passwordFocused = _passwordFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _validateAndLogin() async {
    final identifier = _identifierController.text.trim();

    setState(() {
      _identifierError = identifier.isEmpty;
      _passwordError = _passwordController.text.trim().isEmpty;
    });

    if (_identifierError || _passwordError) {
      const dialogBg = AppConstants.darkAccent;
      const textColor = AppConstants.textDark;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: dialogBg,
          title: Text('Campos incompletos', style: TextStyle(color: textColor)),
          content: Text(
            'Por favor, completa todos los campos.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(color: AppConstants.primaryGreen),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (identifier.contains('@')) {
      if (!PasswordValidationService.isEmailValid(identifier)) {
        setState(() {
          _identifierError = true;
        });
        const dialogBg = AppConstants.darkAccent;
        const textColor = AppConstants.textDark;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: dialogBg,
            title: Text('Email inválido', style: TextStyle(color: textColor)),
            content: Text(
              PasswordValidationService.getEmailValidationMessage(identifier),
              style: TextStyle(color: textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Entendido',
                  style: TextStyle(color: AppConstants.primaryGreen),
                ),
              ),
            ],
          ),
        );
        return;
      }
    }

    LoadingOverlay.show(context, message: 'Iniciando sesión...');

    try {
      final result = await _authService.login(
        _identifierController.text.trim(),
        _passwordController.text,
        rememberMe: true,
      );

      if (!mounted) return;

      LoadingOverlay.hide(context);

      if (result['success'] == true) {
        debugPrint('DEBUG Login - Token guardado correctamente');
        affiliationPasswordNotifier.value = _passwordController.text;

        // Verificar si el email está confirmado
        final data = result['data'];
        final isVerified = data?['is_verified'] ?? data?['isVerified'] ?? true;
        if (isVerified == false || isVerified == 0) {
          // Extraer email del response o del campo identifier si es email
          final emailFromData = data?['email'] as String?;
          final identifier = _identifierController.text.trim();
          final email = (emailFromData != null && emailFromData.isNotEmpty)
              ? emailFromData
              : (identifier.contains('@') ? identifier : null);

          await _authService.logout();
          if (!mounted) return;

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppConstants.darkAccent,
              title: const Text(
                'Email sin confirmar',
                style: TextStyle(color: AppConstants.textDark),
              ),
              content: const Text(
                'Tu email no está confirmado. Confírmalo para continuar.',
                style: TextStyle(color: AppConstants.textDark),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await _sendVerificationEmailAndNavigate(email);
                  },
                  child: const Text(
                    'Confirmar mi email',
                    style: TextStyle(color: AppConstants.primaryGreen),
                  ),
                ),
              ],
            ),
          );
          return;
        }

        final isAffiliated = data?['isAffiliated'] ?? true;
        if (isAffiliated == false) {
          if (!mounted) return;
          if (context.mounted) context.go('/not-affiliated');
          return;
        }

        final biometricEnabled = await BiometricService.maybePromptEnable(
          context,
        );

        if (biometricEnabled) {
          final biometricOk = await BiometricService.requireBiometricIfEnabled(
            reason: 'Confirma para ingresar',
          );

          if (!biometricOk) {
            await _authService.logout();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Autenticación biométrica cancelada o fallida. Vuelve a intentarlo.',
                ),
              ),
            );
            return;
          }
        }

        final role = await TokenService.getUserRole();
        if (!mounted) return;

        if (role?.trim().toUpperCase() == 'AFILIADOR') {
          if (context.mounted) context.go('/affiliates-tools');
        } else if (role?.trim().toUpperCase() == 'STAND') {
          if (context.mounted) context.go('/stand-tools');
        } else {
          pendingLoginTutorialNotifier.value = true;
          if (context.mounted) context.go(HomePageKeys.home);
        }
      } else {
        final message = result['message'] ?? '';
        final isUnverified =
            message.contains('no esta verificada') ||
            message.contains('no está verificada') ||
            message.contains('not verified') ||
            message.contains('unverified') ||
            message.contains('verificada') ||
            message.contains('activarla');

        if (isUnverified) {
          final identifier = _identifierController.text.trim();
          final email = identifier.contains('@') ? identifier : null;

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppConstants.darkAccent,
              title: const Text(
                'Email sin confirmar',
                style: TextStyle(color: AppConstants.textDark),
              ),
              content: const Text(
                'Tu email no está confirmado. Confírmalo para continuar.',
                style: TextStyle(color: AppConstants.textDark),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await _sendVerificationEmailAndNavigate(email);
                  },
                  child: const Text(
                    'Confirmar mi email',
                    style: TextStyle(color: AppConstants.primaryGreen),
                  ),
                ),
              ],
            ),
          );
          return;
        }

        setState(() {
          _identifierError = true;
          _passwordError = true;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppConstants.darkAccent,
            title: const Text(
              'Error de autenticación',
              style: TextStyle(color: AppConstants.textDark),
            ),
            content: Text(
              message.isNotEmpty ? message : 'Usuario/Email o contraseña incorrectos',
              style: const TextStyle(color: AppConstants.textDark),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Entendido',
                  style: TextStyle(color: AppConstants.primaryGreen),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      LoadingOverlay.hide(context);
      const dialogBg = AppConstants.darkAccent;
      const textColor = AppConstants.textDark;

      String errorTitle = 'Error de conexión';
      String errorMessage = 'No se pudo conectar con el servidor';

      if (e.toString().contains('ClientException') ||
          e.toString().contains('Failed to fetch')) {
        errorTitle = 'Error de conexión desde navegador';
        errorMessage =
            'El servidor no permite conexiones desde navegadores web por seguridad (CORS).\n\n'
            '✅ Solución: Usa la aplicación desde Android o iOS.\n\n'
            'Si necesitas usar el navegador, contacta al administrador para configurar CORS en el backend.';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: dialogBg,
          title: Text(errorTitle, style: TextStyle(color: textColor)),
          content: Text(errorMessage, style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(color: AppConstants.primaryGreen),
              ),
            ),
          ],
        ),
      );
    }
  }

  // ─── Reenvío de email de verificación ────────────────────────────────
  Future<void> _sendVerificationEmailAndNavigate(String? email) async {
    LoadingOverlay.show(context, message: 'Enviando email de verificación...');

    if (email != null && email.isNotEmpty) {
      await EmailVerificationService.resendVerificationEmail(email);
    }

    if (!mounted) return;
    LoadingOverlay.hide(context);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EmailConfirmationPage(
          email: email,
          verificacionToken: '',
          isFromLogin: true,
        ),
      ),
    );
  }

  // ─── Botón de ayuda ───────────────────────────────────────────────────
  Widget _buildHelpButton() {
    const primaryGreen = AppConstants.primaryGreen;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: TextButton(
        onPressed: () {
          context.push(HomePageKeys.faq);
        },
        style: TextButton.styleFrom(
          overlayColor: primaryGreen.withValues(alpha: 0.07),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.55),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 10,
                    color: primaryGreen.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'Ayuda',
              style: TextStyle(
                fontSize: 13,
                color: textColor.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Glow wrapper para campos ──────────────────────────────────────────
  Widget _buildGlowField({
    required Widget child,
    required bool isFocused,
    required bool hasError,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: hasError
            ? [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : isFocused
            ? [
                BoxShadow(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.16),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeb = kIsWeb;
    // En web mobile, el browser achica el viewport cuando abre el teclado.
    // Detectamos si el teclado está abierto para adaptar el layout.
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = kIsWeb && keyboardHeight > 100;

    const primaryGreen = AppConstants.primaryGreen;
    final textColor = theme.colorScheme.onSurface;

    const fieldFillColor = Color(0xFF141414);
    const fieldBorderColor = Color(0xFF272727);

    // ─── Logo ────────────────────────────────────────────────────────────
    Widget buildLogo({required double width}) {
      return Center(
        child: Hero(
          tag: 'boombet_logo',
          child: Image.asset('assets/images/boombetlogo.png', width: width),
        ),
      );
    }

    // ─── Header ──────────────────────────────────────────────────────────
    final loginHeader = Column(
      children: [
        // Decoración de acento
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    primaryGreen.withValues(alpha: 0.65),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.75),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryGreen.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );

    // ─── Campos del form ─────────────────────────────────────────────────
    final loginFields = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón Crear cuenta nueva (PRIMERO en el contenedor)
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: primaryGreen.withValues(alpha: 0.45),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              overlayColor: primaryGreen.withValues(alpha: 0.06),
            ),
            onPressed: () => context.push('/register'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_outlined, size: 18, color: primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Crear cuenta nueva',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: primaryGreen,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Separador con "o"
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      textColor.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'o',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.28),
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      textColor.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Usuario o Email
        Semantics(
          label: 'Campo de usuario o email',
          hint:
              'Ingresa tu nombre de usuario o dirección de correo electrónico',
          child: _buildGlowField(
            isFocused: _identifierFocused,
            hasError: _identifierError,
            child: TextField(
              controller: _identifierController,
              focusNode: _identifierFocusNode,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              enableInteractiveSelection: true,
              style: TextStyle(color: textColor, fontSize: 15),
              onChanged: (value) {
                if (_identifierError && value.isNotEmpty) {
                  setState(() => _identifierError = false);
                }
              },
              decoration: InputDecoration(
                hintText: 'Usuario o Email',
                hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.28),
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(9),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _identifierError
                        ? Colors.red.withValues(alpha: 0.1)
                        : primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _identifierError
                          ? Colors.red.withValues(alpha: 0.28)
                          : primaryGreen.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: _identifierError ? Colors.red : primaryGreen,
                    size: 17,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  borderSide: BorderSide(
                    color: _identifierError
                        ? Colors.red.withValues(alpha: 0.6)
                        : fieldBorderColor,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  borderSide: BorderSide(
                    color: _identifierError
                        ? Colors.red.withValues(alpha: 0.6)
                        : fieldBorderColor,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  borderSide: BorderSide(
                    color: _identifierError
                        ? Colors.red
                        : primaryGreen.withValues(alpha: 0.75),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: fieldFillColor,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Contraseña
        Semantics(
          label: 'Campo de contraseña',
          hint: 'Ingresa tu contraseña',
          obscured: true,
          child: _buildGlowField(
            isFocused: _passwordFocused,
            hasError: _passwordError,
            child: TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              style: TextStyle(color: textColor, fontSize: 15),
              onChanged: (value) {
                if (_passwordError && value.isNotEmpty) {
                  setState(() => _passwordError = false);
                }
              },
              decoration: InputDecoration(
                hintText: 'Contraseña',
                hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.28),
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(9),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _passwordError
                        ? Colors.red.withValues(alpha: 0.1)
                        : primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _passwordError
                          ? Colors.red.withValues(alpha: 0.28)
                          : primaryGreen.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: _passwordError ? Colors.red : primaryGreen,
                    size: 17,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: textColor.withValues(alpha: 0.38),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  borderSide: BorderSide(
                    color: _passwordError
                        ? Colors.red.withValues(alpha: 0.6)
                        : fieldBorderColor,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  borderSide: BorderSide(
                    color: _passwordError
                        ? Colors.red.withValues(alpha: 0.6)
                        : fieldBorderColor,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  borderSide: BorderSide(
                    color: _passwordError
                        ? Colors.red
                        : primaryGreen.withValues(alpha: 0.75),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: fieldFillColor,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Botón Iniciar Sesión
        AppButton(
          label: 'Iniciar Sesión',
          onPressed: _validateAndLogin,
          isLoading: _isLoading,
          icon: Icons.login,
        ),
        const SizedBox(height: 6),

        // Link olvidar contraseña
        TextButton(
          onPressed: () {
            context.push(HomePageKeys.forgotPassword);
          },
          style: TextButton.styleFrom(
            overlayColor: primaryGreen.withValues(alpha: 0.07),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 15,
                color: textColor.withValues(alpha: 0.42),
              ),
              const SizedBox(width: 6),
              Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.42),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // ─── Card del form ────────────────────────────────────────────────────
    Widget buildFormCard(Widget child) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryGreen.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: primaryGreen.withValues(alpha: 0.03),
              blurRadius: 48,
              spreadRadius: 0,
            ),
          ],
        ),
        child: child,
      );
    }

    // ─── Banner juego responsable ─────────────────────────────────────────
    Widget buildResponsibleGamblingBanner() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryGreen.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ícono grillito
            Image.asset(
              'assets/images/grillito_icon.png',
              height: 32,
              width: 32,
              color: primaryGreen,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(width: 12),
            // Texto central
            Expanded(
              child: Text(
                'Jugar compulsivamente es perjudicial para la salud',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Ícono +18
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Image.asset(
                'assets/images/+18_icon.png',
                height: 28,
                width: 28,
                color: primaryGreen,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ],
        ),
      );
    }

    // ─── Background con glow ──────────────────────────────────────────────
    Widget buildBackground() {
      return Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFF0E0E0E))),
          // Glow superior-izquierdo
          Positioned(
            top: -130,
            left: -130,
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
          // Glow inferior-derecho
          Positioned(
            bottom: -110,
            right: -110,
            child: Container(
              width: 360,
              height: 360,
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
        ],
      );
    }

    // ─── Body Mobile ──────────────────────────────────────────────────────
    final mobileBody = SafeArea(
      child: ResponsiveWrapper(
        maxWidth: 600,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22.0, 0, 22.0, 50.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Logo sin padding extra
                          buildLogo(width: 150),
                          // FormCard
                          buildFormCard(
                            Column(
                              children: [
                                loginHeader,
                                loginFields,
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                          // Carrusel + Banner juego responsable
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CasinoLogoCarousel(height: 44),
                              const SizedBox(height: 8),
                              buildResponsibleGamblingBanner(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    // ─── Body Web ─────────────────────────────────────────────────────────
    Widget buildWebBody() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrowWeb = constraints.maxWidth < 900;

          if (isNarrowWeb) {
            // SingleChildScrollView en lugar de Column+Expanded+isKeyboardOpen.
            // El layout no cambia estructuralmente cuando el teclado abre:
            // Flutter web reposiciona el HTML input si el widget se mueve durante
            // la animación del teclado y Chrome interpreta eso como un cierre.
            // Con scroll, el contenido se mantiene estático y Flutter auto-scrollea
            // al campo enfocado via ensureVisible.
            return SafeArea(
              child: ResponsiveWrapper(
                maxWidth: 520,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22.0, 16, 22.0, 80.0),
                    child: Column(
                      children: [
                        buildLogo(width: 150),
                        const SizedBox(height: 24),
                        buildFormCard(
                          Column(
                            children: [
                              loginHeader,
                              loginFields,
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CasinoLogoCarousel(height: 44),
                            const SizedBox(height: 8),
                            buildResponsibleGamblingBanner(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: buildResponsibleGamblingBanner(),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: LayoutBuilder(
                            builder: (context, inner) {
                              final double logoWidth = (inner.maxWidth * 0.8)
                                  .clamp(260.0, 520.0)
                                  .toDouble();
                              return Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 460,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [buildLogo(width: logoWidth)],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 28,
                              ),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: buildFormCard(
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      loginHeader,
                                      loginFields,
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Carrusel debajo del contenedor (layout wide)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 50),
                  child: const CasinoLogoCarousel(height: 64),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      // En web: true para que el Scaffold adapte el body cuando el browser
      // achica el viewport por el teclado. En nativo: false porque el layout
      // de login (logo + form + carousel con spaceEvenly) no es scrolleable y
      // si se aprieta Android cierra el teclado automáticamente al no ver el campo.
      resizeToAvoidBottomInset: kIsWeb,
      body: Stack(
        children: [
          // GestureDetector solo en la capa de fondo: captura taps en zonas
          // vacías (para cerrar el teclado) pero NO interfiere con los campos
          // de texto que están en capas superiores del Stack.
          GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.opaque,
            child: buildBackground(),
          ),
          isWeb ? buildWebBody() : mobileBody,
          // Botón ayuda fijo. En web mobile se oculta cuando el teclado
          // está abierto para no ocupar espacio valioso del formulario.
          if (!isKeyboardOpen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(top: false, child: _buildHelpButton()),
            ),
        ],
      ),
    );
  }
}
