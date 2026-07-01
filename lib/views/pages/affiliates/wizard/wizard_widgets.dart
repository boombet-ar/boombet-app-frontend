/// Widgets reutilizables internos del wizard.
library;

import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

class WizardFieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const WizardFieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: AppConstants.primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class WizardTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool readOnly;
  final bool obscureText;
  final VoidCallback? onTap;
  final Widget? suffix;
  final TextCapitalization capitalization;
  final int maxLines;

  const WizardTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.readOnly = false,
    this.obscureText = false,
    this.onTap,
    this.suffix,
    this.capitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  @override
  State<WizardTextField> createState() => _WizardTextFieldState();
}

class _WizardTextFieldState extends State<WizardTextField> {
  late final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: green.withValues(alpha: 0.16),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        textCapitalization: widget.capitalization,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        obscureText: widget.obscureText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
        cursorColor: green,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.22),
            fontSize: 13,
          ),
          filled: true,
          fillColor: const Color(0xFF141414),
          prefixIcon: Container(
            margin: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _hasFocus
                    ? green.withValues(alpha: 0.40)
                    : green.withValues(alpha: 0.20),
              ),
            ),
            child: Icon(
              widget.icon,
              color: _hasFocus ? green : green.withValues(alpha: 0.55),
              size: 16,
            ),
          ),
          suffixIcon: widget.suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: green.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: green.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: green,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle de "Saltear paso" estandarizado para Sorteo y Formulario.
class WizardSkipToggle extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const WizardSkipToggle({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? green.withValues(alpha: 0.08) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? green.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.10),
            width: 1.2,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: green.withValues(alpha: 0.10),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: value
                    ? green.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value
                      ? green.withValues(alpha: 0.30)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                Icons.skip_next_rounded,
                color: value ? green : Colors.white.withValues(alpha: 0.35),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: value ? green : Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: green,
              inactiveThumbColor: Colors.white.withValues(alpha: 0.30),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador de vinculación automática (para el paso Formulario).
class WizardBindingIndicator extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const WizardBindingIndicator({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: green.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          // Barra lateral neon
          Container(
            width: 3,
            height: 32,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [green, green.withValues(alpha: 0.15)],
              ),
              boxShadow: [
                BoxShadow(
                  color: green.withValues(alpha: 0.45),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(icon, color: green.withValues(alpha: 0.70), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, height: 1.4),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: green.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
