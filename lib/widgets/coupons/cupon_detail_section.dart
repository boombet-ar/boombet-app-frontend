import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class CuponDetailSection extends StatelessWidget {
  const CuponDetailSection({
    super.key,
    required this.title,
    required this.icon,
    required this.primaryGreen,
    required this.content,
    required this.textColor,
  });

  final String title;
  final IconData icon;
  final Color primaryGreen;
  final String content;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryGreen,
                        primaryGreen.withValues(alpha: 0.50),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.40),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: primaryGreen.withValues(alpha: 0.07),
                    child: Row(
                      children: [
                        Icon(icon, color: primaryGreen, size: 15),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryGreen,
                            letterSpacing: 0.5,
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
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
          ),
          child: Html(
            data: content,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(13),
                color: textColor,
                lineHeight: const LineHeight(1.5),
              ),
              'p': Style(margin: Margins.only(bottom: 8)),
              'ul': Style(margin: Margins.only(left: 16, bottom: 8)),
              'li': Style(margin: Margins.only(bottom: 4)),
            },
          ),
        ),
      ],
    );
  }
}
