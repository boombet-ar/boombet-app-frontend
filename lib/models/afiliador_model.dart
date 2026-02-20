class AfiliadorModel {
  final int id;
  final String nombre;
  final String tokenAfiliador;
  final String tipoAfiliador;
  final int cantAfiliaciones;
  final bool activo;
  final String email;
  final String dni;
  final String telefono;

  const AfiliadorModel({
    required this.id,
    required this.nombre,
    required this.tokenAfiliador,
    required this.tipoAfiliador,
    required this.cantAfiliaciones,
    required this.activo,
    required this.email,
    required this.dni,
    required this.telefono,
  });

  factory AfiliadorModel.fromJson(Map<String, dynamic> json) {
    final rawTipo =
        json['tipo_afiliador'] ?? json['tipoAfiliador'] ?? json['tipo'];
    final tipoAfiliador = rawTipo is Map
        ? (rawTipo['nombre'] ?? rawTipo['name'] ?? rawTipo['value'])
                  ?.toString() ??
              ''
        : rawTipo?.toString() ?? '';

    return AfiliadorModel(
      id: json['id'] is int ? json['id'] as int : 0,
      nombre: json['nombre']?.toString() ?? '',
      tokenAfiliador: json['token_afiliador']?.toString() ?? '',
      tipoAfiliador: tipoAfiliador,
      cantAfiliaciones: json['cant_afiliaciones'] is int
          ? json['cant_afiliaciones'] as int
          : 0,
      activo: json['activo'] == true,
      email: json['email']?.toString() ?? '',
      dni: json['dni']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
    );
  }
}

class AfiliadoresPage {
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;
  final List<AfiliadorModel> content;

  const AfiliadoresPage({
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.content,
  });

  factory AfiliadoresPage.fromJson(Map<String, dynamic> json) {
    final content = <AfiliadorModel>[];
    final nestedData = json['data'];
    final rawContent =
        json['content'] ??
        (nestedData is Map ? nestedData['content'] : null) ??
        (nestedData is Map ? nestedData['items'] : null);

    if (rawContent is List) {
      for (final item in rawContent) {
        if (item is Map) {
          content.add(AfiliadorModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    int readInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return fallback;
    }

    final totalElementsValue =
        json['totalElements'] ??
        (nestedData is Map ? nestedData['totalElements'] : null);
    final totalPagesValue =
        json['totalPages'] ??
        (nestedData is Map ? nestedData['totalPages'] : null);
    final sizeValue =
        json['size'] ?? (nestedData is Map ? nestedData['size'] : null);
    final numberValue =
        json['number'] ?? (nestedData is Map ? nestedData['number'] : null);
    final firstValue =
        json['first'] ?? (nestedData is Map ? nestedData['first'] : null);
    final lastValue =
        json['last'] ?? (nestedData is Map ? nestedData['last'] : null);

    return AfiliadoresPage(
      totalElements: readInt(totalElementsValue, fallback: content.length),
      totalPages: readInt(totalPagesValue),
      size: readInt(sizeValue, fallback: content.length),
      number: readInt(numberValue),
      first: firstValue == true,
      last: lastValue == true,
      content: content,
    );
  }
}
