class StandModel {
  final int id;
  final String nombre;
  final bool activo;
  final int idAfiliador;
  final int idUsuario;

  const StandModel({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.idAfiliador,
    required this.idUsuario,
  });

  StandModel copyWith({
    int? id,
    String? nombre,
    bool? activo,
    int? idAfiliador,
    int? idUsuario,
  }) {
    return StandModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      activo: activo ?? this.activo,
      idAfiliador: idAfiliador ?? this.idAfiliador,
      idUsuario: idUsuario ?? this.idUsuario,
    );
  }

  factory StandModel.fromJson(Map<String, dynamic> json) {
    return StandModel(
      id: json['id'] is int ? json['id'] as int : 0,
      nombre: json['nombre']?.toString() ?? '',
      activo: json['activo'] as bool? ?? true,
      idAfiliador: json['idAfiliador'] is int ? json['idAfiliador'] as int : 0,
      idUsuario: json['idUsuario'] is int ? json['idUsuario'] as int : 0,
    );
  }
}
