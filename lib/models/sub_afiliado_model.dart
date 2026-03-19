class SubAfiliadoModel {
  final int id;
  final String nombre;
  final bool activo;
  final int idUsuario;
  final int idPadre;

  const SubAfiliadoModel({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.idUsuario,
    required this.idPadre,
  });

  factory SubAfiliadoModel.fromJson(Map<String, dynamic> json) {
    return SubAfiliadoModel(
      id: (json['id'] as num).toInt(),
      nombre: (json['nombre'] ?? '') as String,
      activo: (json['activo'] ?? true) as bool,
      idUsuario: (json['idUsuario'] as num?)?.toInt() ?? 0,
      idPadre: (json['idPadre'] as num?)?.toInt() ?? 0,
    );
  }

  SubAfiliadoModel copyWith({
    int? id,
    String? nombre,
    bool? activo,
    int? idUsuario,
    int? idPadre,
  }) {
    return SubAfiliadoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      activo: activo ?? this.activo,
      idUsuario: idUsuario ?? this.idUsuario,
      idPadre: idPadre ?? this.idPadre,
    );
  }
}
