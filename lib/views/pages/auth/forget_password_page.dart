import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/forgot_password_service.dart';
import 'package:boombet_app/services/password_validation_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/form_fields.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  late TextEditingController _emailController;

  bool _emailError = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateAndSendEmail() async {
    setState(() {
      _emailError = _emailController.text.trim().isEmpty;
    });

    if (_emailError) {
      _showDialog('Campo vacío', 'Por favor, ingresa tu correo electrónico.');
      return;
    }

    // Validar formato de email
    final email = _emailController.text.trim();
    debugPrint('📧 [ForgetPasswordPage] Email ingresado: "$email"');
    debugPrint('📧 [ForgetPasswordPage] Email length: ${email.length}');

    if (!PasswordValidationService.isEmailValid(email)) {
      setState(() {
        _emailError = true;
      });
      _showDialog(
        'Email inválido',
        PasswordValidationService.getEmailValidationMessage(email),
      );
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // Llamar al backend para enviar email
      debugPrint(
        '📧 [ForgetPasswordPage] Llamando a ForgotPasswordService.sendPasswordResetEmail()',
      );
      final result = await ForgotPasswordService.sendPasswordResetEmail(email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint('📧 [ForgetPasswordPage] Respuesta del servicio: $result');

      if (result['success'] == true) {
        // ✅ EMAIL ENVIADO EXITOSAMENTE
        _showDialog(
          '¡Email enviado!',
          result['message'] ??
              'Se ha enviado un correo de recuperación a $email con las instrucciones para restaurar tu contraseña.',
          isSuccess: true,
        );
      } else {
        // ❌ ERROR AL ENVIAR EMAIL
        setState(() {
          if (result['statusCode'] == 404) {
            _emailError = true;
          }
        });
        _showDialog(
          'Error',
          result['message'] ??
              'No se pudo enviar el correo. Por favor intenta más tarde.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error en _validateAndSendEmail: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showDialog('Error', 'Ocurrió un error inesperado: $e');
    }
  }

  void _showDialog(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSuccess
                ? AppConstants.primaryGreen.withValues(alpha: 0.30)
                : AppConstants.primaryGreen.withValues(alpha: 0.14),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSuccess ? AppConstants.primaryGreen : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                _emailController.clear();
                setState(() => _emailError = false);
              }
            },
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: AppConstants.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const isWeb = kIsWeb;
    const scaffoldBg = Color(0xFF0E0E0E);
    const green = AppConstants.primaryGreen;
    const borderRadius = AppConstants.borderRadius;

    Widget buildLogo({required double width}) {
      return Center(
        child: Hero(
          tag: 'boombet_logo',
          child: Image.asset('assets/images/boombetlogo.png', width: width),
        ),
      );
    }

    final header = Column(
      children: [
        // Ícono decorativo
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: green.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: green.withValues(alpha: 0.22),
              width: 1.5,
            ),
          ),
          child: const Icon(Icons.lock_reset_rounded, color: green, size: 28),
        ),
        const SizedBox(height: 16),
        const Text(
          'Recuperar Contraseña',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: green,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Ingresa tu correo electrónico',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.50),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
      ],
    );

    final form = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          enableInteractiveSelection: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          cursorColor: green,
          onChanged: (value) {
            if (_emailError && value.isNotEmpty) {
              setState(() => _emailError = false);
            }
          },
          decoration: InputDecoration(
            hintText: 'Tu correo electrónico',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: _emailError
                  ? Colors.redAccent
                  : green.withValues(alpha: 0.7),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFF141414),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: _emailError
                    ? Colors.redAccent
                    : green.withValues(alpha: 0.14),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: _emailError
                    ? Colors.redAccent
                    : green.withValues(alpha: 0.14),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: _emailError ? Colors.redAccent : green,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Enviar Correo',
          onPressed: _validateAndSendEmail,
          isLoading: _isLoading,
          icon: Icons.mail_outline,
          borderRadius: borderRadius,
        ),
      ],
    );

    final mobileBody = ResponsiveWrapper(
      maxWidth: 600,
      child: Container(
        color: scaffoldBg,
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: buildLogo(width: 200),
              ),
              const SizedBox(height: 28),
              header,
              form,
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    final webBody = LayoutBuilder(
      builder: (context, constraints) {
        final isNarrowWeb = constraints.maxWidth < 900;

        if (isNarrowWeb) {
          final double logoWidth = (constraints.maxWidth * 0.55)
              .clamp(160.0, 220.0)
              .toDouble();

          return ResponsiveWrapper(
            maxWidth: 600,
            child: Container(
              color: scaffoldBg,
              height: double.infinity,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: buildLogo(width: logoWidth),
                    ),
                    const SizedBox(height: 28),
                    header,
                    form,
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          color: scaffoldBg,
          height: double.infinity,
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double logoWidth = (constraints.maxWidth * 0.8)
                          .clamp(260.0, 520.0)
                          .toDouble();
                      return Center(child: buildLogo(width: logoWidth));
                    },
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 28,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [header, form],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Container(color: scaffoldBg),
          ),
          isWeb ? webBody : mobileBody,
        ],
      ),
    );
  }
}
