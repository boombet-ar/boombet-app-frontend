import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onSearch;
  final Function(String)? onChanged;
  final String placeholder;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.onSearch,
    this.onChanged,
    this.placeholder = '¿Qué estás buscando?',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _hasText = false;

  TextEditingController? get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller?.addListener(_onControllerChanged);
    _hasText = _controller?.text.isNotEmpty == true;
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      _controller?.addListener(_onControllerChanged);
      _hasText = _controller?.text.isNotEmpty == true;
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final hasTextNow = _controller?.text.isNotEmpty == true;
    if (hasTextNow != _hasText) {
      setState(() {
        _hasText = hasTextNow;
      });
    }
  }

  void _handleSearchTap() {
    if (widget.onSearch != null && _controller != null) {
      widget.onSearch!(_controller!.text);
    }
  }

  void _handleClearTap() {
    if (_controller == null) return;
    _controller!.clear();
    widget.onChanged?.call('');
    widget.onSearch?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greenColor = theme.colorScheme.primary;
    final textColor = AppConstants.textDark;
    final hintColor = AppConstants.textDark.withValues(alpha: 0.65);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: greenColor.withValues(alpha: 0.20),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: greenColor.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(
              Icons.search_rounded,
              color: greenColor.withValues(alpha: 0.50),
              size: 19,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              enableInteractiveSelection: true,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSearch,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                letterSpacing: 0.1,
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: TextStyle(color: hintColor, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Row(
              children: [
                if (_hasText)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _handleClearTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: hintColor,
                        size: 17,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _handleSearchTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: greenColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: greenColor.withValues(alpha: 0.28),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: greenColor,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
