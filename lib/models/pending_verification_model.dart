class PendingVerification {
  final int id;
  final String casinoUserId;
  final String nombreCompleto;

  const PendingVerification({
    required this.id,
    required this.casinoUserId,
    required this.nombreCompleto,
  });

  factory PendingVerification.fromJson(Map<String, dynamic> json) =>
      PendingVerification(
        id: json['id'] as int,
        casinoUserId: json['casinoUserId'] as String? ?? '',
        nombreCompleto: json['nombreCompleto'] as String? ?? '',
      );
}
