import 'package:flutter/material.dart';

class GameItem {
  final String title;
  final String subtitle;
  final String description;
  final String badge;
  final String asset;
  final Widget page;

  const GameItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.badge,
    required this.asset,
    required this.page,
  });
}
