class CasinoResponse {
  final String message;
  final bool success;
  final String? error;

  CasinoResponse({required this.message, required this.success, this.error});

  factory CasinoResponse.fromJson(Map<String, dynamic> json) {
    return CasinoResponse(
      message: json['message'] ?? 'error',
      success: json['success'] ?? false,
      error: json['error'],
    );
  }

  bool get isSuccess => message == 'OK';
  bool get isWarning => message == 'Jugador previamente afiliado';
  bool get isError => !isSuccess && !isWarning;

  String get statusIcon {
    if (isSuccess) return '✅';
    if (isWarning) return '⚠️';
    return '❌';
  }

  String get statusMessage {
    if (isSuccess) return 'Afiliado exitosamente';
    if (isWarning) return 'Ya estabas afiliado';
    return 'Error en la afiliación';
  }
}
