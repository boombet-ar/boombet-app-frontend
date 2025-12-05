import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

ValueNotifier<int> selectedPageNotifier = ValueNotifier(0);
ValueNotifier<bool> isLightModeNotifier = ValueNotifier(false);
ValueNotifier<bool> emailVerifiedNotifier = ValueNotifier(false);

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

/// Guarda datos de afiliación en SharedPreferences
Future<void> saveAffiliationData({
  PlayerData? playerData,
  String? email,
  String? username,
  String? password,
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

    if (password != null && password.isNotEmpty) {
      await prefs.setString(_keyPassword, password);
      affiliationPasswordNotifier.value = password;
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

    final password = prefs.getString(_keyPassword) ?? '';
    if (password.isNotEmpty) {
      affiliationPasswordNotifier.value = password;
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
