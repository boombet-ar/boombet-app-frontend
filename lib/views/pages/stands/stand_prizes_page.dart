import 'dart:developer';
import 'dart:typed_data';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/stand_prize_model.dart';
import 'package:boombet_app/services/stands_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class StandPrizesPage extends StatefulWidget {
  const StandPrizesPage({super.key});

  @override
  State<StandPrizesPage> createState() => _StandPrizesPageState();
}

class _StandPrizesPageState extends State<StandPrizesPage> {
  final StandsService _service = StandsService();
  List<StandPrizeModel> _prizes = [];
  bool _isLoading = false;
  String? _error;
  final Set<int> _editingIds = {};
  final Set<int> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _loadPrizes();
  }

  Future<void> _createPrize() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CreatePrizeDialog(
        onCreate:
            ({
              required String nombre,
              required int stock,
              Uint8List? imageBytes,
              String? imageName,
              String imageMimeType = 'image/jpeg',
            }) => _service.createStandPrize(
              nombre: nombre,
              stock: stock,
              imageBytes: imageBytes,
              imageName: imageName,
              imageMimeType: imageMimeType,
            ),
      ),
    );
    await _loadPrizes();
  }

  Future<void> _editPrize(StandPrizeModel prize) async {
    setState(() => _editingIds.add(prize.id));
    await showDialog<void>(
      context: context,
      builder: (_) => _EditPrizeDialog(
        prize: prize,
        onUpdate:
            ({
              String? nombre,
              int? stock,
              Uint8List? imageBytes,
              String? imageName,
              String imageMimeType = 'image/jpeg',
            }) => _service.updateStandPrize(
              premioId: prize.id,
              nombre: nombre,
              stock: stock,
              imageBytes: imageBytes,
              imageName: imageName,
              imageMimeType: imageMimeType,
            ),
      ),
    );
    if (!mounted) return;
    setState(() => _editingIds.remove(prize.id));
    await _loadPrizes();
  }

  Future<void> _deletePrize(StandPrizeModel prize) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppConstants.errorRed.withValues(alpha: 0.35),
          ),
        ),
        title: const Text(
          'Eliminar premio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '\u00bfEliminar "${prize.nombre}"? Esta acci\u00f3n no se puede deshacer.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.primaryGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: AppConstants.errorRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _deletingIds.add(prize.id));
    try {
      await _service.deleteStandPrize(premioId: prize.id);
      if (!mounted) return;
      setState(() {
        _prizes.removeWhere((p) => p.id == prize.id);
        _deletingIds.remove(prize.id);
      });
    } catch (e) {
      log('[StandPrizesPage] delete error: $e');
      if (!mounted) return;
      setState(() => _deletingIds.remove(prize.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar: ${e.toString().replaceFirst('Exception: ', '')}',
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
        ),
      );
    }
  }

  Future<void> _loadPrizes() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prizes = await _service.fetchStandPrizes();
      if (!mounted) return;
      setState(() {
        _prizes = prizes;
        _isLoading = false;
      });
    } catch (e, stack) {
      log('[StandPrizesPage] load error: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar los premios: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFF0E0E0E);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/stand-tools');
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: ListView(
          padding: EdgeInsets.zero,
        children: [
          SectionHeaderWidget(
            title: 'Premios del Stand',
            subtitle: 'Premios disponibles y su stock actual.',
            icon: Icons.workspace_premium_outlined,
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
    return Column(
      children: [
        _PrizeCreateButton(onTap: _createPrize),
        const SizedBox(height: 16),
        _buildList(),
      ],
    );
  }

  Widget _buildList() {
    final theme = Theme.of(context);

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
      return _PrizesError(message: _error!, onRetry: _loadPrizes);
    }

    if (_prizes.isEmpty) {
      return _PrizesEmpty(onRetry: _loadPrizes);
    }

    return Column(
      children: [
        ..._prizes.map(
          (prize) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PrizeTile(
              prize: prize,
              isEditing: _editingIds.contains(prize.id),
              isDeleting: _deletingIds.contains(prize.id),
              onEdit: () => _editPrize(prize),
              onDelete: () => _deletePrize(prize),
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
                  '${_prizes.length} premio${_prizes.length == 1 ? '' : 's'} disponible${_prizes.length == 1 ? '' : 's'}',
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

class _PrizeTile extends StatelessWidget {
  final StandPrizeModel prize;
  final bool isEditing;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PrizeTile({
    required this.prize,
    required this.isEditing,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const green = AppConstants.primaryGreen;

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.darkAccent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppConstants.borderRadius),
              bottomLeft: Radius.circular(AppConstants.borderRadius),
            ),
            child: SizedBox(
              width: 90,
              height: 90,
              child: prize.imgUrl.isNotEmpty
                  ? Image.network(
                      prize.imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, st) => _PlaceholderIcon(),
                    )
                  : _PlaceholderIcon(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prize.nombre.isNotEmpty ? prize.nombre : 'Sin nombre',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: green.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Stock: ${prize.stock}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isEditing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.primaryGreen,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: AppConstants.primaryGreen.withValues(alpha: 0.85),
                      onPressed: isDeleting ? null : onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
              isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.errorRed,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppConstants.errorRed.withValues(alpha: 0.85),
                      onPressed: isEditing ? null : onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConstants.primaryGreen.withValues(alpha: 0.10),
      child: const Center(
        child: Icon(
          Icons.workspace_premium_rounded,
          color: AppConstants.primaryGreen,
          size: 32,
        ),
      ),
    );
  }
}

class _PrizesError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PrizesError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.darkAccent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.errorRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No se pudieron cargar los premios.',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizesEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _PrizesEmpty({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              'No hay premios para mostrar.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Refrescar')),
        ],
      ),
    );
  }
}

class _PrizeCreateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PrizeCreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppConstants.darkAccent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: green.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, color: green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Agregar premio',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: green.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create prize dialog ────────────────────────────────────────────────────────

class _CreatePrizeDialog extends StatefulWidget {
  final Future<StandPrizeModel> Function({
    required String nombre,
    required int stock,
    Uint8List? imageBytes,
    String? imageName,
    String imageMimeType,
  })
  onCreate;

  const _CreatePrizeDialog({required this.onCreate});

  @override
  State<_CreatePrizeDialog> createState() => _CreatePrizeDialogState();
}

class _CreatePrizeDialogState extends State<_CreatePrizeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageName;
  String _imageMimeType = 'image/jpeg';
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
        _imageMimeType = file.mimeType ?? 'image/jpeg';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudo cargar la imagen.',
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      await widget.onCreate(
        nombre: _nombreCtrl.text.trim(),
        stock: int.parse(_stockCtrl.text.trim()),
        imageBytes: _imageBytes,
        imageName: _imageName,
        imageMimeType: _imageMimeType,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    const green = AppConstants.primaryGreen;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
      prefixIcon: Icon(icon, color: green.withValues(alpha: 0.70), size: 20),
      filled: true,
      fillColor: const Color(0xFF141414),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.55)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppConstants.errorRed.withValues(alpha: 0.50),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppConstants.errorRed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: green.withValues(alpha: 0.22)),
      ),
      title: const Text(
        'Nuevo premio',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Nombre', Icons.label_outline),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresá un nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stockCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Stock',
                    Icons.inventory_2_outlined,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Ingresá el stock';
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 0) return 'Ingresá un número válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // ── Image picker ──────────────────────────────────────
                GestureDetector(
                  onTap: _isSubmitting ? null : _pickImage,
                  child: Container(
                    height: _imageBytes != null ? null : 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: green.withValues(alpha: 0.18)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageBytes != null
                        ? Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.memory(
                                _imageBytes!,
                                width: double.infinity,
                                height: 130,
                                fit: BoxFit.cover,
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _imageBytes = null),
                                child: Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: green.withValues(alpha: 0.65),
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Seleccionar imagen (opcional)',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.errorRed.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppConstants.errorRed,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _submitError!,
                            style: const TextStyle(
                              color: AppConstants.errorRed,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: green)),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: green,
                  ),
                )
              : const Text(
                  'Crear',
                  style: TextStyle(color: green, fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}

// ── Edit prize dialog ──────────────────────────────────────────────────────────

class _EditPrizeDialog extends StatefulWidget {
  final StandPrizeModel prize;
  final Future<StandPrizeModel> Function({
    String? nombre,
    int? stock,
    Uint8List? imageBytes,
    String? imageName,
    String imageMimeType,
  })
  onUpdate;

  const _EditPrizeDialog({required this.prize, required this.onUpdate});

  @override
  State<_EditPrizeDialog> createState() => _EditPrizeDialogState();
}

class _EditPrizeDialogState extends State<_EditPrizeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _stockCtrl;
  final _imagePicker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageName;
  String _imageMimeType = 'image/jpeg';
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.prize.nombre);
    _stockCtrl = TextEditingController(text: widget.prize.stock.toString());
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
        _imageMimeType = file.mimeType ?? 'image/jpeg';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudo cargar la imagen.',
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      await widget.onUpdate(
        nombre: _nombreCtrl.text.trim(),
        stock: int.parse(_stockCtrl.text.trim()),
        imageBytes: _imageBytes,
        imageName: _imageName,
        imageMimeType: _imageMimeType,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    const green = AppConstants.primaryGreen;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
      prefixIcon: Icon(icon, color: green.withValues(alpha: 0.70), size: 20),
      filled: true,
      fillColor: const Color(0xFF141414),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.55)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppConstants.errorRed.withValues(alpha: 0.50),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppConstants.errorRed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;
    final hasExistingImage =
        widget.prize.imgUrl.isNotEmpty && _imageBytes == null;

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: green.withValues(alpha: 0.22)),
      ),
      title: const Text(
        'Editar premio',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Nombre', Icons.label_outline),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresá un nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stockCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Stock',
                    Icons.inventory_2_outlined,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Ingresá el stock';
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 0) return 'Ingresá un número válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // ── Image picker ──────────────────────────────────────
                GestureDetector(
                  onTap: _isSubmitting ? null : _pickImage,
                  child: Container(
                    height: (_imageBytes != null || hasExistingImage)
                        ? null
                        : 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: green.withValues(alpha: 0.18)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageBytes != null
                        ? Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.memory(
                                _imageBytes!,
                                width: double.infinity,
                                height: 130,
                                fit: BoxFit.cover,
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _imageBytes = null),
                                child: Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : hasExistingImage
                        ? Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.network(
                                widget.prize.imgUrl,
                                width: double.infinity,
                                height: 130,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 130,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.white38,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Tocar para cambiar',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: green.withValues(alpha: 0.65),
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Seleccionar imagen (opcional)',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.errorRed.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppConstants.errorRed,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _submitError!,
                            style: const TextStyle(
                              color: AppConstants.errorRed,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: green)),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: green,
                  ),
                )
              : const Text(
                  'Guardar',
                  style: TextStyle(color: green, fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}
