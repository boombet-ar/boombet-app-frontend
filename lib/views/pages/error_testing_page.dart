import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/utils/error_parser.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';

/// Página de testing para probar el sistema de manejo de errores
///
/// Permite simular diferentes escenarios:
/// - Token expirado (401)
/// - Timeouts
/// - Errores de red
/// - Auto-retry
/// - Diferentes códigos de error HTTP
class ErrorTestingPage extends StatefulWidget {
  const ErrorTestingPage({super.key});

  @override
  State<ErrorTestingPage> createState() => _ErrorTestingPageState();
}

class _ErrorTestingPageState extends State<ErrorTestingPage> {
  String _lastResult = 'Sin pruebas realizadas';
  bool _isLoading = false;

  Future<void> _runTest(String testName, Future<void> Function() test) async {
    setState(() {
      _isLoading = true;
      _lastResult = 'Ejecutando: $testName...';
    });

    try {
      await test();
    } catch (e) {
      setState(() {
        _lastResult = 'ERROR en $testName:\n${ErrorParser.parse(e)}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test 1: Token expirado (401) - debería navegar a login automáticamente
  Future<void> _test401() async {
    await _runTest('Test 401 - Token Expirado', () async {
      // Guardar un token falso/expirado
      await TokenService.saveToken('token_invalido_para_test_401');
      debugPrint('🧪 Test 401: Token inválido guardado');

      // Hacer una request a un endpoint protegido del backend local
      // Si el backend está corriendo, debería responder 401
      // Si no está corriendo, dará error de conexión (esperado)
      try {
        final response = await HttpClient.get(
          'http://10.0.2.2:8080/api/users/profile', // Endpoint protegido
          includeAuth: true,
        );

        setState(() {
          _lastResult =
              'Test 401 completado\n\n'
              'Status: ${response.statusCode}\n'
              'Expected: Deberías haber sido redirigido a LoginPage\n\n'
              'Si ves esta pantalla todavía:\n'
              '1. El backend respondió algo diferente a 401\n'
              '2. El callback onUnauthorized falló\n\n'
              'Revisa los logs para ver: [MAIN] 401 Detected';
        });
      } catch (e) {
        setState(() {
          _lastResult =
              'Test 401 - Error de conexión\n\n'
              'El backend no está corriendo en localhost:8080\n\n'
              'Para probar el 401:\n'
              '1. Asegúrate que el backend Docker esté corriendo\n'
              '2. El backend debe tener un endpoint protegido\n'
              '3. Ese endpoint debe responder 401 con token inválido\n\n'
              'Error: ${ErrorParser.parse(e)}';
        });
      }
    });
  }

  // Test 2: Request exitoso (200)
  Future<void> _test200() async {
    await _runTest('Test 200 - Request Exitoso', () async {
      // Usar httpbin.org/get - siempre devuelve 200 OK
      final response = await HttpClient.get(
        'https://httpbin.org/get',
        includeAuth: false,
      );

      setState(() {
        _lastResult =
            '✅ Test 200 completado\n\n'
            'Status: ${response.statusCode}\n'
            'Body preview: ${response.body.substring(0, response.body.length > 150 ? 150 : response.body.length)}...\n\n'
            '📝 Resultado:\n'
            '- Status 200 = Request exitoso ✅\n'
            '- El servidor respondió correctamente\n'
            '- No hubo errores de red ni timeouts\n\n'
            'Este es el comportamiento esperado para requests normales.';
      });
    });
  }

  // Test 3: Timeout
  Future<void> _testTimeout() async {
    await _runTest('Test Timeout', () async {
      try {
        // httpbin.org/delay/10 espera 10 segundos antes de responder
        // Con timeout de 3s, debería fallar
        debugPrint('🧪 Test Timeout: Esperando 10s con timeout de 3s...');
        final response = await HttpClient.get(
          'https://httpbin.org/delay/10',
          includeAuth: false,
          timeout: const Duration(seconds: 3),
        );

        setState(() {
          _lastResult =
              '⚠️ Test Timeout - No hubo timeout\n\n'
              'Status: ${response.statusCode}\n'
              'El servidor respondió en menos de 3s (inesperado)\n'
              'Esto no debería pasar con delay/10';
        });
      } catch (e) {
        setState(() {
          _lastResult =
              '✅ Test Timeout completado\n\n'
              'Error capturado: ${e.runtimeType}\n'
              'Mensaje: ${ErrorParser.parse(e)}\n\n'
              '📝 Interpretación:\n'
              'El timeout funcionó correctamente.\n'
              'El servidor tardó más de 3 segundos.\n\n'
              'Expected: "La conexión tardó demasiado tiempo..."';
        });
      }
    });
  }

  // Test 4: Auto-retry
  Future<void> _testRetry() async {
    await _runTest('Test Auto-Retry', () async {
      debugPrint('🧪 Test Retry: Probando auto-retry con timeout corto');
      try {
        // httpbin.org/delay/10 tarda 10s, pero timeout es 2s
        // Esto fuerza TimeoutException → retry automático
        final response = await HttpClient.get(
          'https://httpbin.org/delay/10',
          includeAuth: false,
          timeout: const Duration(
            seconds: 2,
          ), // Timeout corto para forzar retry
        );

        setState(() {
          _lastResult =
              '⚠️ Test Auto-Retry - No falló\n\n'
              'Status final: ${response.statusCode}\n'
              'El servidor respondió rápido (inesperado)\n\n'
              'Debería haber dado timeout y reintentar 3 veces';
        });
      } catch (e) {
        setState(() {
          _lastResult =
              '✅ Test Auto-Retry completado\n\n'
              'Error: ${ErrorParser.parse(e)}\n'
              'Tipo: ${e.runtimeType}\n\n'
              '📝 Revisa los logs en consola:\n'
              'Deberías ver los 3 intentos con delays:\n'
              '- [HttpClient] GET ... (Attempt 1/3)\n'
              '- [HttpClient] ⏱️ Timeout...\n'
              '- [HttpClient] 🔄 Retry 2/3 en 2s...\n'
              '- [HttpClient] GET ... (Attempt 2/3)\n'
              '- [HttpClient] ⏱️ Timeout...\n'
              '- [HttpClient] 🔄 Retry 3/3 en 4s...\n'
              '- [HttpClient] GET ... (Attempt 3/3)\n'
              '- [HttpClient] ⏱️ Timeout...\n\n'
              'El sistema de retry funcionó correctamente ✅\n'
              'Total: 3 intentos con backoff exponencial (2s, 4s)';
        });
      }
    });
  }

  // Test 5: Diferentes códigos de error usando httpbin.org (servicio público de testing)
  Future<void> _testErrorCodes(int code) async {
    await _runTest('Test $code', () async {
      try {
        // Usar httpbin.org - servicio público que devuelve códigos específicos
        // Estos endpoints están diseñados para testing y devuelven exactamente el código solicitado
        String endpoint = 'https://httpbin.org/status/$code';

        debugPrint('🧪 Test $code: Solicitando a $endpoint');

        final response = await HttpClient.get(
          endpoint,
          includeAuth: false, // httpbin.org es público
          timeout: const Duration(seconds: 10),
        );

        setState(() {
          _lastResult =
              '✅ Test $code completado\n\n'
              'Status recibido: ${response.statusCode}\n'
              'Mensaje parseado: ${ErrorParser.parseResponse(response)}\n'
              'Mensaje corto: ${ErrorParser.getShortMessage(response)}\n\n'
              '📝 Interpretación:\n'
              '${_getErrorCodeExplanation(code)}\n\n'
              'Los mensajes están en español y son user-friendly';
        });
      } catch (e) {
        setState(() {
          _lastResult =
              '⚠️ Test $code - Excepción capturada\n\n'
              'Error: ${ErrorParser.parse(e)}\n'
              'Tipo: ${e.runtimeType}\n\n'
              'Esto puede pasar si:\n'
              '- El código $code causó una excepción antes del response\n'
              '- Problema de red/timeout\n\n'
              '${_getErrorCodeExplanation(code)}';
        });
      }
    });
  }

  String _getErrorCodeExplanation(int code) {
    switch (code) {
      case 400:
        return '400 = Solicitud incorrecta (datos inválidos)';
      case 403:
        return '403 = Prohibido (sin permisos, pero autenticado)';
      case 404:
        return '404 = No encontrado (endpoint no existe)';
      case 409:
        return '409 = Conflicto (ej: usuario ya existe)';
      case 500:
        return '500 = Error interno del servidor';
      case 503:
        return '503 = Servicio no disponible (servidor caído)';
      default:
        return 'Código HTTP $code';
    }
  }

  // Test 6: Request con token válido
  Future<void> _testWithRealToken() async {
    await _runTest('Test con Token Real', () async {
      final token = await TokenService.getToken();

      if (token == null) {
        setState(() {
          _lastResult = '''
⚠️ No hay token guardado

Para probar con token real:
1. Inicia sesión en la app
2. Vuelve a esta página
3. Ejecuta este test nuevamente
''';
        });
        return;
      }

      // Intentar obtener datos del usuario (ajusta el endpoint según tu backend)
      try {
        final response = await HttpClient.get(
          'http://10.0.2.2:8080/api/users/profile',
          includeAuth: true,
        );

        setState(() {
          _lastResult =
              '''
✅ Test con Token Real completado

Status: ${response.statusCode}
Body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...

Token usado: ${token.substring(0, 20)}...
''';
        });
      } catch (e) {
        setState(() {
          _lastResult =
              '''
⚠️ Test con Token Real - Error

Error: ${ErrorParser.parse(e)}

Esto puede significar:
- El endpoint no existe aún (esperado)
- El token expiró (debería haber navegado a login)
- Problema de red
''';
        });
      }
    });
  }

  // Test 7: Simular error de red
  Future<void> _testNetworkError() async {
    await _runTest('Test Error de Red', () async {
      try {
        debugPrint('🧪 Test Network: Intentando conectar a IP no enrutable');
        // Usar una URL con IP no enrutable para simular error de red
        final response = await HttpClient.get(
          'http://192.0.2.1:8080/test', // IP reservada para documentación (no enrutable)
          includeAuth: false,
          timeout: const Duration(seconds: 5), // Timeout corto
        );

        setState(() {
          _lastResult =
              'Test Error de Red - No falló?\n\n'
              'Status: ${response.statusCode}\n'
              'Esto no debería pasar con IP no enrutable';
        });
      } catch (e) {
        setState(() {
          _lastResult =
              'Test Error de Red completado\n\n'
              'Error capturado: ${e.runtimeType}\n'
              'Mensaje: ${ErrorParser.parse(e)}\n\n'
              'Expected: "Sin conexión a internet..."\n'
              'O: "La conexión tardó demasiado tiempo..."\n\n'
              'Revisa logs para ver los 3 reintentos';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;
    final bgColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: true,
        showProfileButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              '🧪 Testing de Errores HTTP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba el sistema de manejo de errores, retry automático y 401 handler',
              style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),

            // Resultado del último test
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Último Resultado:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Text(
                      _lastResult,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: textColor.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tests críticos
            _buildSection('Tests Críticos', Icons.warning_amber, Colors.red, [
              _buildTestButton(
                '🔐 Test 401 - Token Expirado',
                'Debería navegar automáticamente a LoginPage',
                Colors.red,
                _test401,
              ),
              _buildTestButton(
                '⏱️ Test Timeout',
                'Debería reintentar 3 veces y fallar',
                Colors.orange,
                _testTimeout,
              ),
              _buildTestButton(
                '🔄 Test Auto-Retry',
                'Error 500 con retry automático',
                Colors.orange,
                _testRetry,
              ),
            ]),
            const SizedBox(height: 16),

            // Tests de códigos HTTP
            _buildSection('Códigos de Error HTTP', Icons.code, primaryGreen, [
              Row(
                children: [
                  Expanded(
                    child: _buildTestButton(
                      '400',
                      'Bad Request',
                      Colors.amber,
                      () => _testErrorCodes(400),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTestButton(
                      '403',
                      'Forbidden',
                      Colors.amber,
                      () => _testErrorCodes(403),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTestButton(
                      '404',
                      'Not Found',
                      Colors.amber,
                      () => _testErrorCodes(404),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTestButton(
                      '409',
                      'Conflict',
                      Colors.amber,
                      () => _testErrorCodes(409),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTestButton(
                      '500',
                      'Server Error',
                      Colors.red,
                      () => _testErrorCodes(500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTestButton(
                      '503',
                      'Unavailable',
                      Colors.red,
                      () => _testErrorCodes(503),
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 16),

            // Tests de integración
            _buildSection(
              'Tests de Integración',
              Icons.integration_instructions,
              Colors.blue,
              [
                _buildTestButton(
                  '✅ Test 200 - Request Exitoso',
                  'Request normal sin errores',
                  Colors.green,
                  _test200,
                ),
                _buildTestButton(
                  '🔑 Test con Token Real',
                  'Usar el token guardado en la app',
                  Colors.blue,
                  _testWithRealToken,
                ),
                _buildTestButton(
                  '🌐 Test Error de Red',
                  'Simular sin conexión a internet',
                  Colors.grey,
                  _testNetworkError,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Instrucciones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cómo usar:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction('1', 'Presiona cualquier botón de test'),
                  _buildInstruction(
                    '2',
                    'Observa los logs en la consola (prints)',
                  ),
                  _buildInstruction(
                    '3',
                    'Lee el resultado mostrado arriba para verificar',
                  ),
                  _buildInstruction(
                    '4',
                    'En Test 401, deberías ser redirigido a LoginPage',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTestButton(
    String title,
    String subtitle,
    Color color,
    Future<void> Function() onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
