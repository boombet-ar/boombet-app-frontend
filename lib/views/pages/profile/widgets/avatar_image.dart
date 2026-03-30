import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarImage extends StatelessWidget {
  final String? imageUrl;
  final Color primaryColor;
  final double size;

  const AvatarImage({
    super.key,
    required this.imageUrl,
    required this.primaryColor,
    this.size = 130,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? '';

    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => Icon(
          Icons.person,
          size: (size * 0.55).clamp(48.0, 96.0).toDouble(),
          color: primaryColor,
        ),
      );
    }

    return Icon(
      Icons.person,
      size: (size * 0.55).clamp(48.0, 96.0).toDouble(),
      color: primaryColor,
    );
  }
}
