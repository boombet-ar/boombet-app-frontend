import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

ValueNotifier<int> selectedPageNotifier = ValueNotifier(0);

/// Sistema de navegación interna universal.
/// Cada página registra un callback de "volver" por su índice de tab.
/// El PopScope del home lo consulta antes de mostrar el diálogo de logout.
/// Uso: pageBackCallbacks[pageIndex] = () { ... }  // al entrar a sub-sección
///      pageBackCallbacks.remove(pageIndex);         // al volver al root
final Map<int, VoidCallback> pageBackCallbacks = {};

ValueNotifier<bool> emailVerifiedNotifier = ValueNotifier(false);
ValueNotifier<double> fontSizeMultiplierNotifier = ValueNotifier(1.0);

bool selectedPageWasRestored = false;

const String _keyFontSizeMultiplier = 'font_size_multiplier';
const String _keySelectedPage = 'selected_page_index';

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

Future<void> clearSelectedPage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySelectedPage);
    selectedPageNotifier.value = 0;
  } catch (e) {
    debugPrint('❌ [PERSIST] Error limpiando selected page: $e');
  }
}
