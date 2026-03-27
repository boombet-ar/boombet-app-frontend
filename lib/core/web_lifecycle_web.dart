import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:boombet_app/core/notifiers.dart';

/// Registra el listener de beforeunload para proteger flujos críticos en web.
/// Cuando criticalFlowActive == true, el navegador muestra su diálogo nativo
/// de confirmación antes de permitir F5, cierre de pestaña o navegación externa.
///
/// Implementado con package:web + dart:js_interop (Flutter 3.22+).
/// dart:html está deprecated en Dart 3.x.
void registerBeforeUnloadHandler() {
  web.window.addEventListener(
    'beforeunload',
    (web.BeforeUnloadEvent event) {
      if (criticalFlowActive) {
        event.preventDefault();
        event.returnValue = '';
      }
    }.toJS,
  );
}
