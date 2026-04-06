import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/raffle_model.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/raffle_service.dart';
import 'package:boombet_app/views/pages/admin/raffles/create_raffle.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RafflesManagementView extends StatefulWidget {
  const RafflesManagementView({super.key});

  @override
  State<RafflesManagementView> createState() => _RafflesManagementViewState();
}

class _RafflesManagementViewState extends State<RafflesManagementView> {
  static const int _pageSize = 5;
  final RaffleService _raffleService = RaffleService();

  bool _isLoading = true;
  String? _errorMessage;
  List<RaffleModel> _raffles = const [];
  Map<int, String> _casinoNamesById = const {};
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadCasinoNames();
    _loadRaffles();
  }

  Future<void> _loadCasinoNames() async {
    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/sorteos/casinos',
        includeAuth: true,
        cacheTtl: Duration.zero,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) return;

      final decoded = jsonDecode(response.body);
      List<dynamic> rawItems = const [];
      if (decoded is List) {
        rawItems = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        final content = decoded['content'];
        if (data is List) {
          rawItems = data;
        } else if (content is List) {
          rawItems = content;
        }
      }

      final parsed = <int, String>{};
      for (final item in rawItems) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final nombre = map['nombre']?.toString().trim() ?? '';
        if (nombre.isEmpty) continue;

        final idValue = map['id'];
        final parsedId = idValue is int ? idValue : int.tryParse('$idValue');
        if (parsedId == null) continue;

        parsed[parsedId] = nombre;
      }

      if (!mounted) return;
      setState(() => _casinoNamesById = parsed);
    } catch (_) {
      // fallback: mostramos el id si no se pudo cargar el catálogo
    }
  }

  Future<void> _loadRaffles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final raw = await _raffleService.fetchRaffles();
      if (!mounted) return;
      setState(() {
        _raffles = raw.map(RaffleModel.fromMap).toList(growable: false);
        _isLoading = false;
        _currentPage = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudieron cargar los sorteos.';
      });
    }
  }

  int get _totalPages {
    if (_raffles.isEmpty) return 0;
    return (_raffles.length / _pageSize).ceil();
  }

  List<RaffleModel> get _currentRaffles {
    if (_raffles.isEmpty) return const [];
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _raffles.length);
    return _raffles.sublist(start, end);
  }

  String _formatEndAt(String raw) {
    if (raw.trim().isEmpty) return '-';
    try {
      return DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  String _casinoLabel(int? casinoGralId) {
    if (casinoGralId == null) return 'Boombet';
    return _casinoNamesById[casinoGralId] ?? casinoGralId.toString();
  }

  DateTime? _parseDateTime(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleEdit(RaffleModel raffle) async {
    if (raffle.id == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppConstants.primaryGreen.withValues(alpha: 0.20),
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
          child: SingleChildScrollView(
            child: CreateRaffleSection(
              showHeader: false,
              raffleId: raffle.id,
              initialText: raffle.text,
              initialCasinoGralId: raffle.casinoGralId,
              initialEndAt: _parseDateTime(raffle.endAt),
              initialMediaUrl: raffle.mediaUrl,
              onCreated: () {
                Navigator.of(dialogContext).pop();
                _loadRaffles();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(RaffleModel raffle) async {
    if (raffle.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppConstants.errorRed.withValues(alpha: 0.30),
          ),
        ),
        title: const Text(
          'Eliminar sorteo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar este sorteo? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.primaryGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppConstants.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _raffleService.deleteRaffle(raffle.id!);
      await _loadRaffles();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Sorteo eliminado correctamente.',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppConstants.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el sorteo: $error',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: AppConstants.errorRed.withValues(alpha: 0.40),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppConstants.primaryGreen.withValues(alpha: 0.20),
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
          child: SingleChildScrollView(
            child: CreateRaffleSection(
              showHeader: false,
              onCreated: () {
                Navigator.of(dialogContext).pop();
                _loadRaffles();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
              // ── Botón crear ──────────────────────────────────────────────
              _RaffleCreateButton(
                onPressed: _openCreateDialog,
                label: 'Crear sorteo',
                icon: Icons.emoji_events_outlined,
              ),
              const SizedBox(height: 12),

              // ── Contenido ────────────────────────────────────────────────
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: green,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (_errorMessage != null)
                _ErrorState(message: _errorMessage!, onRetry: _loadRaffles)
              else if (_raffles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    border: Border.all(color: green.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: green.withValues(alpha: 0.55),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay sorteos activos para mostrar.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                ..._currentRaffles.map(
                  (raffle) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RaffleCard(
                      raffle: raffle,
                      casinoLabel: _casinoLabel(raffle.casinoGralId),
                      formatEndAt: _formatEndAt(raffle.endAt),
                      onEdit: () => _handleEdit(raffle),
                      onDelete: () => _handleDelete(raffle),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    border: Border.all(color: green.withValues(alpha: 0.12)),
                  ),
                  child: Center(
                    child: PaginationBar(
                      currentPage: _currentPage + 1,
                      canGoPrevious: _currentPage > 0,
                      canGoNext: _currentPage < (_totalPages - 1),
                      onPrev: () {
                        if (_currentPage <= 0) return;
                        setState(() => _currentPage -= 1);
                      },
                      onNext: () {
                        if (_currentPage >= (_totalPages - 1)) return;
                        setState(() => _currentPage += 1);
                      },
                      primaryColor: green,
                      textColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
    return SingleChildScrollView(child: content);
  }
}

// ── Card ───────────────────────────────────────────────────────────────────────

class _RaffleCard extends StatelessWidget {
  final RaffleModel raffle;
  final String casinoLabel;
  final String formatEndAt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RaffleCard({
    required this.raffle,
    required this.casinoLabel,
    required this.formatEndAt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: green.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Imagen ─────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppConstants.borderRadius - 1),
              bottomLeft: Radius.circular(AppConstants.borderRadius - 1),
            ),
            child: SizedBox(
              width: 84,
              height: 148,
              child: raffle.mediaUrl.isEmpty
                  ? Container(
                      color: green.withValues(alpha: 0.06),
                      child: Center(
                        child: Icon(
                          Icons.emoji_events_outlined,
                          color: green.withValues(alpha: 0.35),
                          size: 28,
                        ),
                      ),
                    )
                  : Image.network(
                      raffle.mediaUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: green.withValues(alpha: 0.06),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: green,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: green.withValues(alpha: 0.06),
                        child: Center(
                          child: Icon(
                            Icons.emoji_events_outlined,
                            color: green.withValues(alpha: 0.35),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // ── Info ───────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    raffle.text.isEmpty ? '—' : raffle.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RaffleInfoChip(
                    icon: Icons.casino_outlined,
                    label: casinoLabel,
                  ),
                  const SizedBox(height: 5),
                  _RaffleInfoChip(
                    icon: Icons.schedule_rounded,
                    label: 'Cierre: $formatEndAt',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _RaffleActionButton(
                        label: 'Editar',
                        icon: Icons.edit_outlined,
                        color: green,
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 8),
                      _RaffleActionButton(
                        label: 'Eliminar',
                        icon: Icons.delete_outline_rounded,
                        color: AppConstants.errorRed,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado de error ────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: AppConstants.errorRed.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppConstants.errorRed,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.errorRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.errorRed.withValues(alpha: 0.30),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: AppConstants.errorRed,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Reintentar',
                      style: TextStyle(
                        color: AppConstants.errorRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón crear ────────────────────────────────────────────────────────────────

class _RaffleCreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _RaffleCreateButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        splashColor: green.withValues(alpha: 0.08),
        highlightColor: green.withValues(alpha: 0.04),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: green.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: green.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: green, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add_rounded, color: green, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chip de info ───────────────────────────────────────────────────────────────

class _RaffleInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RaffleInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: AppConstants.primaryGreen.withValues(alpha: 0.60),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.50),
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Botones de acción ──────────────────────────────────────────────────────────

class _RaffleActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RaffleActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withValues(alpha: 0.22),
        highlightColor: color.withValues(alpha: 0.10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.65), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 8,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
