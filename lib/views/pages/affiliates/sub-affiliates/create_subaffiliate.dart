import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/sub_afiliado_model.dart';
import 'package:boombet_app/services/sub_afiliados_service.dart';
import 'package:flutter/material.dart';

Future<void> showCreateSubAfiliadoDialog({
  required BuildContext context,
  required SubAfiliadosService service,
  required void Function(SubAfiliadoModel) onCreated,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _CreateSubAfiliadoDialogBody(
      service: service,
      onCreated: (created) {
        onCreated(created);
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Sub-afiliador creado correctamente.',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
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
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: AppConstants.errorRed.withValues(alpha: 0.40),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _CreateSubAfiliadoDialogBody extends StatefulWidget {
  final SubAfiliadosService service;
  final void Function(SubAfiliadoModel) onCreated;
  final void Function(String) onError;

  const _CreateSubAfiliadoDialogBody({
    required this.service,
    required this.onCreated,
    required this.onError,
  });

  @override
  State<_CreateSubAfiliadoDialogBody> createState() =>
      _CreateSubAfiliadoDialogBodyState();
}

class _CreateSubAfiliadoDialogBodyState
    extends State<_CreateSubAfiliadoDialogBody> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _dniCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final dni = _dniCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();

    if (username.isEmpty ||
        password.isEmpty ||
        dni.isEmpty ||
        email.isEmpty ||
        telefono.isEmpty) {
      widget.onError('Completá todos los campos para continuar.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final created = await widget.service.createSubAfiliado(
        username: username,
        password: password,
        role: 'AFILIADOR',
        dni: dni,
        email: email,
        telefono: telefono,
      );

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      widget.onCreated(created);
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);

      final raw = e.toString().toLowerCase();
      final isDuplicate =
          raw.contains('409') ||
          raw.contains('duplicate') ||
          raw.contains('duplicado') ||
          raw.contains('already exists') ||
          raw.contains('ya existe');

      widget.onError(
        isDuplicate
            ? 'Ya existe un usuario con ese username, DNI o email.'
            : 'No se pudo crear el sub-afiliador.',
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
      labelStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.50),
        fontSize: 13,
      ),
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.22),
        fontSize: 13,
      ),
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
                      Icons.person_add_outlined,
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
                          'Crear sub-afiliador',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Completá los datos del nuevo afiliador.',
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
                      controller: _usernameCtrl,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Username',
                        hint: 'Ej: carloslopez',
                        icon: Icons.alternate_email_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: !_passwordVisible,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Contraseña',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: green.withValues(alpha: 0.55),
                            size: 18,
                          ),
                          onPressed: () => setState(
                            () => _passwordVisible = !_passwordVisible,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dniCtrl,
                      keyboardType: TextInputType.number,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'DNI',
                        hint: 'Ej: 12345678',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Email',
                        hint: 'Ej: usuario@ejemplo.com',
                        icon: Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Teléfono',
                        hint: 'Ej: +5491123456789',
                        icon: Icons.phone_outlined,
                      ),
                    ),
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
                              'Crear',
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
