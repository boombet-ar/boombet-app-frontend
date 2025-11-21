import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:flutter/material.dart';

class PendingAfiliacionPage extends StatefulWidget {
  const PendingAfiliacionPage({super.key});

  @override
  State<PendingAfiliacionPage> createState() => _PendingAfiliacionPageState();
}

class _PendingAfiliacionPageState extends State<PendingAfiliacionPage> {
  @override
  void initState() {
    super.initState();
    // Navegar a HomePage después de 30 segundos
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final greenColor = theme.colorScheme.primary;
    final appBarBg = isDark ? Colors.black38 : const Color(0xFFE8E8E8);
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onBackground;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: appBarBg,
          leading: null,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: isLightModeNotifier,
                  builder: (context, isLightMode, child) {
                    return Icon(
                      isLightMode ? Icons.dark_mode : Icons.light_mode,
                      color: greenColor,
                    );
                  },
                ),
                tooltip: 'Cambiar tema',
                onPressed: () {
                  isLightModeNotifier.value = !isLightModeNotifier.value;
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: bgColor,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo de BoomBet
                Image.asset('assets/images/boombetlogo.png', width: 200),

                const SizedBox(height: 20),

                // Texto llamativo
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        greenColor.withOpacity(0.2),
                        greenColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: greenColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '🎰 El primer portal de casinos legales y apuestas deportivas online 🎲',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: greenColor,
                      letterSpacing: 0.2,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // Icono de espera/proceso con animación
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: greenColor.withOpacity(0.1),
                    border: Border.all(
                      color: greenColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.hourglass_empty,
                    size: 48,
                    color: greenColor,
                  ),
                ),

                const SizedBox(height: 20),

                // Título principal
                Text(
                  '¡Estamos procesando tu solicitud!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Texto descriptivo
                Text(
                  'Tu afiliación está siendo verificada',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Barra de carga con texto
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: greenColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 18, color: greenColor),
                          const SizedBox(width: 8),
                          Text(
                            'Procesando afiliación',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Barra de progreso indeterminada
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          backgroundColor: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE0E0E0),
                          valueColor: AlwaysStoppedAnimation<Color>(greenColor),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Por favor no cierres la aplicación',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
