class RaffleModel {
  final int? id;
  final int? casinoGralId;
  final String endAt;
  final String mediaUrl;
  final String text;

  const RaffleModel({
    required this.id,
    required this.casinoGralId,
    required this.endAt,
    required this.mediaUrl,
    required this.text,
  });

  factory RaffleModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'] ?? map['sorteoId'];
    int? parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId != null) {
      parsedId = int.tryParse(rawId.toString());
    }

    final idValue = map['casinoGralId'];
    int? parsedCasinoId;
    if (idValue is int) {
      parsedCasinoId = idValue;
    } else if (idValue != null) {
      parsedCasinoId = int.tryParse(idValue.toString());
    }

    return RaffleModel(
      id: parsedId,
      casinoGralId: parsedCasinoId,
      endAt: map['endAt']?.toString() ?? '',
      mediaUrl: map['mediaUrl']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
    );
  }
}
