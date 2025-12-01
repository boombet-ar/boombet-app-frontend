import 'casino_response.dart';

class AffiliationResult {
  final Map<String, dynamic> playerData;
  final Map<String, CasinoResponse> responses;

  AffiliationResult({required this.playerData, required this.responses});

  factory AffiliationResult.fromJson(Map<String, dynamic> json) {
    final rawResponses = json['responses'];

    // Validación fuerte
    if (rawResponses == null || rawResponses is! Map) {
      return AffiliationResult(playerData: {}, responses: {});
    }

    final mapped = <String, CasinoResponse>{};

    rawResponses.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        mapped[key] = CasinoResponse.fromJson(value);
      }
    });

    return AffiliationResult(
      playerData: json['playerData'] ?? {},
      responses: mapped,
    );
  }

  Map<String, int> get statusCount {
    int success = 0;
    int already = 0;
    int error = 0;

    for (final r in responses.values) {
      if (r.isSuccess) {
        success++;
      } else if (r.isWarning) {
        already++;
      } else {
        error++;
      }
    }

    return {
      'success': success,
      'alreadyAffiliated': already,
      'error': error,
      'total': responses.length,
    };
  }
}
