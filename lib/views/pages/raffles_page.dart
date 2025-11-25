import 'package:flutter/material.dart';

class RafflesPage extends StatefulWidget {
  const RafflesPage({super.key});

  @override
  State<RafflesPage> createState() => _RafflesPageState();
}

class _RafflesPageState extends State<RafflesPage> {
  // Mock data de sorteos
  final List<Map<String, dynamic>> _raffles = [
    {
      'id': 1,
      'name': 'Gran Sorteo de Verano',
      'description':
          'Participá por un viaje para 2 personas a las playas más hermosas del caribe. Incluye hospedaje y actividades.',
      'startDate': '01/12/2025',
      'endDate': '31/12/2025',
      'prize': 'Viaje para 2 personas',
      'participants': 1250,
      'isActive': true,
    },
    {
      'id': 2,
      'name': 'Sorteo Tecnología Premium',
      'description':
          'Llevate el último smartphone del mercado más una tablet de última generación. No te lo pierdas!',
      'startDate': '15/11/2025',
      'endDate': '15/01/2026',
      'prize': 'Smartphone + Tablet',
      'participants': 890,
      'isActive': true,
    },
    {
      'id': 3,
      'name': 'Sorteo Fin de Año',
      'description':
          'Celebrá el año nuevo con estilo. Ganate una cena para 4 personas en el mejor restaurant de la ciudad.',
      'startDate': '20/12/2025',
      'endDate': '28/12/2025',
      'prize': 'Cena Premium para 4',
      'participants': 450,
      'isActive': true,
    },
  ];

  String _selectedFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Header con filtros
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.card_giftcard, color: primaryGreen, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Sorteos Activos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFilterChip('Todos', primaryGreen, isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip('Activos', primaryGreen, isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip(
                      'Finalizados',
                      primaryGreen,
                      isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lista de sorteos
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _raffles.length,
            itemBuilder: (context, index) {
              final raffle = _raffles[index];
              return _buildRaffleCard(
                context,
                raffle,
                primaryGreen,
                textColor,
                isDark,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, Color primaryGreen, bool isDark) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : primaryGreen.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRaffleCard(
    BuildContext context,
    Map<String, dynamic> raffle,
    Color primaryGreen,
    Color textColor,
    bool isDark,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _showRaffleDetails(context, raffle, primaryGreen, textColor);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryGreen.withOpacity(0.6),
                    primaryGreen.withOpacity(0.3),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.card_giftcard,
                      size: 80,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  if (raffle['isActive'])
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'ACTIVO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    raffle['name'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    raffle['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Premio
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryGreen.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events, color: primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            raffle['prize'],
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Información de fechas y participantes
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          Icons.calendar_today,
                          'Inicio: ${raffle['startDate']}',
                          textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          Icons.event,
                          'Fin: ${raffle['endDate']}',
                          textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoChip(
                    Icons.people,
                    '${raffle['participants']} participantes',
                    textColor,
                  ),
                  const SizedBox(height: 12),

                  // Botón de participar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Participando en: ${raffle['name']}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Participar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textColor.withOpacity(0.6)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showRaffleDetails(
    BuildContext context,
    Map<String, dynamic> raffle,
    Color primaryGreen,
    Color textColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        raffle['name'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        raffle['description'],
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Detalles del Sorteo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.emoji_events,
                        'Premio',
                        raffle['prize'],
                        textColor,
                      ),
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Fecha de inicio',
                        raffle['startDate'],
                        textColor,
                      ),
                      _buildDetailRow(
                        Icons.event,
                        'Fecha de fin',
                        raffle['endDate'],
                        textColor,
                      ),
                      _buildDetailRow(
                        Icons.people,
                        'Participantes',
                        '${raffle['participants']}',
                        textColor,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '¡Participaste en: ${raffle['name']}!',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirmar Participación'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor.withOpacity(0.6)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
