import 'package:flutter/material.dart';

/// Overlay de carga que bloquea la pantalla completa
///
/// Uso:
/// ```dart
/// LoadingOverlay.show(context, message: 'Cargando...');
/// // ... operación asíncrona ...
/// LoadingOverlay.hide(context);
/// ```
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  /// Muestra el overlay de carga
  static void show(BuildContext context, {String? message}) {
    if (_overlayEntry != null) {
      // Ya hay un overlay activo, no crear otro
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlayWidget(message: message),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Oculta el overlay de carga
  static void hide(BuildContext context) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  /// Verifica si el overlay está visible
  static bool get isVisible => _overlayEntry != null;
}

class _LoadingOverlayWidget extends StatelessWidget {
  final String? message;

  const _LoadingOverlayWidget({this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.black54, // Fondo semi-transparente
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                strokeWidth: 3,
              ),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
