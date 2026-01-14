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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = theme.colorScheme.primary;
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
        title: Text(title, style: TextStyle(color: textColor)),
        content: Text(message, style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                _emailController.clear();
                setState(() => _emailError = false);
              }
            },
            child: Text('Entendido', style: TextStyle(color: primaryGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWeb = kIsWeb;
    final primaryGreen = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;
    final accentColor = isDark
        ? AppConstants.borderDark
        : AppConstants.lightAccent;
    final borderColor = isDark
        ? AppConstants.borderDark
        : AppConstants.lightInputBorder;
    final borderRadius = AppConstants.borderRadius;

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
        Text(
          'Recuperar Contraseña',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa tu correo electrónico',
          style: TextStyle(
            fontSize: 15,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
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
          style: TextStyle(color: textColor),
          onChanged: (value) {
            if (_emailError && value.isNotEmpty) {
              setState(() => _emailError = false);
            }
          },
          decoration: InputDecoration(
            hintText: 'Tu correo electrónico',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : AppConstants.lightHintText,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: _emailError ? Colors.red : primaryGreen,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: _emailError ? Colors.red : borderColor,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: _emailError ? Colors.red : borderColor,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: _emailError ? Colors.red : primaryGreen,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: accentColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
        ),
        const SizedBox(height: 24),
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
        color: theme.scaffoldBackgroundColor,
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
              const SizedBox(height: 24),
              header,
              form,
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    final webBody = Container(
      color: theme.scaffoldBackgroundColor,
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

    return Scaffold(
      appBar: const MainAppBar(
        showSettings: false,
        showProfileButton: false,
        showBackButton: true,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: isWeb ? webBody : mobileBody,
      ),
    );
  }
}
