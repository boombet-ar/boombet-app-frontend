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
    final isDark = theme.brightness == Brightness.dark;
    final greenColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              enableInteractiveSelection: true,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSearch,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
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
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                      topLeft: Radius.circular(0),
                      bottomLeft: Radius.circular(0),
                    ),
                    onTap: _handleClearTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Icon(
                        Icons.clear,
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                InkWell(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  onTap: _handleSearchTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Icon(Icons.search, color: greenColor, size: 24),
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
