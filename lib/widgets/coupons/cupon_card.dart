import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/widgets/coupons/coupon_code_box.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CuponCard extends StatelessWidget {
  const CuponCard({
    super.key,
    required this.cupon,
    required this.primaryGreen,
    required this.textColor,
    required this.isDark,
    required this.isClaimed,
    required this.isClaiming,
    required this.displayCode,
    required this.imageUrlBuilder,
    required this.cleanHtml,
    required this.onTap,
    required this.onClaim,
    this.compactMobile = false,
    this.forceMobileStyle = false,
  });

  final Cupon cupon;
  final Color primaryGreen;
  final Color textColor;
  final bool isDark;
  final bool isClaimed;
  final bool isClaiming;
  final String displayCode;
  final String Function(String) imageUrlBuilder;
  final String Function(String) cleanHtml;
  final VoidCallback onTap;
  final VoidCallback onClaim;
  final bool compactMobile;
  final bool forceMobileStyle;

  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 380;

  Widget _buildClaimButton(BuildContext context, {bool compact = false}) {
    final isSmallScreen = _isSmallScreen(context);
    final showIcon = !isSmallScreen;
    final isDisabled = isClaimed || isClaiming;

    return ElevatedButton(
      onPressed: isDisabled ? null : onClaim,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: AppConstants.textLight,
        disabledBackgroundColor: Colors.grey.shade800,
        disabledForegroundColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 7 : (compact ? 9 : 11),
          horizontal: isSmallScreen ? 12 : (compact ? 14 : 16),
        ),
        minimumSize: Size(isSmallScreen ? 88 : 0, isSmallScreen ? 36 : 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
        shadowColor: primaryGreen.withValues(alpha: 0.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              isClaimed ? Icons.check_circle_outline : Icons.check_circle,
              size: 17,
            ),
            const SizedBox(width: 7),
          ],
          Text(
            isClaimed
                ? 'Reclamado'
                : (isClaiming ? 'Reclamando...' : 'Reclamar'),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && !forceMobileStyle;
    final double heroHeight = isWeb ? 140 : (compactMobile ? 112 : 160);
    final double logoSize = compactMobile ? 40 : 56;
    final EdgeInsets contentPadding = isWeb
        ? const EdgeInsets.fromLTRB(16, 14, 16, 14)
        : (compactMobile
              ? const EdgeInsets.fromLTRB(14, 12, 14, 0)
              : const EdgeInsets.fromLTRB(16, 14, 16, 0));
    final double gapSm = isWeb ? 8 : (compactMobile ? 6 : 10);
    final double gapMd = isWeb ? 10 : (compactMobile ? 8 : 14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: const Color(0xFF111111),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Hero image ---
                  Stack(
                    children: [
                      Container(
                        height: heroHeight,
                        width: double.infinity,
                        color: const Color(0xFF1A1A1A),
                        child: cupon.fotoUrl.isNotEmpty
                            ? Image.network(
                                imageUrlBuilder(cupon.fotoUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Icon(
                                        Icons.local_offer,
                                        size: 64,
                                        color: primaryGreen.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.local_offer,
                                  size: 64,
                                  color: primaryGreen.withValues(alpha: 0.3),
                                ),
                              ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: isClaimed
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryGreen.withValues(alpha: 0.9),
                                      primaryGreen,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryGreen.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: isDark
                                          ? Colors.white
                                          : AppConstants.textLight,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reclamado',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppConstants.textLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Positioned(
                        top: compactMobile ? 8 : 12,
                        right: compactMobile ? 8 : 12,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compactMobile ? 9 : 12,
                            vertical: compactMobile ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryGreen,
                                primaryGreen.withValues(alpha: 0.75),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                              compactMobile ? 18 : 24,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withValues(alpha: 0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            cupon.descuento,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: compactMobile ? 12 : 16,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: compactMobile ? 8 : 12,
                        left: compactMobile ? 8 : 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(
                              compactMobile ? 10 : 12,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: primaryGreen.withValues(alpha: 0.30),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: cupon.logoUrl.isNotEmpty
                                ? Image.network(
                                    imageUrlBuilder(cupon.logoUrl),
                                    width: logoSize,
                                    height: logoSize,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildLogoFallback(logoSize),
                                  )
                                : _buildLogoFallback(logoSize),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- Content ---
                  if (isWeb)
                    Expanded(
                      child: Padding(
                        padding: contentPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cupon.nombre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.storefront,
                                  size: 14,
                                  color: primaryGreen.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    cupon.empresa.nombre,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: gapSm),
                            Text(
                              cleanHtml(cupon.descripcionBreve),
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withValues(alpha: 0.7),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: gapSm),
                            if (cupon.categorias.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: cupon.categorias
                                    .take(2)
                                    .map((cat) => _buildCategoryChip(cat.nombre))
                                    .toList(),
                              ),
                            SizedBox(height: gapSm),
                            _buildDateRow(isClaimed: isClaimed, fontSize: 11),
                            SizedBox(
                              height: compactMobile ? 4 : gapSm,
                            ),
                            const Spacer(),
                            if (isClaimed)
                              CouponCodeBox(
                                code: displayCode,
                                primaryGreen: primaryGreen,
                                textColor: textColor,
                                compact: compactMobile,
                                codeFontSize: 16,
                                padding: const EdgeInsets.all(10),
                              )
                            else
                              Align(
                                alignment: Alignment.centerRight,
                                child: _buildClaimButton(context),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Padding(
                        padding: contentPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cupon.nombre,
                              style: TextStyle(
                                fontSize: compactMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: 0.2,
                              ),
                              maxLines: compactMobile ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.storefront,
                                  size: 14,
                                  color: primaryGreen.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    cupon.empresa.nombre,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: gapSm),
                            if (!compactMobile) ...[
                              Text(
                                cleanHtml(cupon.descripcionBreve),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor.withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: gapSm),
                            ],
                            if (cupon.categorias.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: cupon.categorias
                                    .take(compactMobile ? 1 : 2)
                                    .map((cat) {
                                      final rawName = cat.nombre.trim();
                                      final displayName =
                                          compactMobile && rawName.contains(',')
                                          ? rawName.split(',').first.trim()
                                          : rawName;
                                      return _buildCategoryChip(
                                        displayName,
                                        fontSize: compactMobile ? 10 : 11,
                                      );
                                    })
                                    .toList(),
                              ),
                            SizedBox(height: gapSm),
                            _buildDateRow(
                              isClaimed: isClaimed,
                              fontSize: compactMobile ? 10 : 11,
                            ),
                            SizedBox(height: compactMobile ? 4 : gapMd),
                            if (isClaimed)
                              CouponCodeBox(
                                code: displayCode,
                                primaryGreen: primaryGreen,
                                textColor: textColor,
                                compact: compactMobile,
                                codeFontSize: compactMobile ? 16 : 18,
                                padding: EdgeInsets.all(compactMobile ? 8 : 12),
                              )
                            else
                              Align(
                                alignment: compactMobile
                                    ? Alignment.center
                                    : Alignment.centerRight,
                                child: _buildClaimButton(
                                  context,
                                  compact: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoFallback(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Text(
          cupon.empresa.nombre
              .substring(0, cupon.empresa.nombre.length.clamp(0, 2))
              .toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String name, {double fontSize = 11}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: fontSize,
          color: primaryGreen,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  Widget _buildDateRow({required bool isClaimed, required double fontSize}) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today_rounded,
          size: 14,
          color: textColor.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isClaimed
                ? 'Reclamado el: ${cupon.fechaVencimientoFormatted}'
                : 'Válido hasta: ${cupon.fechaVencimientoFormatted}',
            style: TextStyle(
              fontSize: fontSize,
              color: textColor.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
