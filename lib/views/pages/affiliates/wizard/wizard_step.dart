/// Tipos de datos para cada paso del wizard "Nuevo evento".
/// No contiene UI: solo las estructuras de datos que produce cada paso.
library;

import 'dart:typed_data';

// ── Paso 1: Evento ────────────────────────────────────────────────────────────

class EventoStepData {
  final String nombre;
  final DateTime fechaFin;
  const EventoStepData({required this.nombre, required this.fechaFin});
}

// ── Paso 2: Sorteo ────────────────────────────────────────────────────────────

class SorteoStepData {
  final bool skipped;
  final String nombre;
  final DateTime? fechaFin;
  final int cantidadGanadores;
  final List<String> premios;
  final Uint8List? imageBytes;
  final String? imageName;
  final String imageMimeType;
  final String emailPresentador;
  final int? casinoGralId;
  final String? instrucciones;

  const SorteoStepData({
    this.skipped = false,
    this.nombre = '',
    this.fechaFin,
    this.cantidadGanadores = 1,
    this.premios = const [''],
    this.imageBytes,
    this.imageName,
    this.imageMimeType = 'image/jpeg',
    this.emailPresentador = '',
    this.casinoGralId,
    this.instrucciones,
  });
}

// ── Paso 3: Formulario ────────────────────────────────────────────────────────

class FormularioStepData {
  final bool skipped;
  final String? contrasena;
  const FormularioStepData({this.skipped = false, this.contrasena});
}

// ── Paso 4: TIDs ─────────────────────────────────────────────────────────────

class TidEntry {
  final String nombre;
  final int? standId;
  final String? standNombre;
  const TidEntry({required this.nombre, this.standId, this.standNombre});
}

class TidsStepData {
  final List<TidEntry> entries;
  const TidsStepData({required this.entries});

  /// Compatibilidad con código que usaba .nombres directamente.
  List<String> get nombres => entries.map((e) => e.nombre).toList();
}

// ── Resultado final del wizard ────────────────────────────────────────────────

class WizardCreationResult {
  final int eventoId;
  final String eventoNombre;
  final int? sorteoId;
  final int? formularioId;
  final List<({int id, String tid})> tids;

  const WizardCreationResult({
    required this.eventoId,
    required this.eventoNombre,
    this.sorteoId,
    this.formularioId,
    required this.tids,
  });
}
