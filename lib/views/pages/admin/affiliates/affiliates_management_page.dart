import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/afiliador_model.dart';
import 'package:boombet_app/services/affiliates_service.dart';
import 'package:boombet_app/views/pages/admin/affiliates/create_affiliate.dart';
import 'package:boombet_app/views/pages/admin/affiliates/affiliates_management_view.dart';
import 'package:boombet_app/widgets/appbar_widget.dart' show MainAppBar;
import 'package:flutter/material.dart';

class AffiliatesManagementPage extends StatefulWidget {
  const AffiliatesManagementPage({super.key});

  @override
  State<AffiliatesManagementPage> createState() =>
      _AffiliatesManagementPageState();
}

class _AffiliatesManagementPageState extends State<AffiliatesManagementPage> {
  final AfiliadoresService _afiliadoresService = AfiliadoresService();
  bool _isLoadingAffiliators = false;
  String? _affiliatorsError;
  List<AfiliadorModel> _affiliators = [];
  int _affiliatorsPage = 0;
  int _affiliatorsTotalPages = 0;
  int _affiliatorsTotalElements = 0;
  int _affiliatorsPageSize = 10;
  bool _affiliatorsFirst = true;
  bool _affiliatorsLast = true;
  bool _affiliatorsLoaded = false;
  final Set<int> _affiliatorsUpdating = {};
  final Set<int> _affiliatorsDeleting = {};

  @override
  void initState() {
    super.initState();
    _loadAffiliators();
  }

  Future<void> _loadAffiliators({int page = 0, bool force = false}) async {
    if (_isLoadingAffiliators) return;
    if (_affiliatorsLoaded && !force && page == _affiliatorsPage) return;

    setState(() {
      _isLoadingAffiliators = true;
      _affiliatorsError = null;
    });

    try {
      final pageData = await _afiliadoresService.fetchAfiliadores(
        page: page,
        size: 10,
      );

      if (!mounted) return;
      setState(() {
        _affiliators = pageData.content;
        _affiliatorsPage = pageData.number;
        _affiliatorsTotalPages = pageData.totalPages;
        _affiliatorsTotalElements = pageData.totalElements;
        _affiliatorsPageSize = pageData.size;
        _affiliatorsFirst = pageData.first;
        _affiliatorsLast = pageData.last;
        _affiliatorsLoaded = true;
        _isLoadingAffiliators = false;
      });
    } catch (e, stack) {
      log('[AffiliatesManagement] load error: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _affiliatorsError = 'Error al cargar afiliadores: $e';
        _isLoadingAffiliators = false;
      });
    }
  }

  void _replaceAffiliatorInList(AfiliadorModel updated) {
    _affiliators = _affiliators
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
  }

  Future<void> _toggleAffiliatorActive(
    AfiliadorModel affiliator,
    bool isActive,
  ) async {
    if (_affiliatorsUpdating.contains(affiliator.id)) return;

    setState(() {
      _affiliatorsUpdating.add(affiliator.id);
      _replaceAffiliatorInList(
        AfiliadorModel(
          id: affiliator.id,
          nombre: affiliator.nombre,
          tokenAfiliador: affiliator.tokenAfiliador,
          tipoAfiliador: affiliator.tipoAfiliador,
          cantAfiliaciones: affiliator.cantAfiliaciones,
          activo: isActive,
          email: affiliator.email,
          dni: affiliator.dni,
          telefono: affiliator.telefono,
        ),
      );
    });

    try {
      final updated = await _afiliadoresService.toggleAfiliadorActivo(
        id: affiliator.id,
      );
      if (!mounted) return;
      setState(() {
        _replaceAffiliatorInList(updated);
        _affiliatorsUpdating.remove(affiliator.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _replaceAffiliatorInList(affiliator);
        _affiliatorsUpdating.remove(affiliator.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudo actualizar el estado del afiliador.',
            style: TextStyle(color: Colors.white),
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

  Future<void> _deleteAffiliator(AfiliadorModel affiliator) async {
    if (_affiliatorsDeleting.contains(affiliator.id)) return;

    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppConstants.errorRed.withValues(alpha: 0.30),
          ),
        ),
        title: const Text(
          'Eliminar afiliador',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar a ${affiliator.nombre}? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar', style: TextStyle(color: green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppConstants.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _affiliatorsDeleting.add(affiliator.id));

    try {
      await _afiliadoresService.deleteAfiliador(id: affiliator.id);
      if (!mounted) return;

      final willBeEmpty = _affiliators.length <= 1;
      final shouldLoadPrev = willBeEmpty && _affiliatorsPage > 0;

      setState(() {
        _affiliators = _affiliators
            .where((item) => item.id != affiliator.id)
            .toList();
        if (_affiliatorsTotalElements > 0) {
          _affiliatorsTotalElements -= 1;
        }
        _affiliatorsDeleting.remove(affiliator.id);
      });

      if (shouldLoadPrev) {
        _loadAffiliators(page: _affiliatorsPage - 1, force: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _affiliatorsDeleting.remove(affiliator.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudo eliminar el afiliador.',
            style: TextStyle(color: Colors.white),
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

  Future<void> _showAffiliatorForm() async {
    await showCreateAffiliateDialog(
      context: context,
      service: _afiliadoresService,
      onCreated: () => _loadAffiliators(force: true),
    );
  }

  void _showAffiliationsCount(AfiliadorModel afiliador) {
    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        bool isFetching = false;
        int? totalJugadores;
        String? fetchError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!isFetching && totalJugadores == null && fetchError == null) {
              isFetching = true;
              _afiliadoresService
                  .fetchAfiliadorTotalJugadores(id: afiliador.id)
                  .then((count) {
                setDialogState(() {
                  totalJugadores = count;
                  isFetching = false;
                });
              }).catchError((e) {
                setDialogState(() {
                  fetchError = 'No se pudo obtener la cantidad.';
                  isFetching = false;
                });
              });
            }

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: green.withValues(alpha: 0.20)),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.06),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: green.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: green.withValues(alpha: 0.22),
                              ),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: green,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  afiliador.nombre,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Afiliador registrado',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.38),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Contenido ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: totalJugadores != null
                          ? Column(
                              children: [
                                Text(
                                  'Total de afiliaciones',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: green.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: green.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$totalJugadores',
                                        style: const TextStyle(
                                          color: green,
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        totalJugadores == 1
                                            ? 'jugador afiliado'
                                            : 'jugadores afiliados',
                                        style: TextStyle(
                                          color: green.withValues(alpha: 0.60),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : fetchError != null
                              ? Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppConstants.errorRed,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        fetchError!,
                                        style: const TextStyle(
                                          color: AppConstants.errorRed,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox(
                                  height: 56,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: green,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                    ),

                    // ── Acción ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            backgroundColor: green.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: green.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(
                              color: green,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleGoToPage(int targetPage) {
    if (targetPage < 0) return;
    final lastIndex =
        _affiliatorsTotalPages > 0 ? _affiliatorsTotalPages - 1 : null;
    if (lastIndex != null && targetPage > lastIndex) return;
    _loadAffiliators(page: targetPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Afiliadores', showBackButton: true),
      body: AffiliatesManagementeView(
        onCreate: _showAffiliatorForm,
        items: _affiliators,
        isLoading: _isLoadingAffiliators,
        errorMessage: _affiliatorsError,
        totalElements: _affiliatorsTotalElements,
        page: _affiliatorsPage,
        totalPages: _affiliatorsTotalPages,
        pageSize: _affiliatorsPageSize,
        isFirstPage: _affiliatorsFirst,
        isLastPage: _affiliatorsLast,
        updatingIds: _affiliatorsUpdating,
        deletingIds: _affiliatorsDeleting,
        onRetry: () => _loadAffiliators(force: true),
        onGoToPage: _handleGoToPage,
        onToggleActive: _toggleAffiliatorActive,
        onDelete: _deleteAffiliator,
        onViewAffiliations: _showAffiliationsCount,
      ),
    );
  }
}
