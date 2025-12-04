import 'package:flutter/material.dart';

class _RaffleData {
  final String id;
  final String titulo;
  final String descripcion;
  final IconData icono;
  final String premio;
  final int participantes;
  final int minutosRestantes;

  _RaffleData({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.premio,
    required this.participantes,
    required this.minutosRestantes,
  });
}

class RafflesPage extends StatefulWidget {
  const RafflesPage({super.key});

  @override
  State<RafflesPage> createState() => _RafflesPageState();
}

class _RafflesPageState extends State<RafflesPage> {
  Future<void> _refreshRaffles() async {
    // Simular carga de datos desde el servidor
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Sorteos actualizados!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mock data para sorteos
    final sorteos = [
      _RaffleData(
        id: '1',
        titulo: 'iPhone 15 Pro Max',
        descripcion: 'Último modelo de Apple con cámara de 48MP',
        icono: Icons.phone_iphone,
        premio: '\$2,500',
        participantes: 1245,
        minutosRestantes: 1440,
      ),
      _RaffleData(
        id: '2',
        titulo: 'PlayStation 5',
        descripcion: 'Consola de última generación con juegos',
        icono: Icons.sports_esports,
        premio: '\$800',
        participantes: 892,
        minutosRestantes: 720,
      ),
      _RaffleData(
        id: '3',
        titulo: 'Viaje a Miami',
        descripcion: 'Tour de 5 días todo incluido en Miami',
        icono: Icons.flight,
        premio: '\$5,000',
        participantes: 2341,
        minutosRestantes: 2880,
      ),
      _RaffleData(
        id: '4',
        titulo: 'Smart Watch Ultra',
        descripcion: 'Reloj inteligente con GPS y resistencia al agua',
        icono: Icons.watch,
        premio: '\$600',
        participantes: 567,
        minutosRestantes: 360,
      ),
    ];

    return RefreshIndicator(
      onRefresh: _refreshRaffles,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.purple.shade400, Colors.pink.shade400],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sorteos Activos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${sorteos.length} premios esperándote',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Listado de sorteos
              ...sorteos.asMap().entries.map((entry) {
                final index = entry.key;
                final sorteo = entry.value;
                final horas = sorteo.minutosRestantes ~/ 60;
                final minutos = sorteo.minutosRestantes % 60;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < sorteos.length - 1 ? 16 : 0,
                  ),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.grey.shade50],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado con icono y título
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  sorteo.icono,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sorteo.titulo,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sorteo.descripcion,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Información: Premio
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.amber.shade300,
                                  Colors.orange.shade300,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              'Premio: ${sorteo.premio}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Fila con participantes y tiempo restante
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${sorteo.participantes}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'participantes',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 18,
                                      color: Colors.red.shade600,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      horas > 0
                                          ? '${horas}h ${minutos}m'
                                          : '${minutos}m',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'restante',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Botón de participar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '¡Ya participas en ${sorteo.titulo}!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Participar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
