import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CouponCodeBox extends StatelessWidget {
  const CouponCodeBox({
    super.key,
    required this.code,
    required this.primaryGreen,
    required this.textColor,
    this.compact = false,
    this.codeFontSize = 16,
    this.padding,
  });

  final String code;
  final Color primaryGreen;
  final Color textColor;
  final bool compact;
  final double codeFontSize;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? EdgeInsets.all(compact ? 8.0 : 12.0);

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryGreen.withValues(alpha: 0.12),
            primaryGreen.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  compact ? 'Código:' : 'Tu Código',
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    color: textColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: compact ? 2 : 6),
                if (code.isEmpty)
                  Text(
                    'Codigo no disponible',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryGreen.withValues(alpha: 0.8),
                    ),
                  )
                else if (compact)
                  SizedBox(
                    height: 16,
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          code,
                          style: TextStyle(
                            fontSize: codeFontSize,
                            fontWeight: FontWeight.w800,
                            color: primaryGreen,
                            fontFamily: 'monospace',
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: codeFontSize + 6,
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        code,
                        style: TextStyle(
                          fontSize: codeFontSize,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                          fontFamily: 'monospace',
                          letterSpacing: 1.2,
                        ),
                        softWrap: false,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: compact ? 8.0 : 12.0),
          InkWell(
            onTap: code.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Código copiado: $code'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: primaryGreen,
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(compact ? 10.0 : 12.0),
            child: Container(
              padding: EdgeInsets.all(compact ? 6.0 : 8.0),
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(compact ? 10.0 : 12.0),
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.content_copy,
                color: primaryGreen,
                size: compact ? 16 : 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
