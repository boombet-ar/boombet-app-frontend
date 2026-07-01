import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/formulario_model.dart';
import 'package:boombet_app/models/raffle_model.dart';
import 'package:boombet_app/models/stand_model.dart';
import 'package:boombet_app/models/sub_afiliado_model.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/domain/raffle_service.dart';
import 'package:boombet_app/services/domain/stands_service.dart';
import 'package:boombet_app/services/domain/sub_afiliados_service.dart';
import 'package:boombet_app/services/domain/tids_service.dart';
import 'package:boombet_app/views/pages/admin/raffles/raffles_management_view.dart';
import 'package:boombet_app/views/pages/affiliates/tids/create_tid.dart';
import 'package:boombet_app/views/pages/affiliates/home/formulario_detail_dialog.dart';
import 'package:boombet_app/views/pages/affiliates/tids/evento_dropdown.dart';
import 'package:boombet_app/views/pages/affiliates/home/dialogs/affiliations_count_dialog.dart';
import 'package:boombet_app/views/pages/affiliates/home/dialogs/confirm_delete_dialog.dart';
import 'package:boombet_app/views/pages/affiliates/home/dialogs/edit_sorteo_dialog.dart';
import 'package:boombet_app/views/pages/affiliates/home/dialogs/edit_tid_dialog.dart';
import 'package:boombet_app/views/pages/affiliates/home/dialogs/form_qr_dialog.dart';
import 'package:boombet_app/views/pages/affiliates/home/dialogs/tid_qr_dialog.dart';
import 'package:boombet_app/views/pages/affiliates/home/sin_evento_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tab "Sin evento" de la home del panel de afiliados.
class SinEventoTab extends StatefulWidget {
  final List<TidModel> tids;
  final List<RaffleModel> sorteos;
  final List<StandModel> stands;
  final List<SubAfiliadoModel> subAfiliados;
  final List<FormularioModel> formularios;
  final List<EventoOption> eventoOptions;
  final List<StandOption> standOptions;

  const SinEventoTab({
    super.key,
    required this.tids,
    required this.sorteos,
    required this.stands,
    required this.subAfiliados,
    required this.formularios,
    required this.eventoOptions,
    required this.standOptions,
  });

  @override
  State<SinEventoTab> createState() => _SinEventoTabState();
}

class _SinEventoTabState extends State<SinEventoTab> {
  SinEventoFilter? _filter;

  // ── Servicios ─────────────────────────────────────────────────────────────
  final _tidsService = TidsService();
  final _standsService = StandsService();
  final _subAfiliadosService = SubAfiliadosService();
  final _raffleService = RaffleService();

  // ── Estado de acciones ────────────────────────────────────────────────────
  final Set<int> _editingTidIds = {};
  final Set<int> _deletingTidIds = {};
  final Set<int> _deletingStandIds = {};
  final Set<int> _deletingSubAfiliadoIds = {};
  final Set<int> _togglingRaffleIds = {};
  final Set<int> _deletingRaffleIds = {};

  // ── Listas locales (para reflejar eliminaciones/ediciones sin recargar) ───
  late List<TidModel> _tids;
  late List<StandModel> _stands;
  late List<SubAfiliadoModel> _subAfiliados;
  late List<RaffleModel> _sorteosSinEvento;

  @override
  void initState() {
    super.initState();
    _tids = widget.tids.where((t) => t.idEvento == 0).toList();
    _stands = List.of(widget.stands);
    _subAfiliados = List.of(widget.subAfiliados);
    _sorteosSinEvento =
        widget.sorteos.where((s) => s.eventoId == null).toList();
  }

  @override
  void didUpdateWidget(SinEventoTab old) {
    super.didUpdateWidget(old);
    if (widget.tids != old.tids) {
      _tids = widget.tids.where((t) => t.idEvento == 0).toList();
    }
    if (widget.stands != old.stands) _stands = List.of(widget.stands);
    if (widget.subAfiliados != old.subAfiliados) {
      _subAfiliados = List.of(widget.subAfiliados);
    }
    if (widget.sorteos != old.sorteos) {
      _sorteosSinEvento =
          widget.sorteos.where((s) => s.eventoId == null).toList();
    }
  }

  // ── TID: ver afiliaciones ─────────────────────────────────────────────────

  void _showTidAffiliationsCount(TidModel tid) {
    showDialog<void>(
      context: context,
      builder: (_) => AffiliationsCountDialog(
        label: tid.tid,
        fetchTotal: () => _tidsService.fetchTidTotalJugadores(id: tid.id),
      ),
    );
  }

  // ── TID: QR ───────────────────────────────────────────────────────────────

  void _showTidQr(TidModel tid) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => TidQrDialog(tid: tid),
    );
  }

  // ── TID: QR formulario ────────────────────────────────────────────────────

  void _showFormQrDialog(TidModel tid) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => FormQrDialog(tid: tid),
    );
  }

  // ── TID: editar ───────────────────────────────────────────────────────────

  Future<void> _editTid(TidModel tid) async {
    if (_editingTidIds.contains(tid.id)) return;

    final result = await showDialog<(String, int?, int?)>(
      context: context,
      builder: (_) => EditTidDialog(
        tid: tid,
        eventoOptions: widget.eventoOptions,
        standOptions: widget.standOptions,
      ),
    );

    if (result == null || result.$1.isEmpty) return;

    setState(() => _editingTidIds.add(tid.id));
    try {
      final updated = await _tidsService.updateTid(
        id: tid.id,
        tid: result.$1,
        idEvento: result.$2,
        idStand: result.$3,
        sendIdStand: true,
      );
      if (!mounted) return;
      setState(() {
        final idx = _tids.indexWhere((t) => t.id == tid.id);
        if (idx != -1) _tids[idx] = updated;
        _editingTidIds.remove(tid.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _editingTidIds.remove(tid.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el TID.')),
      );
    }
  }

  // ── TID: eliminar ─────────────────────────────────────────────────────────

  Future<void> _deleteTid(TidModel tid) async {
    final confirmed = await _showConfirmDialog(
      title: 'Eliminar TID',
      body: '¿Querés eliminar el TID "${tid.tid}"? Esta acción no se puede deshacer.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deletingTidIds.add(tid.id));
    try {
      await _tidsService.deleteTid(id: tid.id);
      if (!mounted) return;
      setState(() {
        _tids.removeWhere((t) => t.id == tid.id);
        _deletingTidIds.remove(tid.id);
      });
    } catch (e) {
      log('[SinEventoTab] deleteTid error: $e');
      if (!mounted) return;
      setState(() => _deletingTidIds.remove(tid.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el TID.')),
      );
    }
  }

  // ── Stand: eliminar ───────────────────────────────────────────────────────

  Future<void> _deleteStand(StandModel stand) async {
    final confirmed = await _showConfirmDialog(
      title: 'Eliminar stand',
      body: '¿Querés eliminar el stand "${stand.nombre}"? Esta acción no se puede deshacer.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deletingStandIds.add(stand.id));
    try {
      await _standsService.deleteStand(id: stand.id);
      if (!mounted) return;
      setState(() {
        _stands.removeWhere((s) => s.id == stand.id);
        _deletingStandIds.remove(stand.id);
      });
    } catch (e) {
      log('[SinEventoTab] deleteStand error: $e');
      if (!mounted) return;
      setState(() => _deletingStandIds.remove(stand.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el stand.')),
      );
    }
  }

  // ── Sub-afiliado: eliminar ────────────────────────────────────────────────

  Future<void> _deleteSubAfiliado(SubAfiliadoModel sa) async {
    final confirmed = await _showConfirmDialog(
      title: 'Eliminar sub-afiliador',
      body: '¿Querés eliminar a "${sa.nombre}"? Esta acción no se puede deshacer.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deletingSubAfiliadoIds.add(sa.id));
    try {
      await _subAfiliadosService.deleteSubAfiliado(sa.id);
      if (!mounted) return;
      setState(() {
        _subAfiliados.removeWhere((s) => s.id == sa.id);
        _deletingSubAfiliadoIds.remove(sa.id);
      });
    } catch (e) {
      log('[SinEventoTab] deleteSubAfiliado error: $e');
      if (!mounted) return;
      setState(() => _deletingSubAfiliadoIds.remove(sa.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo eliminar el sub-afiliador.')),
      );
    }
  }

  // ── Sub-afiliado: ver afiliaciones ────────────────────────────────────────

  void _showSubAfiliadoAffiliations(SubAfiliadoModel sa) {
    showDialog<void>(
      context: context,
      builder: (_) => AffiliationsCountDialog(
        label: sa.nombre,
        fetchTotal: () => _subAfiliadosService.fetchTotalJugadores(sa.id),
      ),
    );
  }

  // ── Sorteo: detalle ───────────────────────────────────────────────────────

  Future<void> _showSorteoDetail(RaffleModel raffle) async {
    if (raffle.id == null) return;
    await showRaffleDetailDialog(context, raffleId: raffle.id!);
  }

  // ── Sorteo: editar ────────────────────────────────────────────────────────

  Future<void> _editSorteo(RaffleModel raffle) async {
    if (raffle.id == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => EditSorteoDialog(raffle: raffle),
    );
  }

  // ── Sorteo: toggle activo ─────────────────────────────────────────────────

  Future<void> _toggleSorteo(RaffleModel raffle) async {
    final id = raffle.id;
    if (id == null || _togglingRaffleIds.contains(id)) return;

    setState(() {
      _togglingRaffleIds.add(id);
      _sorteosSinEvento = _sorteosSinEvento.map((r) {
        if (r.id != id) return r;
        return RaffleModel(
          id: r.id,
          codigoSorteo: r.codigoSorteo,
          activo: !r.activo,
          cantidadGanadores: r.cantidadGanadores,
          emailPresentador: r.emailPresentador,
          text: r.text,
          mediaUrl: r.mediaUrl,
          casinoGralId: r.casinoGralId,
          tidId: r.tidId,
          fechaFin: r.fechaFin,
          premios: r.premios,
          afiliadorId: r.afiliadorId,
          createdAt: r.createdAt,
          tipo: r.tipo,
          instrucciones: r.instrucciones,
          eventoId: r.eventoId,
        );
      }).toList();
    });

    try {
      await _raffleService.toggleRaffleActive(id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sorteosSinEvento = _sorteosSinEvento.map((r) {
          if (r.id != id) return r;
          return RaffleModel(
            id: r.id,
            codigoSorteo: r.codigoSorteo,
            activo: !r.activo,
            cantidadGanadores: r.cantidadGanadores,
            emailPresentador: r.emailPresentador,
            text: r.text,
            mediaUrl: r.mediaUrl,
            casinoGralId: r.casinoGralId,
            tidId: r.tidId,
            fechaFin: r.fechaFin,
            premios: r.premios,
            afiliadorId: r.afiliadorId,
            createdAt: r.createdAt,
            tipo: r.tipo,
            instrucciones: r.instrucciones,
            eventoId: r.eventoId,
          );
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo cambiar el estado del sorteo.')),
      );
    } finally {
      if (mounted) setState(() => _togglingRaffleIds.remove(id));
    }
  }

  // ── Sorteo: eliminar ──────────────────────────────────────────────────────

  Future<void> _deleteSorteo(RaffleModel raffle) async {
    if (raffle.id == null) return;
    final confirmed = await _showConfirmDialog(
      title: 'Eliminar sorteo',
      body: '¿Querés eliminar el sorteo "${raffle.text.isNotEmpty ? raffle.text : raffle.codigoSorteo}"? Esta acción no se puede deshacer.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deletingRaffleIds.add(raffle.id!));
    try {
      await _raffleService.deleteRaffle(raffle.id!);
      if (!mounted) return;
      setState(() {
        _sorteosSinEvento.removeWhere((r) => r.id == raffle.id);
        _deletingRaffleIds.remove(raffle.id!);
      });
    } catch (e) {
      log('[SinEventoTab] deleteSorteo error: $e');
      if (!mounted) return;
      setState(() => _deletingRaffleIds.remove(raffle.id!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el sorteo.')),
      );
    }
  }

  // ── Diálogo de confirmación genérico ──────────────────────────────────────

  Future<bool> _showConfirmDialog(
      {required String title, required String body}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDeleteDialog(title: title, body: body),
    );
    return result == true;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final formularios =
        widget.formularios.where((f) => f.eventoId == null).toList();

    return Column(
      children: [
        SinEventoFilterBar(
          selected: _filter,
          onSelected: (f) => setState(() => _filter = f),
        ),

        // Separador neon
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppConstants.primaryGreen.withValues(alpha: 0.15),
                AppConstants.primaryGreen.withValues(alpha: 0.30),
                AppConstants.primaryGreen.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // ── Contenido ─────────────────────────────────────────────────
        Expanded(
          child: _filter == null
              ? const _PromptState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    if (_filter == SinEventoFilter.tids)
                      _Section(
                        label: 'TIDs sin evento',
                        icon: Icons.track_changes_outlined,
                        children: _tids
                            .map((t) => _TidEntityTile(
                                  tid: t,
                                  isEditing: _editingTidIds.contains(t.id),
                                  isDeleting: _deletingTidIds.contains(t.id),
                                  onShowFormQr: () => _showFormQrDialog(t),
                                  onShowQr: () => _showTidQr(t),
                                  onEdit: () => _editTid(t),
                                  onDelete: () => _deleteTid(t),
                                  onViewAffiliations: () =>
                                      _showTidAffiliationsCount(t),
                                ))
                            .toList(),
                        empty: _tids.isEmpty,
                      ),
                    if (_filter == SinEventoFilter.sorteos)
                      _Section(
                        label: 'Sorteos sin evento',
                        icon: Icons.emoji_events_outlined,
                        children: _sorteosSinEvento
                            .map((s) => _SorteoEntityTile(
                                  raffle: s,
                                  isToggling:
                                      _togglingRaffleIds.contains(s.id),
                                  isDeleting:
                                      _deletingRaffleIds.contains(s.id),
                                  onTap: () => _showSorteoDetail(s),
                                  onEdit: () => _editSorteo(s),
                                  onDelete: () => _deleteSorteo(s),
                                  onToggleActive: () => _toggleSorteo(s),
                                ))
                            .toList(),
                        empty: _sorteosSinEvento.isEmpty,
                      ),
                    if (_filter == SinEventoFilter.stands)
                      _Section(
                        label: 'Stands',
                        icon: Icons.storefront_outlined,
                        children: _stands
                            .map((s) => _EntityTile(
                                  primary: s.nombre,
                                  secondary:
                                      s.activo ? 'Activo' : 'Inactivo',
                                  icon: Icons.storefront_outlined,
                                  isActive: s.activo,
                                  isDeleting:
                                      _deletingStandIds.contains(s.id),
                                  onDelete: () => _deleteStand(s),
                                ))
                            .toList(),
                        empty: _stands.isEmpty,
                      ),
                    if (_filter == SinEventoFilter.subAfiliados)
                      _Section(
                        label: 'Sub-afiliadores',
                        icon: Icons.group_outlined,
                        children: _subAfiliados
                            .map((sa) => _EntityTile(
                                  primary: sa.nombre,
                                  secondary:
                                      sa.activo ? 'Activo' : 'Inactivo',
                                  icon: Icons.person_outline_rounded,
                                  isActive: sa.activo,
                                  isDeleting:
                                      _deletingSubAfiliadoIds.contains(sa.id),
                                  onDelete: () => _deleteSubAfiliado(sa),
                                  onViewAffiliations: () =>
                                      _showSubAfiliadoAffiliations(sa),
                                ))
                            .toList(),
                        empty: _subAfiliados.isEmpty,
                      ),
                    if (_filter == SinEventoFilter.formularios)
                      _Section(
                        label: 'Formularios sin evento',
                        icon: Icons.dynamic_form_outlined,
                        children: formularios
                            .map((f) {
                              String secondary;
                              String? sorteoLabel;
                              RaffleModel? sorteo;
                              if (f.sorteoId != null) {
                                sorteo = widget.sorteos
                                    .where((s) => s.id == f.sorteoId)
                                    .firstOrNull;
                                sorteoLabel = sorteo?.codigoSorteo;
                                secondary =
                                    'Vinculado a ${sorteoLabel ?? 'sorteo #${f.sorteoId}'}';
                              } else if (f.tidId != null) {
                                final t = widget.tids
                                    .where((t) => t.id == f.tidId)
                                    .firstOrNull;
                                secondary =
                                    'Vinculado a ${t != null ? t.tid : 'TID #${f.tidId}'}';
                              } else {
                                secondary = 'Sin vinculación';
                              }
                              return _EntityTile(
                                primary: 'Formulario #${f.id}',
                                secondary: secondary,
                                icon: Icons.dynamic_form_outlined,
                                onTap: () => showFormularioDetailDialog(
                                  context,
                                  form: f,
                                  sorteoLabel: sorteoLabel,
                                  mediaUrl: sorteo?.mediaUrl,
                                ),
                              );
                            })
                            .toList(),
                        empty: formularios.isEmpty,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? navLabel;
  final String? navRoute;
  final List<Widget> children;
  final bool empty;

  const _Section({
    required this.label,
    required this.icon,
    this.navLabel,
    this.navRoute,
    required this.children,
    required this.empty,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 3,
              height: 20,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [green, green.withValues(alpha: 0.15)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.55),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(icon, size: 14, color: green.withValues(alpha: 0.65)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                )),
            if (navLabel != null && navRoute != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(navRoute!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: green.withValues(alpha: 0.22)),
                  ),
                  child: Text(navLabel!,
                      style: const TextStyle(
                          color: green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (empty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 28,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text('No hay elementos.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 12.5)),
              ],
            ),
          )
        else
          ...children,
      ],
    );
  }
}

// ── Tile genérico (stands, sub-afiliados, formularios) ────────────────────────

class _EntityTile extends StatelessWidget {
  final String primary;
  final String secondary;
  final IconData icon;
  final bool? isActive;
  final String? badge;
  final VoidCallback? onDelete;
  final bool isDeleting;
  final VoidCallback? onViewAffiliations;
  final VoidCallback? onTap;

  const _EntityTile({
    required this.primary,
    required this.secondary,
    required this.icon,
    this.isActive,
    this.badge,
    this.onDelete,
    this.isDeleting = false,
    this.onViewAffiliations,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const red = AppConstants.errorRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: onTap != null ? green.withValues(alpha: 0.08) : Colors.transparent,
          highlightColor: onTap != null ? green.withValues(alpha: 0.04) : Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: green.withValues(alpha: 0.12)),
            ),
            child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: green.withValues(alpha: 0.15)),
              ),
              child: Icon(icon, size: 14, color: green.withValues(alpha: 0.60)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(primary,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(secondary,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11)),
                  if (onViewAffiliations != null) ...[
                    const SizedBox(height: 2),
                    TextButton.icon(
                      onPressed: onViewAffiliations,
                      icon: const Icon(Icons.people_outline,
                          size: 12, color: green),
                      label: const Text('Ver total de afiliaciones',
                          style: TextStyle(color: green, fontSize: 11)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badge == 'APP'
                      ? Colors.blue.withValues(alpha: 0.12)
                      : Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: badge == 'APP'
                        ? Colors.blue.withValues(alpha: 0.28)
                        : Colors.purple.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(badge!,
                    style: TextStyle(
                        color: badge == 'APP'
                            ? Colors.blue.withValues(alpha: 0.85)
                            : Colors.purple.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3)),
              ),
            ],
            if (isActive != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isActive! ? green : Colors.white)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: (isActive! ? green : Colors.white).withValues(
                        alpha: isActive! ? 0.22 : 0.08),
                  ),
                ),
                child: Text(
                  isActive! ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                      color: (isActive! ? green : Colors.white)
                          .withValues(alpha: isActive! ? 0.85 : 0.30),
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: isDeleting ? null : onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: red.withValues(alpha: 0.20)),
                  ),
                  child: isDeleting
                      ? SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: red.withValues(alpha: 0.70)))
                      : Icon(Icons.delete_outline_rounded,
                          size: 15, color: red.withValues(alpha: 0.70)),
                ),
              ),
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 10, color: Colors.white.withValues(alpha: 0.18)),
            ],
          ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tile específico para TIDs (con botones de acción completos) ───────────────

class _TidEntityTile extends StatelessWidget {
  final TidModel tid;
  final bool isEditing;
  final bool isDeleting;
  final VoidCallback onShowFormQr;
  final VoidCallback onShowQr;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewAffiliations;

  const _TidEntityTile({
    required this.tid,
    required this.isEditing,
    required this.isDeleting,
    required this.onShowFormQr,
    required this.onShowQr,
    required this.onEdit,
    required this.onDelete,
    required this.onViewAffiliations,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const red = AppConstants.errorRed;
    final busy = isEditing || isDeleting;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: green.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: green.withValues(alpha: 0.15)),
              ),
              child: Icon(Icons.track_changes_outlined,
                  size: 14, color: green.withValues(alpha: 0.60)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tid.tid.isNotEmpty ? tid.tid : 'Sin TID',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text('TID · ID ${tid.id}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11)),
                  const SizedBox(height: 2),
                  TextButton.icon(
                    onPressed: onViewAffiliations,
                    icon: const Icon(Icons.people_outline,
                        size: 12, color: green),
                    label: const Text('Ver afiliaciones',
                        style: TextStyle(color: green, fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            // QR formulario
            IconButton(
              tooltip: 'QR de formulario',
              onPressed: busy ? null : onShowFormQr,
              icon: Icon(Icons.dynamic_form_outlined,
                  size: 18,
                  color: busy ? green.withValues(alpha: 0.30) : green),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
            // QR TID
            IconButton(
              tooltip: 'Ver QR del TID',
              onPressed: busy ? null : onShowQr,
              icon: Icon(Icons.qr_code_rounded,
                  size: 18,
                  color: busy ? green.withValues(alpha: 0.30) : green),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
            // Editar
            IconButton(
              tooltip: 'Editar TID',
              onPressed: busy ? null : onEdit,
              icon: isEditing
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: green.withValues(alpha: 0.70)))
                  : Icon(Icons.edit_outlined,
                      size: 18,
                      color: busy ? green.withValues(alpha: 0.30) : green),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
            // Eliminar
            IconButton(
              tooltip: 'Eliminar TID',
              onPressed: busy ? null : onDelete,
              icon: isDeleting
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: red.withValues(alpha: 0.70)))
                  : Icon(Icons.delete_outline_rounded,
                      size: 18,
                      color: busy ? red.withValues(alpha: 0.30) : red),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile específico para Sorteos ──────────────────────────────────────────────

class _SorteoEntityTile extends StatelessWidget {
  final RaffleModel raffle;
  final bool isToggling;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _SorteoEntityTile({
    required this.raffle,
    required this.isToggling,
    required this.isDeleting,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const red = AppConstants.errorRed;
    final busy = isToggling || isDeleting;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: green.withValues(alpha: 0.08),
          highlightColor: green.withValues(alpha: 0.04),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: green.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(7),
                    border:
                        Border.all(color: green.withValues(alpha: 0.15)),
                  ),
                  child: Icon(Icons.emoji_events_outlined,
                      size: 14, color: green.withValues(alpha: 0.60)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        raffle.text.isNotEmpty
                            ? raffle.text
                            : raffle.codigoSorteo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        raffle.codigoSorteo,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Badge tipo (APP/FORM)
                if (raffle.tipo != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: raffle.tipo == 'APP'
                          ? Colors.blue.withValues(alpha: 0.12)
                          : Colors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: raffle.tipo == 'APP'
                            ? Colors.blue.withValues(alpha: 0.28)
                            : Colors.purple.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      raffle.tipo!,
                      style: TextStyle(
                          color: raffle.tipo == 'APP'
                              ? Colors.blue.withValues(alpha: 0.85)
                              : Colors.purple.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                // Switch activo
                SizedBox(
                  width: 44,
                  height: 26,
                  child: isToggling
                      ? Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: green.withValues(alpha: 0.70)),
                          ),
                        )
                      : Transform.scale(
                          scale: 0.72,
                          child: Switch(
                            value: raffle.activo,
                            onChanged: busy ? null : (_) => onToggleActive(),
                            activeColor: green,
                            inactiveThumbColor:
                                Colors.white.withValues(alpha: 0.30),
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                ),
                const SizedBox(width: 4),
                // Editar
                IconButton(
                  tooltip: 'Editar sorteo',
                  onPressed: busy ? null : onEdit,
                  icon: Icon(Icons.edit_outlined,
                      size: 18,
                      color: busy ? green.withValues(alpha: 0.30) : green),
                  padding: const EdgeInsets.all(8),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                // Eliminar
                IconButton(
                  tooltip: 'Eliminar sorteo',
                  onPressed: busy ? null : onDelete,
                  icon: isDeleting
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: red.withValues(alpha: 0.70)))
                      : Icon(Icons.delete_outline_rounded,
                          size: 18,
                          color: busy ? red.withValues(alpha: 0.30) : red),
                  padding: const EdgeInsets.all(8),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptState extends StatelessWidget {
  const _PromptState();

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: green.withValues(alpha: 0.06),
                border: Border.all(color: green.withValues(alpha: 0.18)),
              ),
              child: Icon(Icons.touch_app_outlined,
                  size: 32, color: green.withValues(alpha: 0.50)),
            ),
            const SizedBox(height: 16),
            const Text('Seleccioná una sección',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Elegí un filtro arriba para ver las\nentidades sin evento asignado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.30),
                  fontSize: 12.5,
                  height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}
