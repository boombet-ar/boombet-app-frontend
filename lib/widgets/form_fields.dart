import 'package:flutter/material.dart';
import 'package:boombet_app/config/app_constants.dart';

/// Reusable text form field for registration forms
class AppTextFormField extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colors adaptativos según tema
    final labelColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;
    final hintColor = isDark ? Colors.grey[500] : AppConstants.lightHintText;
    final borderColor = hasError
        ? Colors.red
        : (isDark ? Colors.grey[700] : AppConstants.lightInputBorder);
    final focusedBorderColor = hasError
        ? Colors.red
        : (isDark
              ? AppConstants.primaryGreen
              : AppConstants.lightInputBorderFocus);
    final fillColor = isDark
        ? const Color(0xFF2A2A2A)
        : AppConstants.lightInputBg;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          validator: validator,
          textInputAction: textInputAction,
          focusNode: focusNode,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: hintColor, fontSize: 13),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: borderColor ?? Colors.grey,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: borderColor ?? Colors.grey,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: focusedBorderColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (hasError && errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

/// Reusable password field with visibility toggle
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colors adaptativos según tema
    final labelColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;
    final hintColor = isDark ? Colors.grey[500] : AppConstants.lightHintText;
    final borderColor = widget.hasError
        ? Colors.red
        : (isDark ? Colors.grey[700] : AppConstants.lightInputBorder);
    final focusedBorderColor = widget.hasError
        ? Colors.red
        : (isDark
              ? AppConstants.primaryGreen
              : AppConstants.lightInputBorderFocus);
    final fillColor = isDark
        ? const Color(0xFF2A2A2A)
        : AppConstants.lightInputBg;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;
    final suffixIconColor = isDark
        ? Colors.grey[400]
        : AppConstants.lightLabelText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          onChanged: widget.onChanged,
          textInputAction: widget.textInputAction,
          focusNode: widget.focusNode,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: hintColor, fontSize: 13),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: borderColor ?? Colors.grey,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: borderColor ?? Colors.grey,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: focusedBorderColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: suffixIconColor,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
        if (widget.hasError && widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

/// Reusable gender selector with modern design
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
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;
    final unselectedBgColor = isDark
        ? const Color(0xFF2A2A2A).withValues(alpha: 0.6)
        : AppConstants.lightSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Género',
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _GenderButton(
                label: 'Masculino',
                icon: Icons.male,
                value: 'M',
                isSelected: selectedGender == 'M',
                onTap: () => onGenderChanged('M'),
                primaryColor: primaryColor,
                isDark: isDark,
                unselectedBgColor: unselectedBgColor,
                textColor: textColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _GenderButton(
                label: 'Femenino',
                icon: Icons.female,
                value: 'F',
                isSelected: selectedGender == 'F',
                onTap: () => onGenderChanged('F'),
                primaryColor: primaryColor,
                isDark: isDark,
                unselectedBgColor: unselectedBgColor,
                textColor: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual gender button with animation
class _GenderButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool isSelected;
  final Function() onTap;
  final Color primaryColor;
  final bool isDark;
  final Color unselectedBgColor;
  final Color textColor;

  const _GenderButton({
    required this.label,
    required this.icon,
    required this.value,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
    required this.unselectedBgColor,
    required this.textColor,
  });

  @override
  State<_GenderButton> createState() => _GenderButtonState();
}

class _GenderButtonState extends State<_GenderButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_GenderButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _animationController.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              gradient: widget.isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.primaryColor,
                        widget.primaryColor.withValues(alpha: 0.8),
                      ],
                    )
                  : null,
              color: widget.isSelected ? null : widget.unselectedBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected
                    ? widget.primaryColor.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: widget.isSelected ? Colors.white : Colors.grey[600],
                    fontSize: widget.isSelected ? 28 : 24,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Icon(
                    widget.icon,
                    size: widget.isSelected ? 28 : 24,
                    color: widget.isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: widget.isSelected ? Colors.white : widget.textColor,
                    fontSize: widget.isSelected ? 13 : 12,
                    fontWeight: widget.isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable button with loading state and animations
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
    this.height = 56.0,
    this.borderRadius = 14.0,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final bgColor = backgroundColor ?? primaryColor;
    final txtColor = textColor ?? (isDark ? Colors.white : Colors.white);
    final effectiveBgColor = disabled || isLoading
        ? bgColor.withValues(alpha: 0.5)
        : bgColor;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled || isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            decoration: BoxDecoration(
              gradient: !disabled && !isLoading
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [bgColor, bgColor.withValues(alpha: 0.85)],
                    )
                  : null,
              color: disabled || isLoading ? effectiveBgColor : null,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: !disabled && !isLoading
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.4 : 0.3,
                        ),
                        blurRadius: 12,
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(txtColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Cargando...',
                          style: TextStyle(
                            color: txtColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: txtColor, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: txtColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
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
