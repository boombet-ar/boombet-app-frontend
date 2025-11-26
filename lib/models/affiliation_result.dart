/// Modelo para el resultado completo de afiliación
class AffiliationResult {
  final Map<String, dynamic> playerData;
  final Map<String, CasinoResponse> responses;

  AffiliationResult({required this.playerData, required this.responses});

  factory AffiliationResult.fromJson(Map<String, dynamic> json) {
    final responsesJson = json['responses'] as Map<String, dynamic>;
    final responses = <String, CasinoResponse>{};

    responsesJson.forEach((key, value) {
      responses[key] = CasinoResponse.fromJson(value as Map<String, dynamic>);
    });

    return AffiliationResult(
      playerData: json['playerData'] as Map<String, dynamic>,
      responses: responses,
    );
  }

  /// Retorna el conteo de casinos por estado
  Map<String, int> get statusCount {
    int success = 0;
    int alreadyAffiliated = 0;
    int error = 0;

    for (var response in responses.values) {
      if (response.message == 'OK') {
        success++;
      } else if (response.message == 'Jugador previamente afiliado') {
        alreadyAffiliated++;
      } else if (response.message == 'error') {
        error++;
      }
    }

    return {
      'success': success,
      'alreadyAffiliated': alreadyAffiliated,
      'error': error,
      'total': responses.length,
    };
  }
}

/// Modelo para la respuesta de afiliación de un casino individual
class CasinoResponse {
  final String message; // 'OK', 'error', 'Jugador previamente afiliado'
  final bool success;
  final String? error;

  CasinoResponse({required this.message, required this.success, this.error});

  factory CasinoResponse.fromJson(Map<String, dynamic> json) {
    return CasinoResponse(
      message: json['message'] as String,
      success: json['success'] as bool,
      error: json['error'] as String?,
    );
  }

  /// Retorna un mensaje user-friendly del estado
  String get statusMessage {
    if (message == 'OK') {
      return 'Afiliado exitosamente';
    } else if (message == 'Jugador previamente afiliado') {
      return 'Ya estabas afiliado';
    } else {
      return 'Error en la afiliación';
    }
  }

  /// Retorna un icono según el estado
  String get statusIcon {
    if (message == 'OK') {
      return '✅';
    } else if (message == 'Jugador previamente afiliado') {
      return '⚠️';
    } else {
      return '❌';
    }
  }

  /// Retorna un color según el estado
  bool get isSuccess => message == 'OK';
  bool get isWarning => message == 'Jugador previamente afiliado';
  bool get isError => message == 'error';
}
