import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';

class FilteredParallaxComponent extends ParallaxComponent {
  FilteredParallaxComponent({
    required super.parallax,
    this.colorFilter,
    this.opacity = 1.0,
  });

  ui.ColorFilter? colorFilter;
  double opacity;

  @override
  void render(ui.Canvas canvas) {
    final filter = colorFilter;
    final o = opacity;

    if (filter == null && o >= 1.0) {
      super.render(canvas);
      return;
    }

    final paint = ui.Paint();
    if (filter != null) {
      paint.colorFilter = filter;
    }
    if (o < 1.0) {
      paint.color = ui.Color(0xFFFFFFFF).withValues(alpha: o);
    }

    canvas.saveLayer(null, paint);
    super.render(canvas);
    canvas.restore();
  }
}
