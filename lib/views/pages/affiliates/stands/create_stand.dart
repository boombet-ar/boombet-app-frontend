import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/stands_service.dart';
import 'package:flutter/material.dart';

Future<void> showCreateStandDialog({
  required BuildContext context,
  required StandsService standsService,
  required void Function(StandCreationResult result) onCreated,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _CreateStandDialogBody(
      standsService: standsService,
      onCreated: onCreated,
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

class _CreateStandDialogBody extends StatefulWidget {
  final StandsService standsService;
  final void Function(StandCreationResult result) onCreated;
  final void Function(String) onError;

  const _CreateStandDialogBody({
    required this.standsService,
    required this.onCreated,
    required this.onError,
  });

  @override
  State<_CreateStandDialogBody> createState() => _CreateStandDialogBodyState();
}

class _CreateStandDialogBodyState extends State<_CreateStandDialogBody> {
  bool _isSubmitting = false;
  bool _showPassword = false;

  final _nombreController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final nombre = _nombreController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final email = _emailController.text.trim();

    if (nombre.isEmpty || username.isEmpty || password.isEmpty || email.isEmpty) {
      widget.onError('Todos los campos son obligatorios para continuar.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await widget.standsService.createStand(
        nombre: nombre,
        username: username,
        password: password,
        email: email,
      );

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      widget.onCreated(result);
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);

      final raw = e.toString().toLowerCase();
      final isDuplicate =
          raw.contains('409') ||
          raw.contains('duplicate') ||
          raw.contains('duplicado') ||
          raw.contains('already exists') ||
          raw.contains('ya existe') ||
          raw.contains('unique');

      widget.onError(
        isDuplicate
            ? 'Ya existe un puesto con ese usuario o nombre. Usá otros datos.'
            : 'No se pudo crear el puesto.',
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
                      Icons.add_business_outlined,
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
                          'Crear puesto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Completá los datos para crear la cuenta del operador.',
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
                      controller: _nombreController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Nombre del puesto',
                        hint: 'Ej: Stand Central',
                        icon: Icons.storefront_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _usernameController,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Usuario operador',
                        hint: 'Ej: stand_central',
                        icon: Icons.person_outline_rounded,
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
                        hint: 'Mínimo 6 caracteres',
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
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: fieldStyle,
                      cursorColor: green,
                      decoration: _fieldDecoration(
                        label: 'Email del operador',
                        hint: 'Ej: stand@boombet.com',
                        icon: Icons.email_outlined,
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
                              'Crear puesto',
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
