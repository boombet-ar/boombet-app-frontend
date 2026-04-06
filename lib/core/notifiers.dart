import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

ValueNotifier<int> selectedPageNotifier = ValueNotifier(0);

/// Sistema de navegación interna universal.
/// Cada página registra un callback de "volver" por su índice de tab.
/// El PopScope del home lo consulta antes de mostrar el diálogo de logout.
/// Uso: pageBackCallbacks[pageIndex] = () { ... }  // al entrar a sub-sección
///      pageBackCallbacks.remove(pageIndex);         // al volver al root
final Map<int, VoidCallback> pageBackCallbacks = {};
ValueNotifier<bool> loginTutorialActiveNotifier = ValueNotifier(false);
ValueNotifier<bool> pendingLoginTutorialNotifier = ValueNotifier(false);
ValueNotifier<bool> rouletteTriggerAfterTutorialNotifier = ValueNotifier(false);
ValueNotifier<bool> emailVerifiedNotifier = ValueNotifier(false);
ValueNotifier<double> fontSizeMultiplierNotifier = ValueNotifier(1.0);
ValueNotifier<String> affiliateTypeNotifier = ValueNotifier('');
ValueNotifier<bool> affiliateCodeValidatedNotifier = ValueNotifier(false);
ValueNotifier<String> affiliateCodeTokenNotifier = ValueNotifier('');

// Notifiers para datos de afiliación
ValueNotifier<PlayerData?> affiliationPlayerDataNotifier = ValueNotifier(null);
ValueNotifier<String> affiliationEmailNotifier = ValueNotifier('');
ValueNotifier<String> affiliationUsernameNotifier = ValueNotifier('');
ValueNotifier<String> affiliationPasswordNotifier = ValueNotifier('');
ValueNotifier<String> affiliationDniNotifier = ValueNotifier('');
ValueNotifier<String> affiliationTelefonoNotifier = ValueNotifier('');
ValueNotifier<String> affiliationGeneroNotifier = ValueNotifier('');

// Constantes para SharedPreferences
const String _keyPlayerData = 'affiliation_playerData';
const String _keyEmail = 'affiliation_email';
const String _keyUsername = 'affiliation_username';
const String _keyPassword = 'affiliation_password';
const String _keyDni = 'affiliation_dni';
const String _keyTelefono = 'affiliation_telefono';
const String _keyGenero = 'affiliation_genero';
const String _keyFontSizeMultiplier = 'font_size_multiplier';
const String _keyAffiliateType = 'affiliate_type';
const String _keyAffiliateCodeValidated = 'affiliate_code_validated';
const String _keyAffiliateCodeToken = 'affiliate_code_token';
const String _keySelectedPage = 'selected_page_index';
const String _keyAffiliationFlowRoute = 'affiliation_flow_route';
const String _keyAffiliationWsUrl = 'affiliation_ws_url';

bool selectedPageWasRestored = false;

/// Flag global para proteger flujos críticos (afiliación, verificación de mail).
/// Cuando es true, el handler de beforeunload (web) muestra un diálogo de confirmación
/// si el usuario intenta refrescar o cerrar la pestaña.
/// Las páginas de flujo crítico deben setear esto en initState/dispose.
bool criticalFlowActive = false;

/// Guarda datos de afiliación en SharedPreferences
Future<void> saveAffiliationData({
  PlayerData? playerData,
  String? email,
  String? username,
  String? dni,
  String? telefono,
  String? genero,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    if (playerData != null) {
      final playerDataJson = jsonEncode(playerData.toJson());
      await prefs.setString(_keyPlayerData, playerDataJson);
      affiliationPlayerDataNotifier.value = playerData;
      debugPrint('💾 [PERSIST] PlayerData guardado en SharedPreferences');
    }

    if (email != null && email.isNotEmpty) {
      await prefs.setString(_keyEmail, email);
      affiliationEmailNotifier.value = email;
    }

    if (username != null && username.isNotEmpty) {
      await prefs.setString(_keyUsername, username);
      affiliationUsernameNotifier.value = username;
    }

    if (dni != null && dni.isNotEmpty) {
      await prefs.setString(_keyDni, dni);
      affiliationDniNotifier.value = dni;
    }

    if (telefono != null && telefono.isNotEmpty) {
      await prefs.setString(_keyTelefono, telefono);
      affiliationTelefonoNotifier.value = telefono;
    }

    if (genero != null && genero.isNotEmpty) {
      await prefs.setString(_keyGenero, genero);
      affiliationGeneroNotifier.value = genero;
    }
  } catch (e) {
    debugPrint('❌ [PERSIST] Error guardando datos: $e');
  }
}

/// Carga datos de afiliación desde SharedPreferences
Future<void> loadAffiliationData() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Cargar PlayerData
    final playerDataJson = prefs.getString(_keyPlayerData);
    if (playerDataJson != null && playerDataJson.isNotEmpty) {
      try {
        final playerDataMap =
            jsonDecode(playerDataJson) as Map<String, dynamic>;
        affiliationPlayerDataNotifier.value = PlayerData.fromJson(
          playerDataMap,
        );
        debugPrint('💾 [PERSIST] PlayerData cargado desde SharedPreferences');
      } catch (e) {
        debugPrint('❌ [PERSIST] Error parseando PlayerData: $e');
      }
    }

    // Cargar otros datos
    final email = prefs.getString(_keyEmail) ?? '';
    if (email.isNotEmpty) {
      affiliationEmailNotifier.value = email;
    }

    final username = prefs.getString(_keyUsername) ?? '';
    if (username.isNotEmpty) {
      affiliationUsernameNotifier.value = username;
    }

    final dni = prefs.getString(_keyDni) ?? '';
    if (dni.isNotEmpty) {
      affiliationDniNotifier.value = dni;
    }

    final telefono = prefs.getString(_keyTelefono) ?? '';
    if (telefono.isNotEmpty) {
      affiliationTelefonoNotifier.value = telefono;
    }

    final genero = prefs.getString(_keyGenero) ?? '';
    if (genero.isNotEmpty) {
      affiliationGeneroNotifier.value = genero;
    }

    debugPrint(
      '✅ [PERSIST] Datos de afiliación cargados desde SharedPreferences',
    );
  } catch (e) {
    debugPrint('❌ [PERSIST] Error cargando datos: $e');
  }
}

/// Limpia todos los datos de afiliación
Future<void> clearAffiliationData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPlayerData);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyDni);
    await prefs.remove(_keyTelefono);
    await prefs.remove(_keyGenero);

    affiliationPlayerDataNotifier.value = null;
    affiliationEmailNotifier.value = '';
    affiliationUsernameNotifier.value = '';
    affiliationPasswordNotifier.value = '';
    affiliationDniNotifier.value = '';
    affiliationTelefonoNotifier.value = '';
    affiliationGeneroNotifier.value = '';

    debugPrint('🗑️ [PERSIST] Datos de afiliación limpiados');
  } catch (e) {
    debugPrint('❌ [PERSIST] Error limpiando datos: $e');
  }
}

/// Guarda el multiplicador de tamaño de fuente
Future<void> saveFontSizeMultiplier(double multiplier) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSizeMultiplier, multiplier);
    fontSizeMultiplierNotifier.value = multiplier;
    debugPrint('💾 [PERSIST] Font size multiplier guardado: $multiplier');
  } catch (e) {
    debugPrint('❌ [PERSIST] Error guardando font size multiplier: $e');
  }
}

/// Carga el multiplicador de tamaño de fuente
Future<void> loadFontSizeMultiplier() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final multiplier = prefs.getDouble(_keyFontSizeMultiplier) ?? 1.0;
    fontSizeMultiplierNotifier.value = multiplier;
    debugPrint('💾 [PERSIST] Font size multiplier cargado: $multiplier');
  } catch (e) {
    debugPrint('❌ [PERSIST] Error cargando font size multiplier: $e');
  }
}

Future<void> saveAffiliateType(String? type) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final normalized = type?.trim() ?? '';
    if (normalized.isEmpty) {
      await prefs.remove(_keyAffiliateType);
      affiliateTypeNotifier.value = '';
      return;
    }

    await prefs.setString(_keyAffiliateType, normalized);
    affiliateTypeNotifier.value = normalized;
  } catch (e) {
    debugPrint('❌ [PERSIST] Error guardando tipo afiliador: $e');
  }
}

Future<void> loadAffiliateType() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyAffiliateType) ?? '';
    affiliateTypeNotifier.value = value;
  } catch (e) {
    debugPrint('❌ [PERSIST] Error cargando tipo afiliador: $e');
  }
}

Future<void> clearAffiliateType() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAffiliateType);
    affiliateTypeNotifier.value = '';
  } catch (e) {
    debugPrint('❌ [PERSIST] Error limpiando tipo afiliador: $e');
  }
}

Future<void> saveAffiliateCodeUsage({
  required bool validated,
  String? token,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAffiliateCodeValidated, validated);
    affiliateCodeValidatedNotifier.value = validated;

    final normalized = token?.trim() ?? '';
    if (normalized.isEmpty) {
      await prefs.remove(_keyAffiliateCodeToken);
      affiliateCodeTokenNotifier.value = '';
    } else {
      await prefs.setString(_keyAffiliateCodeToken, normalized);
      affiliateCodeTokenNotifier.value = normalized;
    }
  } catch (e) {
    debugPrint('❌ [PERSIST] Error guardando uso de afiliador: $e');
  }
}

Future<void> loadAffiliateCodeUsage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final validated = prefs.getBool(_keyAffiliateCodeValidated) ?? false;
    affiliateCodeValidatedNotifier.value = validated;

    final token = prefs.getString(_keyAffiliateCodeToken) ?? '';
    affiliateCodeTokenNotifier.value = token;
  } catch (e) {
    debugPrint('❌ [PERSIST] Error cargando uso de afiliador: $e');
  }
}

Future<void> clearAffiliateCodeUsage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAffiliateCodeValidated);
    await prefs.remove(_keyAffiliateCodeToken);
    affiliateCodeValidatedNotifier.value = false;
    affiliateCodeTokenNotifier.value = '';
  } catch (e) {
    debugPrint('❌ [PERSIST] Error limpiando uso de afiliador: $e');
  }
}

Future<void> saveSelectedPage(int value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySelectedPage, value);
    selectedPageNotifier.value = value;
  } catch (e) {
    debugPrint('❌ [PERSIST] Error guardando selected page: $e');
  }
}

Future<void> loadSelectedPage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_keySelectedPage);
    if (saved != null) {
      selectedPageNotifier.value = saved;
    }
    selectedPageWasRestored = true;
  } catch (e) {
    debugPrint('❌ [PERSIST] Error cargando selected page: $e');
  }
}

Future<void> saveAffiliationFlowRoute(String route) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAffiliationFlowRoute, route);
  } catch (e) {
    debugPrint('❌ [PERSIST] Error guardando flow route: $e');
  }
}

Future<String?> loadAffiliationFlowRoute() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString(_keyAffiliationFlowRoute);
    return route?.trim().isEmpty == true ? null : route;
  } catch (e) {
    debugPrint('❌ [PERSIST] Error cargando flow route: $e');
    return null;
  }
}

Future<void> clearAffiliationFlowRoute() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAffiliationFlowRoute);
  } catch (e) {
    debugPrint('❌ [PERSIST] Error limpiando flow route: $e');
  }
}

/// Limpia todo el estado de sesión al hacer logout.
/// No limpia preferencias de dispositivo (font_size_multiplier, hasSeenOnboarding).
Future<void> clearSessionState() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySelectedPage);
    await prefs.remove(_keyAffiliateType);
    await prefs.remove(_keyAffiliateCodeValidated);
    await prefs.remove(_keyAffiliateCodeToken);

    selectedPageNotifier.value = 0;
    loginTutorialActiveNotifier.value = false;
    pendingLoginTutorialNotifier.value = false;
    rouletteTriggerAfterTutorialNotifier.value = false;
    emailVerifiedNotifier.value = false;
    affiliateTypeNotifier.value = '';
    affiliateCodeValidatedNotifier.value = false;
    affiliateCodeTokenNotifier.value = '';
    pageBackCallbacks.clear();

    await clearAffiliationData();
    await clearAffiliationFlowRoute();
    await clearAffiliationWsUrl();

    debugPrint('🗑️ [SESSION] Estado de sesión limpiado');
  } catch (e) {
    debugPrint('❌ [SESSION] Error limpiando estado de sesión: $e');
  }
}

Future<void> saveAffiliationWsUrl(String wsUrl) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAffiliationWsUrl, wsUrl);
  } catch (e) {
    debugPrint('❌ [PERSIST] Error guardando ws url: $e');
  }
}

Future<String?> loadAffiliationWsUrl() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final wsUrl = prefs.getString(_keyAffiliationWsUrl);
    return wsUrl?.trim().isEmpty == true ? null : wsUrl;
  } catch (e) {
    debugPrint('❌ [PERSIST] Error cargando ws url: $e');
    return null;
  }
}

Future<void> clearAffiliationWsUrl() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAffiliationWsUrl);
  } catch (e) {
    debugPrint('❌ [PERSIST] Error limpiando ws url: $e');
  }
}
