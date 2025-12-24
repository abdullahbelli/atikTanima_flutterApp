import 'dart:ui';

class Detection {
  final Rect box; // 640x640 koordinatında (left, top, right, bottom)
  final String label;
  final double confidence;

  const Detection({
    required this.box,
    required this.label,
    required this.confidence,
  });
}
