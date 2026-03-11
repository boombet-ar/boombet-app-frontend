class EventoModel {
  final int id;
  final String nombre;
  final bool activo;
  final String? fechaFin;
  final int idAfiliador;

  const EventoModel({
    required this.id,
    required this.nombre,
    required this.activo,
    this.fechaFin,
    required this.idAfiliador,
  });

  factory EventoModel.fromJson(Map<String, dynamic> json) {
    return EventoModel(
      id: json['id'] is int ? json['id'] as int : 0,
      nombre: json['nombre']?.toString() ?? '',
      activo: json['activo'] == true,
      fechaFin: json['fechaFin']?.toString(),
      idAfiliador: json['idAfiliador'] is int ? json['idAfiliador'] as int : 0,
    );
  }
}

class EventosPaginatedResponse {
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;
  final List<EventoModel> content;

  const EventosPaginatedResponse({
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.content,
  });

  factory EventosPaginatedResponse.fromJson(Map<String, dynamic> json) {
    final content = <EventoModel>[];
    final rawContent = json['content'];

    if (rawContent is List) {
      for (final item in rawContent) {
        if (item is Map) {
          content.add(EventoModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    int readInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return fallback;
    }

    final parsedTotal = readInt(json['totalElements']);
    final parsedPages = readInt(json['totalPages']);
    final parsedSize = readInt(json['size']);

    // Si el backend manda 0 pero hay contenido, inferimos los valores mínimos
    final totalElements =
        parsedTotal > 0 ? parsedTotal : content.length;
    final totalPages =
        parsedPages > 0 ? parsedPages : (content.isNotEmpty ? 1 : 0);
    final size =
        parsedSize > 0 ? parsedSize : content.length;

    return EventosPaginatedResponse(
      totalElements: totalElements,
      totalPages: totalPages,
      size: size,
      number: readInt(json['number']),
      first: json['first'] == true,
      last: json['last'] == true,
      content: content,
    );
  }
}
