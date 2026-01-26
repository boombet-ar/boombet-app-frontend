class AfiliadorModel {
  final int id;
  final String nombre;
  final String tokenAfiliador;
  final int cantAfiliaciones;
  final bool activo;
  final String email;
  final String dni;
  final String telefono;

  const AfiliadorModel({
    required this.id,
    required this.nombre,
    required this.tokenAfiliador,
    required this.cantAfiliaciones,
    required this.activo,
    required this.email,
    required this.dni,
    required this.telefono,
  });

  factory AfiliadorModel.fromJson(Map<String, dynamic> json) {
    return AfiliadorModel(
      id: json['id'] is int ? json['id'] as int : 0,
      nombre: json['nombre']?.toString() ?? '',
      tokenAfiliador: json['token_afiliador']?.toString() ?? '',
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
    final rawContent = json['content'];
    if (rawContent is List) {
      for (final item in rawContent) {
        if (item is Map<String, dynamic>) {
          content.add(AfiliadorModel.fromJson(item));
        }
      }
    }

    return AfiliadoresPage(
      totalElements: json['totalElements'] is int
          ? json['totalElements'] as int
          : content.length,
      totalPages: json['totalPages'] is int ? json['totalPages'] as int : 0,
      size: json['size'] is int ? json['size'] as int : content.length,
      number: json['number'] is int ? json['number'] as int : 0,
      first: json['first'] == true,
      last: json['last'] == true,
      content: content,
    );
  }
}
