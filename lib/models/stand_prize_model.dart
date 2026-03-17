class StandPrizeModel {
  final int id;
  final int idPremioUsuario;
  final String nombre;
  final String imgUrl;
  final int stock;
  final int idStand;

  const StandPrizeModel({
    required this.id,
    required this.idPremioUsuario,
    required this.nombre,
    required this.imgUrl,
    required this.stock,
    required this.idStand,
  });

  factory StandPrizeModel.fromJson(Map<String, dynamic> json) {
    return StandPrizeModel(
      id: json['id'] is int ? json['id'] as int : 0,
      idPremioUsuario: json['idPremioUsuario'] is int
          ? json['idPremioUsuario'] as int
          : 0,
      nombre: json['nombre']?.toString() ?? '',
      imgUrl: json['imgUrl']?.toString() ?? '',
      stock: json['stock'] is int ? json['stock'] as int : 0,
      idStand: json['idStand'] is int ? json['idStand'] as int : 0,
    );
  }
}
