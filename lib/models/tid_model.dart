class TidModel {
  final int id;
  final String tid;
  final int idEvento;
  final int idAfiliador;
  final int? idStand;
  final int? sorteoId;
  final String? eventoNombre;
  final String? afiliadorNombre;

  const TidModel({
    required this.id,
    required this.tid,
    required this.idEvento,
    required this.idAfiliador,
    this.idStand,
    this.sorteoId,
    this.eventoNombre,
    this.afiliadorNombre,
  });

  TidModel copyWith({String? eventoNombre, String? afiliadorNombre}) {
    return TidModel(
      id: id,
      tid: tid,
      idEvento: idEvento,
      idAfiliador: idAfiliador,
      idStand: idStand,
      sorteoId: sorteoId,
      eventoNombre: eventoNombre ?? this.eventoNombre,
      afiliadorNombre: afiliadorNombre ?? this.afiliadorNombre,
    );
  }

  factory TidModel.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
    return TidModel(
      id: json['id'] is int ? json['id'] as int : 0,
      tid: json['tid']?.toString() ?? '',
      idEvento: json['idEvento'] is int ? json['idEvento'] as int : 0,
      idAfiliador: json['idAfiliador'] is int ? json['idAfiliador'] as int : 0,
      idStand: json['idStand'] is int ? json['idStand'] as int : null,
      sorteoId: parseId(json['sorteoId']),
      eventoNombre:
          json['eventoNombre']?.toString() ?? json['evento_nombre']?.toString(),
      afiliadorNombre:
          json['afiliadorNombre']?.toString() ??
          json['afiliador_nombre']?.toString(),
    );
  }
}
