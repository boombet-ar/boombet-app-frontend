class PremioModel {
  final String nombre;
  final String imgUrl;
  final int orden;

  const PremioModel({
    required this.nombre,
    required this.imgUrl,
    required this.orden,
  });

  factory PremioModel.fromMap(Map<String, dynamic> map) {
    return PremioModel(
      nombre: map['nombre']?.toString() ?? '',
      imgUrl: map['imgUrl']?.toString() ?? '',
      orden: map['orden'] is int
          ? map['orden']
          : int.tryParse(map['orden']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'imgUrl': imgUrl,
        'orden': orden,
      };
}

class RaffleModel {
  final int? id;
  final String codigoSorteo;
  final bool activo;
  final int cantidadGanadores;
  final String? emailPresentador;
  final String text;
  final String mediaUrl;
  final int? casinoGralId;
  final int? tidId;
  final String fechaFin;
  final List<PremioModel> premios;
  final int? afiliadorId;
  final String createdAt;

  const RaffleModel({
    required this.id,
    required this.codigoSorteo,
    required this.activo,
    required this.cantidadGanadores,
    this.emailPresentador,
    required this.text,
    required this.mediaUrl,
    required this.casinoGralId,
    required this.tidId,
    required this.fechaFin,
    required this.premios,
    required this.afiliadorId,
    required this.createdAt,
  });

  factory RaffleModel.fromMap(Map<String, dynamic> map) {
    int? parseId(dynamic raw) {
      if (raw is int) return raw;
      if (raw != null) return int.tryParse(raw.toString());
      return null;
    }

    final rawPremios = map['premios'];
    final premios = rawPremios is List
        ? rawPremios
            .whereType<Map>()
            .map((p) => PremioModel.fromMap(Map<String, dynamic>.from(p)))
            .toList(growable: false)
        : const <PremioModel>[];

    return RaffleModel(
      id: parseId(map['id'] ?? map['sorteoId']),
      codigoSorteo: map['codigoSorteo']?.toString() ?? '',
      activo: map['activo'] == true,
      cantidadGanadores: parseId(map['cantidadGanadores']) ?? 0,
      emailPresentador: map['emailPresentador']?.toString(),
      text: map['text']?.toString() ?? '',
      mediaUrl: map['mediaUrl']?.toString() ?? '',
      casinoGralId: parseId(map['casinoGralId']),
      tidId: parseId(map['tidId']),
      fechaFin: map['fechaFin']?.toString() ?? map['endAt']?.toString() ?? '',
      premios: premios,
      afiliadorId: parseId(map['afiliadorId']),
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }
}
