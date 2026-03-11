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
          const SnackBar(
            content: Text('Afiliador creado correctamente.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      onError: (message) => messenger.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    const textColor = AppConstants.textDark;
    const dialogBg = AppConstants.darkAccent;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 6),
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
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.25),
                    accent.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadius + 6),
                  topRight: Radius.circular(AppConstants.borderRadius + 6),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(Icons.person_add_alt_1, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crear afiliador',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Completá los datos para crear una cuenta de afiliador.',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
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
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        hintText: 'Ej: juan_perez',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Ej: juan@email.com',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'DNI',
                        hintText: 'Ej: 12345678',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        hintText: 'Ej: 1123456789',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: 'Mínimo 8 caracteres',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PasswordRulesPanel(
                      rules: _passwordRules,
                      accent: accent,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        hintText: 'Repetí la contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Acciones ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(
                          color: accent.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppConstants.textLight,
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
                                color: AppConstants.textLight,
                              ),
                            )
                          : const Text('Crear afiliador'),
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
  final Color accent;

  const _PasswordRulesPanel({required this.rules, required this.accent});

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
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: rules.entries.map((entry) {
        final ok = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ok ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              size: 14,
              color: ok ? accent : AppConstants.textDark.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            Text(
              _labels[entry.key] ?? entry.key,
              style: TextStyle(
                fontSize: 11,
                color: ok
                    ? accent
                    : AppConstants.textDark.withValues(alpha: 0.4),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
