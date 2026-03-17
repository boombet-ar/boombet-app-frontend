class PrizeCanjeModel {
  final int idPremioUsuario;
  final String nombrePremio;
  final String imgUrl;
  final String usernameUsuario;
  final bool reclamado;

  const PrizeCanjeModel({
    required this.idPremioUsuario,
    required this.nombrePremio,
    required this.imgUrl,
    required this.usernameUsuario,
    required this.reclamado,
  });

  factory PrizeCanjeModel.fromJson(Map<String, dynamic> json) {
    return PrizeCanjeModel(
      idPremioUsuario: json['idPremioUsuario'] is int
          ? json['idPremioUsuario'] as int
          : 0,
      nombrePremio: json['nombrePremio']?.toString() ?? '',
      imgUrl: json['imgUrl']?.toString() ?? '',
      usernameUsuario: json['usernameUsuario']?.toString() ?? '',
      reclamado: json['reclamado'] == true,
    );
  }
}
