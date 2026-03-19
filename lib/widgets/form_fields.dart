import 'package:flutter/material.dart';
import 'package:boombet_app/config/app_constants.dart';

// ─── Shared constants ────────────────────────────────────────────────────────
const _kFieldFill = Color(0xFF141414);
const _kFieldBorder = Color(0xFF272727);

// ─── Glow wrapper ─────────────────────────────────────────────────────────────
Widget _buildGlowField({
  required Widget child,
  required bool isFocused,
  required bool hasError,
  required Color primaryGreen,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOut,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      boxShadow: hasError
          ? [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.18),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ]
          : isFocused
          ? [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.16),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ]
          : [],
    ),
    child: child,
  );
}

// ─── Prefix icon builder ──────────────────────────────────────────────────────
Widget _buildPrefixIcon({
  required IconData icon,
  required bool hasError,
  required Color primaryGreen,
}) {
  return Container(
    margin: const EdgeInsets.all(9),
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: hasError
          ? Colors.red.withValues(alpha: 0.1)
          : primaryGreen.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: hasError
            ? Colors.red.withValues(alpha: 0.28)
            : primaryGreen.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    child: Icon(icon, color: hasError ? Colors.red : primaryGreen, size: 17),
  );
}

// ─── Shared InputDecoration builder ──────────────────────────────────────────
InputDecoration _buildDecoration({
  required String hint,
  required Color textColor,
  required Color primaryGreen,
  required bool hasError,
  Widget? prefixIconWidget,
  Widget? suffixIconWidget,
}) {
  final borderColor = hasError
      ? Colors.red.withValues(alpha: 0.6)
      : _kFieldBorder;
  final focusedBorderColor = hasError
      ? Colors.red
      : primaryGreen.withValues(alpha: 0.75);

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: textColor.withValues(alpha: 0.28),
      fontSize: 14,
    ),
    prefixIcon: prefixIconWidget,
    suffixIcon: suffixIconWidget,
    filled: true,
    fillColor: _kFieldFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      borderSide: BorderSide(color: borderColor, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      borderSide: BorderSide(color: borderColor, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      borderSide: BorderSide(
        color: Colors.red.withValues(alpha: 0.6),
        width: 1.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  );
}

// ─── AppTextFormField ─────────────────────────────────────────────────────────

class AppTextFormField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool hasError;
  final String? errorText;
  final int? maxLines;
  final int? minLines;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Widget? suffix;
  final IconData? icon;

  const AppTextFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.hasError = false,
    this.errorText,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.focusNode,
    this.suffix,
    this.icon,
  });

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  late FocusNode _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _isFocused = _effectiveFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _internalFocusNode.removeListener(_onFocusChanged);
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    final prefixWidget = widget.icon != null
        ? _buildPrefixIcon(
            icon: widget.icon!,
            hasError: widget.hasError,
            primaryGreen: primaryGreen,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            color: widget.hasError
                ? Colors.red.withValues(alpha: 0.85)
                : textColor.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        // Glow + Field
        _buildGlowField(
          isFocused: _isFocused,
          hasError: widget.hasError,
          primaryGreen: primaryGreen,
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            onChanged: widget.onChanged,
            validator: widget.validator,
            textInputAction: widget.textInputAction,
            focusNode: _effectiveFocusNode,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: _buildDecoration(
              hint: widget.hint,
              textColor: textColor,
              primaryGreen: primaryGreen,
              hasError: widget.hasError,
              prefixIconWidget: prefixWidget,
              suffixIconWidget: widget.suffix,
            ),
          ),
        ),
        // Error text
        if (widget.hasError && widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.85),
              fontSize: 11.5,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── AppPasswordField ─────────────────────────────────────────────────────────

class AppPasswordField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool hasError;
  final String? errorText;
  final Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const AppPasswordField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.hasError = false,
    this.errorText,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;
  late FocusNode _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _isFocused = _effectiveFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _internalFocusNode.removeListener(_onFocusChanged);
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            color: widget.hasError
                ? Colors.red.withValues(alpha: 0.85)
                : textColor.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        // Glow + Field
        _buildGlowField(
          isFocused: _isFocused,
          hasError: widget.hasError,
          primaryGreen: primaryGreen,
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscureText,
            onChanged: widget.onChanged,
            textInputAction: widget.textInputAction,
            focusNode: _effectiveFocusNode,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: _buildDecoration(
              hint: widget.hint,
              textColor: textColor,
              primaryGreen: primaryGreen,
              hasError: widget.hasError,
              prefixIconWidget: _buildPrefixIcon(
                icon: Icons.lock_outline,
                hasError: widget.hasError,
                primaryGreen: primaryGreen,
              ),
              suffixIconWidget: IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: textColor.withValues(alpha: 0.38),
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscureText = !_obscureText);
                },
              ),
            ),
          ),
        ),
        // Error text
        if (widget.hasError && widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.85),
              fontSize: 11.5,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── GenderSelector ───────────────────────────────────────────────────────────

class GenderSelector extends StatelessWidget {
  final String selectedGender;
  final Function(String) onGenderChanged;
  final Color primaryColor;
  final Color backgroundColor;

  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Género',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GenderButton(
                label: 'Masculino',
                icon: Icons.male_rounded,
                value: 'M',
                isSelected: selectedGender == 'M',
                onTap: () => onGenderChanged('M'),
                primaryColor: primaryColor,
                textColor: textColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderButton(
                label: 'Femenino',
                icon: Icons.female_rounded,
                value: 'F',
                isSelected: selectedGender == 'F',
                onTap: () => onGenderChanged('F'),
                primaryColor: primaryColor,
                textColor: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual gender button
class _GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color textColor;

  const _GenderButton({
    required this.label,
    required this.icon,
    required this.value,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.12)
              : _kFieldFill,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.75)
                : _kFieldBorder,
            width: isSelected ? 1.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.15)
                    : primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.4)
                      : primaryColor.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected
                    ? primaryColor
                    : textColor.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? primaryColor
                    : textColor.withValues(alpha: 0.45),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AppButton ────────────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool disabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 52.0,
    this.borderRadius = 14.0,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final bgColor = backgroundColor ?? primaryColor;
    final txtColor = textColor ?? Colors.black;
    final isDisabledOrLoading = disabled || isLoading;
    final effectiveBg = isDisabledOrLoading
        ? bgColor.withValues(alpha: 0.45)
        : bgColor;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabledOrLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDisabledOrLoading ? effectiveBg : null,
              gradient: !isDisabledOrLoading
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [bgColor, bgColor.withValues(alpha: 0.85)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: !isDisabledOrLoading
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.38),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(txtColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: TextStyle(
                            color: txtColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: txtColor, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: txtColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
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
}
