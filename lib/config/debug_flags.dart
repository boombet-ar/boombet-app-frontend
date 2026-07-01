class DebugFlags {
  /// Toggle temporal para QA: si está en true, siempre abre onboarding.
  /// Dejar en false para volver al flujo normal.
  static const bool forceShowOnboardingAlways = false;

  /// Muestra un pop-up de debug con el request/response completo
  /// al presionar "Crear cuenta". Desactivar en producción estable.
  static const bool debugRegisterEnabled = false;

  /// Muestra la consola de logs en la vista de escaneo QR.
  /// Poner en false para ocultarla completamente.
  static const bool qrScannerDebugConsoleEnabled = false;

  /// Muestra el panel de debug con el playerData crudo del backend
  /// en la página de resultados de afiliación. Desactivar en producción.
  static const bool affiliationPlayerDataDebugEnabled = false;

  /// Muestra la consola de logs en IsNotAffiliatedPage para debuggear
  /// el endpoint POST /api/users/auth/affiliate. Desactivar en producción.
  static const bool isNotAffiliatedDebugConsoleEnabled = false;
}
