class Cupon {
  final String id;
  final String descuento;
  final String nombre;
  final String descripcionBreve;
  final String descripcionMicrositio;
  final String legales;
  final String fechaVencimiento;
  final bool permitirSms;
  final Map<String, bool> usarEn;
  final Map<String, String> fotoThumbnail;
  final Map<String, String> fotoPrincipal;
  final List<Categoria> categorias;
  final Empresa empresa;

  Cupon({
    required this.id,
    required this.descuento,
    required this.nombre,
    required this.descripcionBreve,
    required this.descripcionMicrositio,
    required this.legales,
    required this.fechaVencimiento,
    required this.permitirSms,
    required this.usarEn,
    required this.fotoThumbnail,
    required this.fotoPrincipal,
    required this.categorias,
    required this.empresa,
  });

  // Obtener URL de imagen principal (preferir 280x190, fallback a original)
  String get fotoUrl {
    return fotoPrincipal['280x190'] ?? fotoPrincipal['original'] ?? '';
  }

  // Obtener URL de logo de empresa
  String get logoUrl {
    return empresa.logoThumbnail['original'] ?? '';
  }

  factory Cupon.fromJson(Map<String, dynamic> json) {
    return Cupon(
      id: json['id']?.toString() ?? '',
      descuento: json['descuento']?.toString() ?? 'N/A',
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      descripcionBreve: json['descripcion_breve']?.toString() ?? '',
      descripcionMicrositio: json['descripcion_micrositio']?.toString() ?? '',
      legales: json['legales']?.toString() ?? '',
      fechaVencimiento: json['fecha_vencimiento']?.toString() ?? '',
      permitirSms: json['permitir_sms'] as bool? ?? false,
      usarEn: _parseUsarEn(json['usar_en']),
      fotoThumbnail: _parseFoto(json['foto_thumbnail']),
      fotoPrincipal: _parseFoto(json['foto_principal']),
      categorias: _parseCategorias(json['categorias']),
      empresa: Empresa.fromJson(json['empresa'] ?? {}),
    );
  }

  static Map<String, bool> _parseUsarEn(dynamic data) {
    if (data is Map) {
      return {
        'email': data['email'] as bool? ?? false,
        'phone': data['phone'] as bool? ?? false,
        'online': data['online'] as bool? ?? false,
        'onsite': data['onsite'] as bool? ?? false,
        'whatsapp': data['whatsapp'] as bool? ?? false,
      };
    }
    return {
      'email': false,
      'phone': false,
      'online': false,
      'onsite': false,
      'whatsapp': false,
    };
  }

  static Map<String, String> _parseFoto(dynamic data) {
    final result = <String, String>{};
    if (data is Map) {
      data.forEach((key, value) {
        if (value is String) {
          result[key] = value;
        }
      });
    }
    return result;
  }

  static List<Categoria> _parseCategorias(dynamic data) {
    if (data is List) {
      return data
          .map((item) => Categoria.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

class Categoria {
  final dynamic id;
  final String nombre;
  final dynamic parentId;

  Categoria({required this.id, required this.nombre, this.parentId});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre']?.toString() ?? '',
      parentId: json['parent_id'],
    );
  }
}

class Empresa {
  final String id;
  final String nombre;
  final Map<String, String> logoThumbnail;
  final String descripcion;

  Empresa({
    required this.id,
    required this.nombre,
    required this.logoThumbnail,
    required this.descripcion,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      logoThumbnail: _parseLogoThumbnail(json['logo_thumbnail']),
      descripcion: json['descripcion']?.toString() ?? '',
    );
  }

  static Map<String, String> _parseLogoThumbnail(dynamic data) {
    final result = <String, String>{};
    if (data is Map) {
      data.forEach((key, value) {
        if (value is String) {
          result[key] = value;
        }
      });
    }
    return result;
  }
}
