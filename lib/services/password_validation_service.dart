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

  /// Detecta secuencias: dígitos (2+ asc/desc) y letras (3+ asc/desc)
  static bool hasSequence(String password) {
    if (password.length < 2) return false;

    for (int i = 0; i < password.length - 1; i++) {
      final String a = password[i];
      final String b = password[i + 1];

      // Números consecutivos (asc o desc)
      if (_isDigit(a) && _isDigit(b)) {
        final int d1 = a.codeUnitAt(0);
        final int d2 = b.codeUnitAt(0);
        if ((d2 - d1 == 1) || (d1 - d2 == 1)) return true;
      }

      // Letras consecutivas (asc o desc) pero solo si son 3+ seguidas
      if (_isLetter(a) && _isLetter(b) && i < password.length - 2) {
        final String c = password[i + 2];
        if (_isLetter(c)) {
          final int c1 = a.toLowerCase().codeUnitAt(0);
          final int c2 = b.toLowerCase().codeUnitAt(0);
          final int c3 = c.toLowerCase().codeUnitAt(0);
          final bool asc = (c2 - c1 == 1) && (c3 - c2 == 1);
          final bool desc = (c1 - c2 == 1) && (c2 - c3 == 1);
          if (asc || desc) return true;
        }
      }
    }

    return false;
  }

  static bool _isDigit(String c) => RegExp(r'^[0-9]$').hasMatch(c);
  static bool _isLetter(String c) => RegExp(r'^[a-zA-Z]$').hasMatch(c);

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
