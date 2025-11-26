import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AffiliationService {
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream para escuchar mensajes del WebSocket
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Genera un WebSocket URL único para este usuario
  String _generateWebSocketUrl() {
    // Obtener la URL base y convertirla a WebSocket
    final baseUrl = ApiConfig.baseUrl;
    final wsUrl = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    // Generar un ID único basado en timestamp
    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    return '$wsUrl/affiliation/$uniqueId';
  }

  /// Conecta al WebSocket usando una URL específica
  /// Este método se usa cuando ya tenemos el wsUrl del backend
  Future<void> connectToWebSocket({
    required String wsUrl,
    String token = '',
  }) async {
    print('[AffiliationService] Conectando a WebSocket: $wsUrl');

    try {
      // Cerrar conexión previa si existe
      closeWebSocket();

      // Parsear y validar la URI
      final uri = Uri.parse(wsUrl);
      print('[AffiliationService] URI parseada: $uri');
      print(
        '[AffiliationService] Scheme: ${uri.scheme}, Host: ${uri.host}, Port: ${uri.port}, Path: ${uri.path}',
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
      print('[AffiliationService] ✅ WebSocket conectado exitosamente');

      // Escuchar mensajes del WebSocket
      _wsSubscription = _channel!.stream.listen(
        (message) {
          try {
            print('[AffiliationService] 📩 Mensaje recibido: $message');
            if (message is String) {
              final data = jsonDecode(message);
              if (!_messageController.isClosed) {
                _messageController.add(data);
              }
            }
          } catch (e) {
            print('[AffiliationService] ❌ Error parsing message: $e');
          }
        },
        onError: (error) {
          print('[AffiliationService] ❌ WebSocket error: $error');
          if (!_messageController.isClosed) {
            _messageController.addError(error);
          }
        },
        onDone: () {
          print('[AffiliationService] 🔌 WebSocket connection closed');
        },
        cancelOnError: false,
      );
    } catch (e, stackTrace) {
      print('[AffiliationService] ❌ Error al conectar WebSocket: $e');
      print('[AffiliationService] Stack trace: $stackTrace');
      // No relanzamos el error para que no crashee la app
      // El flujo puede continuar sin WebSocket activo
    }
  }

  /// Inicia el proceso de afiliación: abre WebSocket y envía datos al backend
  Future<Map<String, dynamic>> startAffiliation({
    required PlayerData playerData,
    String token = '',
    Map<String, dynamic>? completeData,
  }) async {
    print('[AffiliationService] Iniciando proceso de afiliación...');

    try {
      // 1. Generar URL del WebSocket
      final wsUrl = _generateWebSocketUrl();
      print('[AffiliationService] WebSocket URL generada: $wsUrl');

      // 2. Preparar datos del jugador
      final playerDataJson =
          completeData ??
          {
            'nombre': playerData.nombre,
            'apellido': playerData.apellido,
            'email': playerData.correoElectronico,
            'telefono': playerData.telefono,
            'genero': playerData.sexo,
            'fecha_nacimiento': playerData.fechaNacimiento,
            'dni': playerData.dni,
            'cuit': playerData.cuil,
            'est_civil': playerData.estadoCivil,
            'calle': playerData.calle,
            'numCalle': playerData.numCalle,
            'provincia': playerData.provincia,
            'ciudad': playerData.localidad,
            'cp': playerData.cp?.toString() ?? '',
            'user': '',
            'password': '',
          };

      // 3. Preparar payload para enviar al backend
      final payload = {'playerData': playerDataJson, 'websocketlink': wsUrl};

      // 4. Enviar al endpoint de startaffiliate CON TIMEOUT
      final url = Uri.parse('${ApiConfig.baseUrl}/users/startAffiliate');
      print('[AffiliationService] Enviando POST a: $url');
      print('[AffiliationService] Payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('[AffiliationService] ⚠️ TIMEOUT después de 15 segundos');
              return http.Response('Request timeout', 408);
            },
          );

      print('[AffiliationService] Response Status: ${response.statusCode}');
      print('[AffiliationService] Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[AffiliationService] ✅ Afiliación iniciada exitosamente');

        // 5. Abrir conexión WebSocket DESPUÉS del POST exitoso
        try {
          print('[AffiliationService] Intentando conectar WebSocket...');
          _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
          print('[AffiliationService] WebSocket conectado exitosamente');

          // Escuchar mensajes del WebSocket
          _wsSubscription = _channel!.stream.listen(
            (message) {
              try {
                if (message is String) {
                  final data = jsonDecode(message);
                  if (!_messageController.isClosed) {
                    _messageController.add(data);
                  }
                }
              } catch (e) {
                print(
                  '[AffiliationService] Error parsing WebSocket message: $e',
                );
              }
            },
            onError: (error) {
              print('[AffiliationService] WebSocket error: $error');
              if (!_messageController.isClosed) {
                _messageController.addError(error);
              }
            },
            onDone: () {
              print('[AffiliationService] WebSocket connection closed');
            },
            cancelOnError: false,
          );
        } catch (e) {
          print('[AffiliationService] Error opening WebSocket: $e');
        }

        return {
          'success': true,
          'message': 'Afiliación iniciada correctamente',
          'wsUrl': wsUrl,
        };
      } else {
        print('[AffiliationService] ❌ Error en respuesta del servidor');
        return {
          'success': false,
          'message':
              'Error al iniciar afiliación (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e, stackTrace) {
      print('[AffiliationService] ❌ EXCEPCIÓN CAPTURADA: $e');
      print('[AffiliationService] Stack trace: $stackTrace');
      closeWebSocket(); // Cerrar WS en caso de error
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Cierra la conexión del WebSocket
  void closeWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Limpia los recursos
  void dispose() {
    closeWebSocket();
    if (!_messageController.isClosed) {
      _messageController.close();
    }
  }
}
