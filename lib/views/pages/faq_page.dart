import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  bool _isLoggedIn = false;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final token = await TokenService.getToken();
    final hasSession = await TokenService.hasActiveSession();

    print('DEBUG FAQ - Token: ${token != null ? "exists" : "null"}');
    print('DEBUG FAQ - Has Active Session: $hasSession');

    if (mounted) {
      setState(() {
        _isLoggedIn = hasSession;
      });
      print('DEBUG FAQ - _isLoggedIn set to: $_isLoggedIn');
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    // Aquí iría la lógica para enviar el mensaje al backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mensaje enviado correctamente'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE0E0E0) : Colors.black87;
    final greenColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: const MainAppBar(
        showBackButton: true,
        showLogo: true,
        showFaqButton: false,
      ),
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ResponsiveWrapper(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Título
              Text(
                'Ayuda',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),

              // Secciones de FAQ
              _buildFaqSection(
                context,
                icon: Icons.home,
                title: 'Plataforma',
                cardColor: cardColor,
                textColor: textColor,
              ),
              const SizedBox(height: 12),
              _buildFaqSection(
                context,
                icon: Icons.local_offer,
                title: 'Descuentos',
                cardColor: cardColor,
                textColor: textColor,
              ),
              const SizedBox(height: 12),
              _buildFaqSection(
                context,
                icon: Icons.shield,
                title: 'Puntos',
                cardColor: cardColor,
                textColor: textColor,
              ),
              const SizedBox(height: 12),
              _buildFaqSection(
                context,
                icon: Icons.article,
                title: 'Actividades',
                cardColor: cardColor,
                textColor: textColor,
              ),
              const SizedBox(height: 12),
              _buildFaqSection(
                context,
                icon: Icons.thumb_up,
                title: 'Sorteos',
                cardColor: cardColor,
                textColor: textColor,
              ),
              const SizedBox(height: 32),

              // Sección de comentarios/sugerencias
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Tienes sugerencias o comentarios?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nos gustaría saber qué tipo de beneficios quieres que agreguemos a la plataforma o alguna sugerencia para mejorarla.\nPuedes completar el formulario o enviarnos un mail a:',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ventas@bonda.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Área de mensaje - bloqueada si no está logueado
                    if (!_isLoggedIn) ...[
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade400,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock,
                              size: 40,
                              color: textColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Inicia sesión para completar el formulario',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: greenColor,
                                  foregroundColor: isDark
                                      ? Colors.black
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                  shadowColor: greenColor.withOpacity(0.4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.login, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Formulario de mensaje
                      TextField(
                        controller: _messageController,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        enableInteractiveSelection: true,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Escribe tu mensaje aquí...',
                          hintStyle: TextStyle(
                            color: textColor.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: greenColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Enviar mensaje',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: textColor.withOpacity(0.5)),
        onTap: () {
          // Aquí iría la navegación a la página de detalle de cada sección
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Abriendo sección: $title'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
