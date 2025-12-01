import 'package:boombet_app/config/app_constants.dart';

/// Service centralizado para validación de contraseñas y datos
class PasswordValidationService {
  /// Valida si una contraseña cumple todos los requisitos
  static bool isPasswordValid(String password) {
    return hasMinimumLength(password) &&
        hasUppercase(password) &&
        hasNumber(password) &&
        hasSymbol(password) &&
        !hasRepeatedCharacters(password) &&
        !hasSequence(password);
  }

  /// Valida longitud mínima (8 caracteres)
  static bool hasMinimumLength(String password) {
    return password.length >= AppConstants.minPasswordLength;
  }

  /// Valida que tenga al menos una mayúscula
  static bool hasUppercase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }

  /// Valida que tenga al menos un número
  static bool hasNumber(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }

  /// Valida que tenga al menos un símbolo
  static bool hasSymbol(String password) {
    return password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:",.<>?/\\|`~]'));
  }

  /// Detecta caracteres repetidos (3 o más consecutivos)
  static bool hasRepeatedCharacters(String password) {
    return RegExp(AppConstants.sequencePattern).hasMatch(password);
  }

  /// Detecta secuencias comunes (abc, 123, etc.)
  static bool hasSequence(String password) {
    return RegExp(
      r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)',
      caseSensitive: false,
    ).hasMatch(password);
  }

  /// Retorna un mapa con el estado de cada validación
  static Map<String, bool> getValidationStatus(String password) {
    return {
      'minimum_length': hasMinimumLength(password),
      'uppercase': hasUppercase(password),
      'number': hasNumber(password),
      'symbol': hasSymbol(password),
      'no_repetition': !hasRepeatedCharacters(password),
      'no_sequence': !hasSequence(password),
    };
  }

  /// Retorna un mensaje amigable explicando el estado de la contraseña
  static String getValidationMessage(String password) {
    if (password.isEmpty) return 'Ingresa una contraseña';

    final status = getValidationStatus(password);
    final failedValidations = <String>[];

    if (!status['minimum_length']!) {
      failedValidations.add('mínimo 8 caracteres');
    }
    if (!status['uppercase']!) {
      failedValidations.add('una mayúscula');
    }
    if (!status['number']!) {
      failedValidations.add('un número');
    }
    if (!status['symbol']!) {
      failedValidations.add('un símbolo');
    }
    if (!status['no_repetition']!) {
      failedValidations.add('sin caracteres repetidos');
    }
    if (!status['no_sequence']!) {
      failedValidations.add('sin secuencias');
    }

    if (failedValidations.isEmpty) {
      return 'Contraseña válida ✓';
    }

    return 'Falta: ${failedValidations.join(', ')}';
  }

  // ==================== EMAIL VALIDATION ====================

  /// Valida formato de email (RFC 5322 simplificado)
  static bool isEmailValid(String email) {
    if (email.isEmpty) return false;

    // Regex para validar email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    return emailRegex.hasMatch(email);
  }

  /// Retorna mensaje de validación para email
  static String getEmailValidationMessage(String email) {
    if (email.isEmpty) return 'El email es requerido';
    if (!email.contains('@')) return 'Email debe contener @';
    if (!isEmailValid(email)) return 'Email no válido';
    return 'Email válido ✓';
  }

  // ==================== DNI VALIDATION ====================

  /// Valida formato de DNI (7-10 dígitos)
  static bool isDniValid(String dni) {
    if (dni.isEmpty) return false;

    // Remover espacios y guiones
    final cleanDni = dni.replaceAll(RegExp(r'[\s-]'), '');

    // Debe ser solo números y entre 7-10 dígitos
    final dniRegex = RegExp(r'^\d{7,10}$');

    return dniRegex.hasMatch(cleanDni);
  }

  /// Retorna mensaje de validación para DNI
  static String getDniValidationMessage(String dni) {
    if (dni.isEmpty) return 'El DNI es requerido';

    final cleanDni = dni.replaceAll(RegExp(r'[\s-]'), '');

    if (cleanDni.length < 7) return 'DNI debe tener al menos 7 dígitos';
    if (cleanDni.length > 10) return 'DNI no puede tener más de 10 dígitos';
    if (!cleanDni.contains(RegExp(r'^\d+$'))) {
      return 'DNI solo debe contener números';
    }

    return 'DNI válido ✓';
  }

  // ==================== PHONE VALIDATION ====================

  /// Valida formato de teléfono (10-15 dígitos, sin prefijo)
  static bool isPhoneValid(String phone) {
    if (phone.isEmpty) return false;

    // Remover espacios y guiones
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');

    // Debe ser solo números y entre 10-15 dígitos
    final phoneRegex = RegExp(r'^\d{10,15}$');

    return phoneRegex.hasMatch(cleanPhone);
  }

  /// Retorna mensaje de validación para teléfono
  static String getPhoneValidationMessage(String phone) {
    if (phone.isEmpty) return 'El teléfono es requerido';

    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');

    if (cleanPhone.length < 10) {
      return 'El teléfono debe tener al menos 10 dígitos (tienes ${cleanPhone.length})';
    }
    if (cleanPhone.length > 15) {
      return 'El teléfono no puede tener más de 15 dígitos';
    }
    if (!cleanPhone.contains(RegExp(r'^\d+$'))) {
      return 'El teléfono solo debe contener números';
    }

    return 'Teléfono válido ✓';
  }
}
