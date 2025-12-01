import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AffiliationService {
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream para escuchar mensajes del WebSocket desde la UI
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Conecta al WebSocket y escucha mensajes de afiliación
  Future<void> connectToWebSocket({
    required String wsUrl,
    String token = '',
  }) async {
    log('[AffiliationService] Conectando a WebSocket: $wsUrl');

    try {
      // Cerrar conexión previa si existe
      closeWebSocket();

      // Parsear y loguear la URI
      final uri = Uri.parse(wsUrl);
      log('[AffiliationService] URI parseada: $uri');
      log(
        '[AffiliationService] Scheme: ${uri.scheme}, '
        'Host: ${uri.host}, Port: ${uri.port}, Path: ${uri.path}',
      );

      // Conectar usando WebSocket nativo de dart:io
      final webSocket =
          await WebSocket.connect(
            wsUrl,
            headers: {if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('WebSocket connection timeout');
            },
          );

      // Crear el canal desde el WebSocket conectado
      _channel = IOWebSocketChannel(webSocket);
      log('[AffiliationService] ✅ WebSocket conectado exitosamente');

      // Escuchar mensajes del WebSocket
      _wsSubscription = _channel!.stream.listen(
        (message) {
          try {
            log('[AffiliationService] 📩 Mensaje recibido: $message');
            if (message is String) {
              final data = jsonDecode(message);
              if (!_messageController.isClosed) {
                _messageController.add(data);
              }
            }
          } catch (e) {
            log('[AffiliationService] ❌ Error parsing message: $e');
          }
        },
        onError: (error) {
          log('[AffiliationService] ❌ WebSocket error: $error');
          if (!_messageController.isClosed) {
            _messageController.addError(error);
          }
        },
        onDone: () {
          log('[AffiliationService] 🔌 WebSocket connection closed');
        },
        cancelOnError: false,
      );
    } catch (e, stackTrace) {
      log('[AffiliationService] ❌ Error al conectar WebSocket: $e');
      log('[AffiliationService] Stack trace: $stackTrace');
      // No relanzamos para no crashear la app
    }
  }

  /// Cierra la conexión del WebSocket
  void closeWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Limpia recursos
  void dispose() {
    closeWebSocket();
    if (!_messageController.isClosed) {
      _messageController.close();
    }
  }
}
