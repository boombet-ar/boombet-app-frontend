import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

class AffiliationsCountDialog extends StatefulWidget {
  final String label;
  final Future<int> Function() fetchTotal;

  const AffiliationsCountDialog({
    super.key,
    required this.label,
    required this.fetchTotal,
  });

  @override
  State<AffiliationsCountDialog> createState() =>
      _AffiliationsCountDialogState();
}

class _AffiliationsCountDialogState extends State<AffiliationsCountDialog> {
  bool _isFetching = false;
  int? _total;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isFetching = true);
    try {
      final v = await widget.fetchTotal();
      if (!mounted) return;
      setState(() {
        _total = v;
        _isFetching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo obtener la cantidad.';
        _isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: green.withValues(alpha: 0.20)),
      ),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    bottom:
                        BorderSide(color: green.withValues(alpha: 0.12))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.people_outline,
                        color: green, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Afiliaciones',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        Text(widget.label,
                            style: TextStyle(
                                color: green.withValues(alpha: 0.70),
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: _isFetching
                  ? const SizedBox(
                      height: 48,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: green, strokeWidth: 2.5)))
                  : _error != null
                      ? Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.60),
                              fontSize: 13))
                      : Column(children: [
                          Text('$_total',
                              style: const TextStyle(
                                  color: green,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  height: 1)),
                          const SizedBox(height: 6),
                          Text(
                              'jugador${_total == 1 ? '' : 'es'} afiliado${_total == 1 ? '' : 's'}',
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13)),
                        ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 11),
                    backgroundColor: green.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                          color: green.withValues(alpha: 0.18)),
                    ),
                  ),
                  child: const Text('Cerrar',
                      style: TextStyle(
                          color: green,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
