import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/affiliated_casino_model.dart';
import 'package:boombet_app/services/casino_service.dart';
import 'package:flutter/material.dart';

class CasinoCard extends StatefulWidget {
  final AffiliatedCasino casino;

  const CasinoCard({super.key, required this.casino});

  @override
  State<CasinoCard> createState() => _CasinoCardState();
}

class _CasinoCardState extends State<CasinoCard> {
  final _controller = TextEditingController();
  final _service = CasinoService();

  String? _localVerified;
  bool _isRetrying = false;
  bool _isLoading = false;
  int _fieldKey = 0;

  bool get _showForm => _localVerified == null || _isRetrying;

  @override
  void initState() {
    super.initState();
    _localVerified = widget.casino.verified;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final id = _controller.text.trim();

    if (id.isEmpty) {
      _showEmptyIdDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.verifyAffiliation(
        idAfiliacion: widget.casino.idAfiliacion,
        casinoUserId: id,
      );
      if (!mounted) return;
      setState(() {
        _localVerified = 'PENDIENTE';
        _isRetrying = false;
        _controller.clear();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error. Intentá de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmptyIdDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.darkAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppConstants.primaryGreen, size: 22),
            SizedBox(width: 10),
            Text(
              'Campo vacío',
              style: TextStyle(
                color: AppConstants.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'No podés enviar el ID vacío.',
          style: TextStyle(color: AppConstants.textDark, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryGreen.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppConstants.primaryGreen.withValues(alpha: 0.05),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CasinoLogo(logoUrl: widget.casino.logoUrl, name: widget.casino.nombreGral),
            const SizedBox(height: 24),
            if (_showForm) ...[
              _IdInputField(key: ValueKey(_fieldKey), controller: _controller),
              const SizedBox(height: 16),
              _VerifyButton(onTap: _handleVerify, isLoading: _isLoading),
            ] else
              _VerificationStatus(
                status: _localVerified!,
                onRetry: _localVerified == 'RECHAZADO'
                    ? () => setState(() {
                        _controller.clear();
                        _fieldKey++;
                        _isRetrying = true;
                      })
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Subwidgets ─────────────────────────────────────────────────────────────

class _CasinoLogo extends StatelessWidget {
  final String logoUrl;
  final String name;

  const _CasinoLogo({required this.logoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(
          color: AppConstants.primaryGreen.withValues(alpha: 0.28),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryGreen.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: logoUrl.isNotEmpty
            ? Image.network(
                logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _FallbackLogo(name: name),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppConstants.primaryGreen.withValues(alpha: 0.5),
                        ),
                      ),
              )
            : _FallbackLogo(name: name),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final String name;
  const _FallbackLogo({required this.name});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w800,
            color: AppConstants.primaryGreen.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _IdInputField extends StatelessWidget {
  final TextEditingController controller;
  const _IdInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: AppConstants.textDark,
        fontSize: 14,
        letterSpacing: 0.3,
      ),
      decoration: InputDecoration(
        hintText: 'Ingresá tu ID',
        hintStyle: TextStyle(
          color: AppConstants.textDark.withValues(alpha: 0.35),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.badge_outlined,
          size: 18,
          color: AppConstants.primaryGreen.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.primaryGreen.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppConstants.primaryGreen.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const _VerifyButton({this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppConstants.primaryGreen.withValues(alpha: 0.12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryGreen.withValues(alpha: 0.18),
                  AppConstants.primaryGreen.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppConstants.primaryGreen.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.primaryGreen.withValues(alpha: 0.8),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_outlined, size: 16, color: AppConstants.primaryGreen),
                        SizedBox(width: 8),
                        Text(
                          'Verificar mi afiliación',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryGreen,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationStatus extends StatelessWidget {
  final String status;
  final VoidCallback? onRetry;

  const _VerificationStatus({required this.status, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final config = _configForStatus(status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(config.icon, size: 28, color: config.color),
        const SizedBox(height: 10),
        Text(
          config.message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: config.color,
            letterSpacing: 0.2,
            height: 1.4,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  _StatusConfig _configForStatus(String status) {
    switch (status) {
      case 'OK':
        return _StatusConfig(
          icon: Icons.check_circle_outline_rounded,
          color: AppConstants.primaryGreen,
          message: '¡Tu verificación fue aprobada!',
        );
      case 'RECHAZADO':
        return _StatusConfig(
          icon: Icons.cancel_outlined,
          color: Colors.red,
          message: 'Tu verificación fue rechazada',
        );
      case 'PENDIENTE':
      default:
        return _StatusConfig(
          icon: Icons.access_time_rounded,
          color: Colors.grey,
          message: 'Tu verificación está siendo revisada',
        );
    }
  }
}

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String message;

  const _StatusConfig({
    required this.icon,
    required this.color,
    required this.message,
  });
}
