import 'package:flutter/material.dart';

/// Centraliza todas las constantes de la app para fácil mantenimiento
class AppConstants {
  // ==================== COLORES ====================
  static const Color primaryGreen = Color.fromARGB(255, 41, 255, 94);
  static const Color darkBg = Color(0xFF121212);
  static const Color darkAccent = Color(0xFF1A1A1A);
  static const Color darkCardBg = Color(0xFF2A2A2A);
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightAccent = Color(0xFFE8E8E8);
  static const Color borderDark = Color(0xFF1A1A1A);
  static const Color borderLight = Color(0xFFD0D0D0);
  static const Color textDark = Color(0xFFE0E0E0);
  static const Color textLight = Color(0xFF2C2C2C);
  static const Color errorRed = Colors.red;
  static const Color warningOrange = Colors.orange;
  static const Color successGreen = Colors.green;

  // ==================== LIGHT MODE SPECIFIC COLORS ====================
  static const Color lightInputBg = Color(
    0xFFFAFAFA,
  ); // Casi blanco, ligeramente gris
  static const Color lightInputBorder = Color(
    0xFFBBBBBB,
  ); // Gris oscuro para contraste
  static const Color lightInputBorderFocus = Color(
    0xFF808080,
  ); // Más oscuro en focus
  static const Color lightCardBg = Color(0xFFFFFFFF); // Blanco puro para cards
  static const Color lightLabelText = Color(
    0xFF1F1F1F,
  ); // Casi negro para labels
  static const Color lightHintText = Color(0xFF888888); // Gris medio para hints
  static const Color lightDivider = Color(0xFFE8E8E8); // Divisores suaves
  static const Color lightSurfaceVariant = Color(
    0xFFF5F5F5,
  ); // Superficie alternativa
  static const Color lightDialogBg = Color(0xFFFFFAFA); // Blanco muy suave

  // ==================== DURACIONES ====================
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration affiliationTimeout = Duration(seconds: 15);
  static const Duration shortDelay = Duration(milliseconds: 300);
  static const Duration mediumDelay = Duration(milliseconds: 500);
  static const Duration longDelay = Duration(seconds: 1);
  static const Duration webSocketHandshakeDuration = Duration(seconds: 2);
  static const Duration snackbarDuration = Duration(seconds: 2);
  static const Duration longSnackbarDuration = Duration(seconds: 5);
  static const Duration themeAnimationDuration = Duration(milliseconds: 150);

  // ==================== TAMAÑOS ====================
  static const double borderRadius = 12.0;
  static const double appBarHeight = 56.0;
  static const double buttonHeight = 56.0;
  static const double smallIconSize = 18.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 80.0;

  // ==================== TAMAÑOS DE FUENTE ====================
  static const double headingLarge = 28.0;
  static const double headingMedium = 22.0;
  static const double headingSmall = 18.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 13.0;
  static const double bodyExtraSmall = 12.0;
  static const double captionSize = 11.0;

  // ==================== PADDING Y SPACING ====================
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 24.0;
  static const double paddingXXLarge = 32.0;

  // ==================== VALIDACIÓN ====================
  static const int minPasswordLength = 8;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;

  // ==================== REGEX PATTERNS ====================
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^\d{10,15}$';
  static const String sequencePattern = r'(.)\1{2,}'; // Detecta 3+ repetidos
  static const String passwordSequencePattern =
      r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)';

  // ==================== API ENDPOINTS ====================
  static const String endpointLogin = '/users/login';
  static const String endpointRegister = '/users/auth/register';
  static const String endpointUserData = '/users/auth/userData';
  static const String endpointProfile = '/api/jugadores';
  static const String endpointUpdateProfile = '/api/jugadores/update';

  // ==================== RESPONSIVE DESIGN ====================
  static const double maxWidthSmall = 600.0;
  static const double maxWidthMedium = 800.0;
  static const double maxWidthLarge = 1000.0;
  static const double maxWidthXLarge = 1200.0;

  // ==================== MENSAJES COMUNES ====================
  static const String msgSessionExpired =
      'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
  static const String msgPasswordInvalid =
      'La contraseña debe tener al menos 8 caracteres, una mayúscula, un número y un símbolo. No debe tener secuencias ni caracteres repetidos.';
  static const String msgEmailInvalid = 'Por favor, ingresa un email válido.';
  static const String msgPhoneInvalid =
      'El teléfono debe contener solo números (10-15 dígitos).';
  static const String msgConnectionError =
      'Error de conexión. Por favor, intenta nuevamente.';
  static const String msgLoadingData = 'Cargando datos...';
  static const String msgCreatingAccount = 'Creando cuenta y afiliando...';
}
