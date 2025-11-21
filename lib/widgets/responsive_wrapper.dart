import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Widget que adapta el contenido para verse mejor en web
/// Limita el ancho máximo y centra el contenido en pantallas grandes
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 500, // Ancho similar a un teléfono
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // En móvil, mostrar el widget tal cual
      return child;
    }

    // En web, centrar y limitar el ancho
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
