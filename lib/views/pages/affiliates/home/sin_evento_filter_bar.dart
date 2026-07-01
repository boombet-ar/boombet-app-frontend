import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

enum SinEventoFilter { tids, sorteos, stands, subAfiliados, formularios }

extension SinEventoFilterLabel on SinEventoFilter {
  String get label => switch (this) {
        SinEventoFilter.tids => 'TIDs',
        SinEventoFilter.sorteos => 'Sorteos',
        SinEventoFilter.stands => 'Stands',
        SinEventoFilter.subAfiliados => 'Sub-afiliados',
        SinEventoFilter.formularios => 'Formularios',
      };

  IconData get icon => switch (this) {
        SinEventoFilter.tids => Icons.track_changes_outlined,
        SinEventoFilter.sorteos => Icons.emoji_events_outlined,
        SinEventoFilter.stands => Icons.storefront_outlined,
        SinEventoFilter.subAfiliados => Icons.group_outlined,
        SinEventoFilter.formularios => Icons.dynamic_form_outlined,
      };
}

class SinEventoFilterBar extends StatelessWidget {
  final SinEventoFilter? selected;
  final ValueChanged<SinEventoFilter> onSelected;

  const SinEventoFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        scrollDirection: Axis.horizontal,
        children: SinEventoFilter.values.map((f) {
          final isSelected = selected == f;
          const green = AppConstants.primaryGreen;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? green.withValues(alpha: 0.12)
                      : const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? green.withValues(alpha: 0.42)
                        : Colors.white.withValues(alpha: 0.10),
                    width: isSelected ? 1.2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: green.withValues(alpha: 0.14),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f.icon,
                        size: 13,
                        color: isSelected
                            ? green
                            : Colors.white.withValues(alpha: 0.40)),
                    const SizedBox(width: 6),
                    Text(f.label,
                        style: TextStyle(
                          color: isSelected
                              ? green
                              : Colors.white.withValues(alpha: 0.50),
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
