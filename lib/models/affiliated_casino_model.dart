class AffiliatedCasino {
  final int id;
  final int idAfiliacion;
  final String url;
  final String nombreGral;
  final String logoUrl;
  final String? verified;

  const AffiliatedCasino({
    required this.id,
    required this.idAfiliacion,
    required this.url,
    required this.nombreGral,
    required this.logoUrl,
    this.verified,
  });

  factory AffiliatedCasino.fromJson(Map<String, dynamic> json) =>
      AffiliatedCasino(
        id: json['id'] as int,
        idAfiliacion: json['idAfiliacion'] as int,
        url: json['url'] as String? ?? '',
        nombreGral: json['nombreGral'] as String? ?? '',
        logoUrl: json['logoUrl'] as String? ?? '',
        verified: json['verified'] as String?,
      );
}
