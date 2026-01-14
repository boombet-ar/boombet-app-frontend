import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Widget que adapta el contenido para verse mejor en web
/// Por defecto, en web deja que el contenido use todo el ancho.
/// Si se desea limitar (comportamiento anterior), usar constrainOnWeb=true.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool constrainOnWeb;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 500,
    this.constrainOnWeb = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // En móvil, mostrar el widget tal cual
      return child;
    }

    if (!constrainOnWeb) {
      // En web, usar todo el ancho disponible
      return SizedBox(width: double.infinity, child: child);
    }

    // Opt-in: centrar y limitar el ancho
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
