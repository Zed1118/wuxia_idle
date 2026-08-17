import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('performance sampling requires a stable calibrated viewport', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('attempt <= 20'));
    expect(source, contains('consecutiveMatches >= 3'));
    expect(source, contains('viewport.width - 64'));
    expect(source, contains('viewport.height - 64'));
    expect(source, contains('PROBE_VIEWPORT_CALIBRATION_FAIL'));
    expect(source, contains('PHASE0A_VIEWPORT_CALIBRATION_FAIL'));
    expect(source, contains('await windowManager.close()'));
  });
}
