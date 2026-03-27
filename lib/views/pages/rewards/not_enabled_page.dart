import 'package:flutter/material.dart';

class NotEnabledContent extends StatefulWidget {
  const NotEnabledContent({super.key});

  @override
  State<NotEnabledContent> createState() => _NotEnabledContentState();
}

class _NotEnabledContentState extends State<NotEnabledContent>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _floatController;

  late final Animation<double> _pulseAnim;
  late final Animation<double> _floatAnim;

  static const Color _green = Color(0xFF29FF5E);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Floating icon con glow
            AnimatedBuilder(
              animation: Listenable.merge([_pulseAnim, _floatAnim]),
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF111111),
                    border: Border.all(
                      color: _green.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withOpacity(0.28 * _pulseAnim.value),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_green, _green.withOpacity(0.55)],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.diamond_outlined,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Divider
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, _green.withOpacity(0.4)],
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_green.withOpacity(0.4), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Título
            const Text(
              'BENEFICIOS\nBLOQUEADOS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ThaleahFat',
                fontSize: 36,
                color: _green,
                height: 1.0,
                letterSpacing: 3,
                shadows: [
                  Shadow(color: Color(0x8029FF5E), blurRadius: 16),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Subtexto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withOpacity(0.2), width: 1),
                color: _green.withOpacity(0.05),
              ),
              child: const Text(
                'Seguí jugando para volver\na acceder a tus beneficios!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'ThaleahFat',
                  fontSize: 18,
                  color: Colors.white70,
                  height: 1.4,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status badge pulsante
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Opacity(
                opacity: 0.5 + 0.5 * _pulseAnim.value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.6 + 0.4 * _pulseAnim.value),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _green.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ACCESO TEMPORALMENTE SUSPENDIDO',
                      style: TextStyle(
                        fontFamily: 'ThaleahFat',
                        fontSize: 11,
                        color: _green.withOpacity(0.7),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
