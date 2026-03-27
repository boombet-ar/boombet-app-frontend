import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/stands_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StandRoulettesPage extends StatefulWidget {
  const StandRoulettesPage({super.key});

  @override
  State<StandRoulettesPage> createState() => _StandRoulettesPageState();
}

class _StandRoulettesPageState extends State<StandRoulettesPage> {
  final StandsService _service = StandsService();
  List<TidModel> _roulettes = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoulettes();
  }

  Future<void> _loadRoulettes() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final roulettes = await _service.fetchStandRoulettes();
      if (!mounted) return;
      setState(() {
        _roulettes = roulettes;
        _isLoading = false;
      });
    } catch (e, stack) {
      log('[StandRoulettesPage] load error: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar las ruletas: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/stand-tools');
      },
      child: Scaffold(
        backgroundColor: AppConstants.darkBg,
        body: ListView(
          padding: EdgeInsets.zero,
        children: [
          SectionHeaderWidget(
            title: 'Ruletas del Stand',
            subtitle: 'TIDs configurados para la entrega de premios.',
            icon: Icons.casino_outlined,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: _buildBody(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    const green = AppConstants.primaryGreen;

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppConstants.darkAccent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: AppConstants.errorRed.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No se pudieron cargar las ruletas.',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _loadRoulettes,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      );
    }

    if (_roulettes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppConstants.darkAccent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.inbox_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No hay ruletas configuradas para este stand.',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadRoulettes,
              child: const Text('Refrescar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ..._roulettes.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppConstants.darkAccent,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: green.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.casino_outlined,
                      color: AppConstants.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      r.tid.isNotEmpty ? r.tid : 'Sin TID',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppConstants.darkAccent,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_roulettes.length} ruleta${_roulettes.length == 1 ? '' : 's'} configurada${_roulettes.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
