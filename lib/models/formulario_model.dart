class FormularioModel {
  final int id;
  final String? contrasena;
  final int? tidId;
  final int? sorteoId;
  final int? afiliadorId;
  final int? eventoId;

  const FormularioModel({
    required this.id,
    this.contrasena,
    this.tidId,
    this.sorteoId,
    this.afiliadorId,
    this.eventoId,
  });

  factory FormularioModel.fromMap(Map<String, dynamic> map) {
    int? parseId(dynamic raw) {
      if (raw is int) return raw;
      if (raw != null) return int.tryParse(raw.toString());
      return null;
    }

    return FormularioModel(
      id: parseId(map['id']) ?? 0,
      contrasena: map['contrasena']?.toString(),
      tidId: parseId(map['tidId']),
      sorteoId: parseId(map['sorteoId']),
      afiliadorId: parseId(map['afiliadorId']),
      eventoId: parseId(map['eventoId']),
    );
  }
}
