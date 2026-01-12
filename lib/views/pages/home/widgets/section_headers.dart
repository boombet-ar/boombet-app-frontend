import 'package:flutter/material.dart';
import 'package:boombet_app/config/app_constants.dart';

Widget buildSectionHeader(
  String title,
  String subtitle,
  IconData icon,
  Color primaryGreen,
  bool isDark,
) {
  final headerBg = isDark ? Colors.grey[800] : AppConstants.lightAccent;
  final headerTextColor = isDark ? Colors.white : AppConstants.textLight;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: headerBg,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryGreen, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: headerTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: headerTextColor),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildSectionHeaderWithSwitch(
  String title,
  String subtitle,
  IconData icon,
  Color primaryGreen,
  bool isDark, {
  required bool isShowingClaimed,
  required VoidCallback onSwitchPressed,
}) {
  final headerBg = isDark ? Colors.grey[800] : AppConstants.lightAccent;
  final headerTextColor = isDark ? Colors.white : AppConstants.textLight;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: headerBg,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryGreen, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: headerTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: headerTextColor),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSwitchPressed,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                isShowingClaimed
                    ? Icons.local_offer_outlined
                    : Icons.check_circle_outline,
                color: headerTextColor,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
