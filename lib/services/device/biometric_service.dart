import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maneja la configuración de biometría (huella / face) con flag persistente.
class BiometricService {
  BiometricService._();

  static const _enabledKey = 'biometric_enabled';
  static const _promptedKey = 'biometric_prompted';
  static final LocalAuthentication _auth = LocalAuthentication();
  static bool _runtimeValidated = false;

  /// Indica si ya se autenticó biometría (o se decidió omitirla) en esta sesión de app.
  static bool get runtimeValidated => _runtimeValidated;

  /// Limpia el flag en memoria para forzar un nuevo prompt biométrico.
  static void resetRuntimeValidation() {
    _runtimeValidated = false;
  }

  /// Devuelve true si el usuario ya activó la biometría.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Pregunta una sola vez después del login si el usuario desea activarla.
  static Future<bool> maybePromptEnable(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final alreadyPrompted = prefs.getBool(_promptedKey) ?? false;
    if (alreadyPrompted) return await isEnabled();

    final eligible = await _isDeviceEligible();
    if (!eligible) {
      debugPrint('🔒 Biometría no disponible en el dispositivo');
      await _markPrompted(enabled: false);
      return false;
    }

    final wantsEnable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activar biometría'),
        content: const Text(
          '¿Quieres usar tu huella (o PIN/contraseña del dispositivo como respaldo) '
          'para iniciar sesión más rápido?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );

    if (wantsEnable != true) {
      await _markPrompted(enabled: false);
      resetRuntimeValidation();
      return false;
    }

    final success = await _authenticate(
      reason: 'Confirma para activar el acceso con huella',
      persistEnableOnSuccess: true,
    );
    await _markPrompted(enabled: success);
    _runtimeValidated = success;
    return success;
  }

  /// Si la biometría está activa, solicita autenticación al abrir la app.
  /// Retorna true si se autenticó (o si no está activada), false si falla/cancela.
  static Future<bool> requireBiometricIfEnabled({
    String reason = 'Confirma tu identidad',
    bool skipIfAlreadyValidated = true,
  }) async {
    if (skipIfAlreadyValidated && _runtimeValidated) {
      debugPrint('🔒 [BIO] skipping prompt (already validated this session)');
      return true;
    }

    final enabled = await isEnabled();
    debugPrint('🔒 [BIO] enabled flag: $enabled');
    if (!enabled) {
      _runtimeValidated = true;
      return true;
    }

    final ok = await _authenticate(
      reason: reason,
      persistEnableOnSuccess: false,
    );
    _runtimeValidated = ok;
    return ok;
  }

  /// Activa biometría bajo demanda con prompt inmediato.
  static Future<bool> enableWithPrompt({
    String reason = 'Confirma para activar biometría',
  }) async {
    final eligible = await _isDeviceEligible();
    if (!eligible) {
      await _markPrompted(enabled: false);
      return false;
    }

    final ok = await _authenticate(
      reason: reason,
      persistEnableOnSuccess: true,
    );
    await _markPrompted(enabled: ok);
    _runtimeValidated = ok;
    return ok;
  }

  /// Desactiva biometría y marca como ya preguntado.
  static Future<void> disableBiometric() async {
    await _markPrompted(enabled: false);
    resetRuntimeValidation();
  }

  /// Expone elegibilidad de dispositivo para la UI.
  static Future<bool> isDeviceEligible() => _isDeviceEligible();

  static Future<bool> _isDeviceEligible() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (e) {
      debugPrint('🔒 Error comprobando biometría: $e');
      return false;
    }
  }

  static Future<bool> _authenticate({
    required String reason,
    required bool persistEnableOnSuccess,
  }) async {
    try {
      // Garantizar que cualquier sesión previa se cancele para forzar nuevo prompt
      await _auth.stopAuthentication();

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        // En versiones recientes de local_auth, opciones como stickyAuth/useErrorDialogs
        // no están disponibles; se usa la configuración por defecto con fallback a PIN.
      );

      if (didAuthenticate && persistEnableOnSuccess) {
        await _setEnabled(true);
        debugPrint('🔒 Biometría activada');
      }

      _runtimeValidated = didAuthenticate;
      return didAuthenticate;
    } catch (e) {
      debugPrint('🔒 Error autenticando biometría: $e');
      _runtimeValidated = false;
      return false;
    }
  }

  static Future<void> _setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  static Future<void> _markPrompted({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promptedKey, true);
    await prefs.setBool(_enabledKey, enabled);
  }
}
