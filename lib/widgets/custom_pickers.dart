import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in replacement for [showDatePicker].
/// Returns the selected [DateTime] or null if dismissed.
Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _CustomDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

/// Drop-in replacement for [showTimePicker].
/// Returns the selected [TimeOfDay] or null if dismissed.
Future<TimeOfDay?> showCustomTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => _CustomTimePickerDialog(initialTime: initialTime),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Date Picker
// ─────────────────────────────────────────────────────────────────────────────

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CustomDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CustomDatePickerDialog> createState() =>
      _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late DateTime _selected;
  late DateTime _viewMonth;

  static const _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _dayNames = ['Do', 'Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa'];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _viewMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _goToPreviousMonth() {
    final prev = DateTime(_viewMonth.year, _viewMonth.month - 1);
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    if (!prev.isBefore(firstMonth)) setState(() => _viewMonth = prev);
  }

  void _goToNextMonth() {
    final next = DateTime(_viewMonth.year, _viewMonth.month + 1);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    if (!next.isAfter(lastMonth)) setState(() => _viewMonth = next);
  }

  /// Returns a list of [DateTime?] representing each cell in the calendar grid.
  /// Nulls are padding before the 1st of the month.
  List<DateTime?> _buildGrid() {
    final first = DateTime(_viewMonth.year, _viewMonth.month, 1);
    // weekday: 1=Mon … 7=Sun → offset so Sunday = 0
    final startOffset = first.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(_viewMonth.year, _viewMonth.month);

    return [
      ...List<DateTime?>.filled(startOffset, null),
      for (int d = 1; d <= daysInMonth; d++)
        DateTime(_viewMonth.year, _viewMonth.month, d),
    ];
  }

  bool _isSelected(DateTime day) =>
      day.year == _selected.year &&
      day.month == _selected.month &&
      day.day == _selected.day;

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  bool _isDisabled(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final f = DateTime(
        widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final l = DateTime(
        widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    return d.isBefore(f) || d.isAfter(l);
  }

  bool get _canGoPrev {
    final prev = DateTime(_viewMonth.year, _viewMonth.month - 1);
    final firstMonth =
        DateTime(widget.firstDate.year, widget.firstDate.month);
    return !prev.isBefore(firstMonth);
  }

  bool get _canGoNext {
    final next = DateTime(_viewMonth.year, _viewMonth.month + 1);
    final lastMonth =
        DateTime(widget.lastDate.year, widget.lastDate.month);
    return !next.isAfter(lastMonth);
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);

    final grid = _buildGrid();
    // Pad to full weeks
    final cellCount = ((grid.length / 7).ceil()) * 7;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 6),
        side: BorderSide(color: green.withValues(alpha: 0.20)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadius + 6),
                  topRight: Radius.circular(AppConstants.borderRadius + 6),
                ),
                border: Border(
                  bottom: BorderSide(color: green.withValues(alpha: 0.12)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: green.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      color: green,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seleccioná la fecha',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '${_monthNames[_selected.month - 1]} ${_selected.day}, ${_selected.year}',
                          style: TextStyle(
                            color: green.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Month navigator + calendar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Column(
                children: [
                  // Month / year row
                  Row(
                    children: [
                      _NavButton(
                        icon: Icons.chevron_left_rounded,
                        onPressed: _canGoPrev ? _goToPreviousMonth : null,
                      ),
                      Expanded(
                        child: Text(
                          '${_monthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      _NavButton(
                        icon: Icons.chevron_right_rounded,
                        onPressed: _canGoNext ? _goToNextMonth : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Day-of-week labels
                  Row(
                    children: _dayNames
                        .map(
                          (d) => Expanded(
                            child: Text(
                              d,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.30),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 6),

                  // Calendar grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: cellCount,
                    itemBuilder: (_, index) {
                      if (index >= grid.length || grid[index] == null) {
                        return const SizedBox.shrink();
                      }
                      final day = grid[index]!;
                      final sel = _isSelected(day);
                      final today = _isToday(day);
                      final disabled = _isDisabled(day);

                      return GestureDetector(
                        onTap: disabled
                            ? null
                            : () => setState(() => _selected = day),
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: sel ? green : Colors.transparent,
                            shape: BoxShape.circle,
                            border: !sel && today
                                ? Border.all(
                                    color: green.withValues(alpha: 0.55),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: sel
                                    ? Colors.black
                                    : disabled
                                        ? Colors.white.withValues(alpha: 0.16)
                                        : today
                                            ? green
                                            : Colors.white
                                                .withValues(alpha: 0.80),
                                fontSize: 13,
                                fontWeight: sel || today
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Actions ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: _ActionRow(
                onCancel: () => Navigator.pop(context),
                onConfirm: () => Navigator.pop(context, _selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time Picker
// ─────────────────────────────────────────────────────────────────────────────

class _CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const _CustomTimePickerDialog({required this.initialTime});

  @override
  State<_CustomTimePickerDialog> createState() =>
      _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<_CustomTimePickerDialog> {
  late int _hour;
  late int _minute;

  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 6),
        side: BorderSide(color: green.withValues(alpha: 0.20)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadius + 6),
                  topRight: Radius.circular(AppConstants.borderRadius + 6),
                ),
                border: Border(
                  bottom: BorderSide(color: green.withValues(alpha: 0.12)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: green.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(
                      Icons.schedule_outlined,
                      color: green,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seleccioná la hora',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Deslizá para seleccionar',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Wheel pickers ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Column(
                children: [
                  // Selected time readout
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: green.withValues(alpha: 0.18)),
                    ),
                    child: Center(
                      child: Text(
                        '${_hour.toString().padLeft(2, '0')} : ${_minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: green,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Labels row — outside the Stack so they don't offset
                  // the wheel center away from the highlight band
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'HH',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.28),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      // Invisible spacer matching the colon separator width
                      const Opacity(
                        opacity: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'MM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.28),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Wheels — now full 150px, so highlight center = wheel center
                  SizedBox(
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Selection highlight band (centered at exactly 75px)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: green.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: green.withValues(alpha: 0.16),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Row(
                          children: [
                            // Hours wheel (no label inside)
                            Expanded(
                              child: _WheelPicker(
                                controller: _hourCtrl,
                                itemCount: 24,
                                onChanged: (i) =>
                                    setState(() => _hour = i),
                              ),
                            ),

                            // Colon separator
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4),
                              child: Text(
                                ':',
                                style: TextStyle(
                                  color: green.withValues(alpha: 0.70),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            // Minutes wheel (no label inside)
                            Expanded(
                              child: _WheelPicker(
                                controller: _minuteCtrl,
                                itemCount: 60,
                                onChanged: (i) =>
                                    setState(() => _minute = i),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Actions ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: _ActionRow(
                onCancel: () => Navigator.pop(context),
                onConfirm: () => Navigator.pop(
                  context,
                  TimeOfDay(hour: _hour, minute: _minute),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _WheelPicker extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final ValueChanged<int> onChanged;

  const _WheelPicker({
    required this.controller,
    required this.itemCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 44,
      diameterRatio: 1.5,
      perspective: 0.0025,
      squeeze: 1.0,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = index == controller.selectedItem;
          return Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                color: isSelected
                    ? green
                    : Colors.white.withValues(alpha: 0.28),
                fontSize: isSelected ? 24 : 18,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    final enabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: enabled
                ? green.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? green.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Icon(
            icon,
            color: enabled
                ? green.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.18),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _ActionRow({required this.onCancel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
