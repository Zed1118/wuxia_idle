import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('art load runner rejects mixed displays and keeps non-Gate claim', () {
    final runner = File(
      'scripts/run_phase0b_art_load_macos.sh',
    ).readAsStringSync();
    final matrix = File(
      'scripts/run_phase0b_art_load_matrix_macos.sh',
    ).readAsStringSync();

    expect(runner, contains('PROBE_WINDOW_X'));
    expect(runner, contains(r'.viewport.refresh_rate_hz == $expected_refresh'));
    expect(runner, contains(r'.viewport.device_pixel_ratio == $expected_dpr'));
    expect(runner, contains('.gate_eligible == false'));
    expect(matrix, contains(r'"$window_x" "$window_y"'));
  });
}
