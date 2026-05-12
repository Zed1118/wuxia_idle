import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Shared screen shake offset for short impact feedback.
Offset screenShakeOffset({required double t, double amplitude = 4.0}) {
  final x = t == 0 ? 0.0 : math.sin(t * 2 * math.pi) * amplitude;
  return Offset(x, x * 0.5);
}
