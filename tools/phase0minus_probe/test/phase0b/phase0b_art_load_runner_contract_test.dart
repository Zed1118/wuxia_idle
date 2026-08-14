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

  test('art load and scroll runners fail-closed on DPR/refresh', () {
    final artLoadRunner = File(
      'scripts/run_phase0b_art_load_macos.sh',
    ).readAsStringSync();
    final scrollRunner = File(
      'scripts/run_phase0b_scroll_macos.sh',
    ).readAsStringSync();

    for (final entry in [
      ('art-load', artLoadRunner),
      ('scroll', scrollRunner),
    ]) {
      final name = entry.$1;
      final script = entry.$2;
      expect(
        script.contains(':-144') || script.contains(':-60'),
        isFalse,
        reason: '$name runner must not hardcode a local refresh rate default',
      );
      expect(
        script.contains(':-2}'),
        isFalse,
        reason: '$name runner must not hardcode a local DPR default',
      );
      expect(
        script,
        contains('PROBE_EXPECTED_REFRESH_RATE'),
        reason: '$name runner must reference refresh rate env var',
      );
      expect(
        script,
        contains('PROBE_EXPECTED_DPR'),
        reason: '$name runner must reference DPR env var',
      );
      expect(
        script,
        contains('must be set'),
        reason: '$name runner must fail-closed when env vars are unset',
      );
    }
  });
}
