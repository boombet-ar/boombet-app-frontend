import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/utils/inappropriate_content_guard.dart';
import 'package:boombet_app/services/affiliates_service.dart';
import 'package:boombet_app/services/password_validation_service.dart';
import 'package:flutter/material.dart';

Future<void> showCreateAffiliateDialog({
  required BuildContext context,
  required AfiliadoresService service,
  required VoidCallback onCreated,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _CreateAffiliateDialogBody(
      service: service,
      onCreated: () {
        onCreated();
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Afiliador creado correctamente.',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppConstants.primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onError: (message) => messenger.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: AppConstants.errorRed.withValues(alpha: 0.40),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      ),
    ),
  );
}

class _CreateAffiliateDialogBody extends StatefulWidget {
  final AfiliadoresService service;
  final VoidCallback onCreated;
  final void Function(String) onError;

  const _CreateAffiliateDialogBody({
    required this.service,
    required this.onCreated,
    required this.onError,
  });

  @override
  State<_CreateAffiliateDialogBody> createState() =>
      _CreateAffiliateDialogBodyState();
}

class _CreateAffiliateDialogBodyState
    extends State<_CreateAffiliateDialogBody> {
  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Map<String, bool> _passwordRules = {
    'minimum_length': false,
    'uppercase': false,
    'number': false,
    'symbol': false,
    'no_repetition': false,
    'no_sequence': false,
  };

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordRules);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordRules);
    _usernameController.dispose();
    _emailController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordRules() {
    final status =
        PasswordValidationService.getValidationStatus(_passwordController.text);
    setState(() => _passwordRules = status);
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final dni = _dniController.text.trim();
    final telefono = _telefonoController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || dni.isEmpty || telefono.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      widget.onError('Todos los campos son obligatorios para continuar.');
      return;
    }

    final blocked =
        await InappropriateContentGuard.blockIfAnyFieldContainsInappropriateContent(
          context: context,
          values: [username, email],
        );
    if (blocked || !mounted) return;

    if (!PasswordValidationService.isEmailValid(email)) {
      widget.onError(PasswordValidationService.getEmailValidationMessage(email));
      return;
    }

    if (!PasswordValidationService.isPhoneValid(telefono)) {
      widget.onError(
        PasswordValidationService.getPhoneValidationMessage(telefono),
      );
      return;
    }

    if (!PasswordValidationService.isDniValid(dni)) {
      widget.onError(PasswordValidationService.getDniValidationMessage(dni));
      return;
    }

    if (username.length < 4 ||
        !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      widget.onError(
        'El usuario debe tener mínimo 4 caracteres, solo letras, números y guión bajo (_).',
      );
      return;
    }

    if (!PasswordValidationService.isPasswordValid(password)) {
      widget.onError(
        PasswordValidationService.getValidationMessage(password),
      );
      return;
    }

    if (password != confirmPassword) {
      widget.onError('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.service.createAfiliador(
        username: username,
        password: password,
        dni: dni,
        email: email,
        telefono: telefono,
      );

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      widget.onCreated();
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);

      final raw = e.toString().toLowerCase();
      final isDuplicate = raw.contains('409') ||
          raw.contains('duplicate') ||
          raw.contains('duplicado') ||
          raw.contains('already exists') ||
          raw.contains('ya existe') ||
          raw.contains('unique');

      widget.onError(
        isDuplicate
            ? 'Ya existe un usuario con ese nombre o email. Usá otros datos.'
            : 'No se pudo crear el afiliador.',
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    const green = AppConstants.primaryGreen;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.50), fontSize: 13),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.22), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF141414),
      prefixIcon: Icon(icon, color: green.withValues(alpha: 0.65), size: 18),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: green),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);
    const fieldStyle = TextStyle(color: Colors.white, fontSize: 14);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 6),
        side: BorderSide(color: green.withValues(alpha: 0.20)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadius + 6),
                  topRight: Radius.circular(AppConstants.borderRadius + 6),
                ),
                border: Border(
                  bottom: BorderSide(color: green.withValues(alpha: 0.12)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: green.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_outlined,
                      color: green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crear afiliador',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Completá los datos para crear la cuenta.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Campos ──────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _usernameController,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Usuario',
                        hint: 'Ej: juan_perez',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Email',
                        hint: 'Ej: juan@email.com',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'DNI',
                        hint: 'Ej: 12345678',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Teléfono',
                        hint: 'Ej: 1123456789',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Contraseña',
                        hint: 'Mínimo 8 caracteres',
                        icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white.withValues(alpha: 0.40),
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PasswordRulesPanel(rules: _passwordRules),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Confirmar contraseña',
                        hint: 'Repetí la contraseña',
                        icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white.withValues(alpha: 0.40),
                            size: 18,
                          ),
                          onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // ── Acciones ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Crear afiliador',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordRulesPanel extends StatelessWidget {
  final Map<String, bool> rules;

  const _PasswordRulesPanel({required this.rules});

  static const _labels = {
    'minimum_length': '8+ caracteres',
    'uppercase': '1 mayúscula',
    'number': '1 número',
    'symbol': '1 símbolo',
    'no_repetition': 'Sin repetidos',
    'no_sequence': 'Sin secuencias',
  };

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: green.withValues(alpha: 0.12)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: rules.entries.map((entry) {
          final ok = entry.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ok
                    ? Icons.check_circle_outline_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 13,
                color: ok ? green : Colors.white.withValues(alpha: 0.28),
              ),
              const SizedBox(width: 4),
              Text(
                _labels[entry.key] ?? entry.key,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: ok ? FontWeight.w600 : FontWeight.normal,
                  color: ok ? green : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
