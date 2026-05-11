import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/pending_verification_model.dart';
import 'package:boombet_app/services/casino_service.dart';
import 'package:boombet_app/views/pages/admin/casino_verifications/casino_verifications_admin_view.dart';
import 'package:flutter/material.dart';

class CasinoVerificationsAdminPage extends StatefulWidget {
  const CasinoVerificationsAdminPage({super.key});

  @override
  State<CasinoVerificationsAdminPage> createState() =>
      _CasinoVerificationsAdminPageState();
}

class _CasinoVerificationsAdminPageState
    extends State<CasinoVerificationsAdminPage> {
  final _service = CasinoService();

  List<PendingVerification> _items = [];
  bool _isLoading = false;
  String? _error;
  final Set<int> _approvingIds = {};
  final Set<int> _rejectingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getPendingVerifications();
      if (!mounted) return;
      setState(() {
        _items = data;
        _isLoading = false;
      });
    } catch (e, stack) {
      log('[CasinoVerifications] load error: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar verificaciones: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resolve(PendingVerification item, String estado) async {
    final isApproving = estado == 'OK';
    final trackingSet = isApproving ? _approvingIds : _rejectingIds;

    if (trackingSet.contains(item.id)) return;
    setState(() => trackingSet.add(item.id));

    try {
      await _service.adminResolveVerification(
        afiliacionId: item.id,
        estado: estado,
      );
      if (!mounted) return;
      setState(() {
        _items = _items.where((v) => v.id != item.id).toList();
        trackingSet.remove(item.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => trackingSet.remove(item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApproving
                ? 'No se pudo aprobar la verificación.'
                : 'No se pudo rechazar la verificación.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0E),
        foregroundColor: AppConstants.primaryGreen,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Verificaciones Pendientes',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CasinoVerificationsAdminView(
        items: _items,
        isLoading: _isLoading,
        errorMessage: _error,
        approvingIds: _approvingIds,
        rejectingIds: _rejectingIds,
        onRetry: () => _load(force: true),
        onApprove: (item) => _resolve(item, 'OK'),
        onReject: (item) => _resolve(item, 'RECHAZADO'),
      ),
    );
  }
}
