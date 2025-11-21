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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
              vertical: 40.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo de BoomBet
                Image.asset('assets/images/boombetlogo.png', width: 250),

                const SizedBox(height: 40),

                // Texto llamativo
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: greenColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '🎰 El primer portal de casinos legales y apuestas deportivas online 🎲',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: greenColor,
                      letterSpacing: 0.5,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 60),

                // Icono de espera/proceso
                Icon(Icons.hourglass_empty, size: 80, color: greenColor),

                const SizedBox(height: 40),

                // Título principal
                Text(
                  '¡Estamos procesando tu solicitud!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Texto descriptivo
                Text(
                  'Tu afiliación está siendo verificada por nuestro equipo.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Imagen placeholder
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: greenColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 60,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Imagen Placeholder',
                          style: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black26,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Texto informativo adicional
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Este proceso puede tardar unos minutos. Por favor no cierres la aplicación.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 60),

                // Barra de carga con texto
                Column(
                  children: [
                    Text(
                      'Te estamos afiliando, espere unos minutos',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Barra de progreso indeterminada
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          backgroundColor: isDark
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFE8E8E8),
                          valueColor: AlwaysStoppedAnimation<Color>(greenColor),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
