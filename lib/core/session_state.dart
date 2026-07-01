import 'package:flutter/widgets.dart';
import 'package:boombet_app/core/affiliation_notifiers.dart';
import 'package:boombet_app/core/ui_notifiers.dart';

/// Limpia todo el estado de sesión al hacer logout.
/// No limpia preferencias de dispositivo (font_size_multiplier, hasSeenOnboarding).
Future<void> clearSessionState() async {
  try {
    await clearSelectedPage();
    emailVerifiedNotifier.value = false;
    pageBackCallbacks.clear();

    await clearAffiliateType();
    await clearAffiliateCodeUsage();
    await clearAffiliationData();
    await clearAffiliationFlowRoute();
    await clearAffiliationWsUrl();

    debugPrint('🗑️ [SESSION] Estado de sesión limpiado');
  } catch (e) {
    debugPrint('❌ [SESSION] Error limpiando estado de sesión: $e');
  }
}
