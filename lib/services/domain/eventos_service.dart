import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:boombet_app/services/infra/http_client.dart';
import 'package:boombet_app/services/infra/token_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// ── Tipos para el wizard bulk ─────────────────────────────────────────────────

class WizardInput {
  final String eventoNombre;
  final DateTime eventoFechaFin;
  final bool hasSorteo;
  final String? sorteoText;
  final DateTime? sorteoFechaFin;
  final int sorteoGanadores;
  final String? sorteoEmail;
  final String? sorteoInstrucciones;
  final List<Map<String, dynamic>> sorteoPremios;
  final int? sorteoCasinoGralId;
  final Uint8List? sorteoImageBytes;
  final String? sorteoImageName;
  final String sorteoImageMimeType;
  final bool hasFormulario;
  final String? formularioContrasena;
  final List<String> tidStrings;

  const WizardInput({
    required this.eventoNombre,
    required this.eventoFechaFin,
    this.hasSorteo = false,
    this.sorteoText,
    this.sorteoFechaFin,
    this.sorteoGanadores = 1,
    this.sorteoEmail,
    this.sorteoInstrucciones,
    this.sorteoPremios = const [],
    this.sorteoCasinoGralId,
    this.sorteoImageBytes,
    this.sorteoImageName,
    this.sorteoImageMimeType = 'image/jpeg',
    this.hasFormulario = false,
    this.formularioContrasena,
    this.tidStrings = const [],
  });
}

typedef WizardResult = ({
  int eventoId,
  String eventoNombre,
  int? sorteoId,
  int? formularioId,
  List<({int id, String tid})> tids,
});

class EventosService {
  Future<EventoModel> createEvento({
    required String nombre,
    required DateTime fechaFin,
  }) async {
    final url = '${ApiConfig.baseUrl}/eventos';
    final body = <String, dynamic>{
      'nombre': nombre.trim(),
      'activo': true,
      'fechaFin': fechaFin.toUtc().toIso8601String(),
    };

    final response = await HttpClient.post(url, includeAuth: true, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return EventoModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<EventoModel> toggleEventoActivo({required int id, required bool activo}) async {
    final url = '${ApiConfig.baseUrl}/eventos/$id';

    final response = await HttpClient.patch(
      url,
      includeAuth: true,
      body: {'activo': activo},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return EventoModel.fromJson(data);
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<void> deleteEvento({required int id, required bool cascade}) async {
    final url = '${ApiConfig.baseUrl}/eventos/$id?cascade=$cascade';

    final response = await HttpClient.delete(url, includeAuth: true);

    if (response.statusCode == 200 || response.statusCode == 204) return;

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<List<EventoModel>> fetchEventos({bool includeDetails = true}) async {
    final url = '${ApiConfig.baseUrl}/eventos${includeDetails ? '' : '?includeDetails=false'}';

    final response = await HttpClient.get(
      url,
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      List<dynamic>? rawList;

      if (data is List) {
        rawList = data;
      } else if (data is Map) {
        final raw = data['content'];
        if (raw is List) rawList = raw;
      }

      if (rawList == null) {
        throw Exception('Formato inesperado de respuesta');
      }

      final result = <EventoModel>[];
      for (final item in rawList) {
        if (item is Map) {
          result.add(EventoModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return result;
    }

    log('[EventosService] fetchEventos error ${response.statusCode}: ${response.body}');
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<int> fetchEventoTotalAfiliaciones({required int id}) async {
    final url = '${ApiConfig.baseUrl}/eventos/$id/afiliaciones';

    final response = await HttpClient.get(
      url,
      includeAuth: true,
      cacheTtl: Duration.zero,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return (data['totalJugadores'] as num?)?.toInt() ?? 0;
      }
      throw Exception('Formato inesperado de respuesta');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  // ── Wizard bulk ───────────────────────────────────────────────────────────────

  Future<WizardResult> createWizard(WizardInput input) async {
    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token no encontrado. Iniciá sesión nuevamente.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/eventos/wizard'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    final body = <String, dynamic>{
      'evento': {
        'nombre': input.eventoNombre.trim(),
        'fechaFin': _toIso8601WithOffset(input.eventoFechaFin),
      },
      if (input.hasSorteo) 'sorteo': {
        'text': input.sorteoText!.trim(),
        'cantidadGanadores': input.sorteoGanadores,
        'emailPresentador': input.sorteoEmail!.trim(),
        if (input.sorteoFechaFin != null)
          'fechaFin': _toIso8601WithOffset(input.sorteoFechaFin!),
        if (input.sorteoInstrucciones != null && input.sorteoInstrucciones!.isNotEmpty)
          'instrucciones': input.sorteoInstrucciones,
        if (input.sorteoCasinoGralId != null) 'casinoGralId': input.sorteoCasinoGralId,
        'premios': input.sorteoPremios.isNotEmpty
            ? input.sorteoPremios
            : [<String, dynamic>{'nombre': 'Premio principal', 'orden': 1}],
      },
      if (input.hasFormulario) 'formulario': {
        'contrasena': input.formularioContrasena,
      },
      if (input.tidStrings.isNotEmpty) 'tids': input.tidStrings,
    };

    request.files.add(
      http.MultipartFile.fromString(
        'data',
        jsonEncode(body),
        filename: 'data.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    if (input.sorteoImageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'media',
          input.sorteoImageBytes!,
          filename: input.sorteoImageName ?? 'sorteo.jpg',
          contentType: MediaType.parse(input.sorteoImageMimeType),
        ),
      );
    }

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('HTTP ${streamed.statusCode}: $responseBody');
    }

    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) throw Exception('Formato inesperado de respuesta');

    int? parseInt(dynamic raw) {
      if (raw is int) return raw;
      if (raw != null) return int.tryParse(raw.toString());
      return null;
    }

    final eventoJson = decoded['evento'] as Map<String, dynamic>;
    final sorteoJson = decoded['sorteo'];
    final formularioJson = decoded['formulario'];
    final tidsJson = decoded['tids'];

    final tids = <({int id, String tid})>[];
    if (tidsJson is List) {
      for (final t in tidsJson.whereType<Map>()) {
        final id = parseInt(t['id']) ?? 0;
        final tidStr = t['tid']?.toString() ?? '';
        tids.add((id: id, tid: tidStr));
      }
    }

    return (
      eventoId: parseInt(eventoJson['id']) ?? 0,
      eventoNombre: eventoJson['nombre']?.toString() ?? '',
      sorteoId: sorteoJson is Map ? parseInt(sorteoJson['id']) : null,
      formularioId: formularioJson is Map ? parseInt(formularioJson['id']) : null,
      tids: tids,
    );
  }

  String _toIso8601WithOffset(DateTime dateTime) {
    final local = dateTime.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final totalMinutes = offset.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$year-$month-${day}T$hour:$minute:$second$sign$hours:$minutes';
  }
}
