import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const frozenPath = 'docs/phase0/evidence/phase0b-art-load-matrix-frozen.json';
  const checksumPath =
      'docs/phase0/evidence/phase0b-art-load-matrix-frozen.json.sha256';

  test('Phase 0B art-load frozen matrix is intact and auditable', () {
    final frozenFile = File(frozenPath);
    expect(frozenFile.existsSync(), isTrue, reason: 'frozen evidence missing');

    final expectedSha256 = File(checksumPath).readAsStringSync().trim();
    final actualSha256 = _fileSha256(frozenPath);
    expect(
      actualSha256,
      equals(expectedSha256),
      reason: 'frozen evidence checksum mismatch',
    );

    final report =
        jsonDecode(frozenFile.readAsStringSync()) as Map<String, dynamic>;
    expect(report['schema_version'], equals(1));
    expect(report['gate_eligible'], isFalse);
    expect(
      report['claim'],
      equals('art_load_observation_only_not_phase0minus_or_gameplay_gate'),
    );

    final buildCommit = report['build_commit'] as String;
    expect(buildCommit, hasLength(greaterThanOrEqualTo(7)));
    expect(
      _isAncestor(buildCommit),
      isTrue,
      reason: 'frozen build_commit $buildCommit is not an ancestor of HEAD',
    );

    final assetSha256 = report['asset_sha256'] as Map<String, dynamic>;
    expect(
      assetSha256['background'],
      equals(_sha256(_assetPath('mountain_pass_background_v2.png'))),
    );
    expect(
      assetSha256['founder'],
      equals(_sha256(_assetPath('founder_pose_atlas_v1.png'))),
    );
    expect(
      assetSha256['bandit'],
      equals(_sha256(_assetPath('bandit_pose_atlas_v1.png'))),
    );
    expect(
      assetSha256['elite'],
      equals(_sha256(_assetPath('elite_pose_atlas_v1.png'))),
    );

    final observations = report['observations'] as List<dynamic>;
    expect(observations.length, equals(6));

    final viewports = observations
        .map(
          (o) =>
              (o as Map<String, dynamic>)['viewport'] as Map<String, dynamic>,
        )
        .map((v) => v['id'] as String)
        .toList();
    expect(viewports.where((id) => id == 'desktop_1280x720').length, equals(3));
    expect(viewports.where((id) => id == 'desktop_1440x900').length, equals(3));

    for (final observation in observations.cast<Map<String, dynamic>>()) {
      expect(observation['frames'], greaterThanOrEqualTo(300));
      expect(
        (observation['total_span'] as Map<String, dynamic>)['p99_us'],
        isA<int>(),
      );
      expect(
        (observation['total_span'] as Map<String, dynamic>)['max_us'],
        isA<int>(),
      );
      expect(observation['over_reference_budget_count'], isA<int>());
      expect(observation['maximum_severe_streak'], isA<int>());
    }
  });

  test('art-load runner enforces non-Gate claim and display identity', () {
    final runner = File(
      'tools/phase0minus_probe/scripts/run_phase0b_art_load_macos.sh',
    ).readAsStringSync();
    expect(runner, contains('gate_eligible == false'));
    expect(
      runner,
      contains('art_load_observation_only_not_phase0minus_or_gameplay_gate'),
    );
    expect(runner, contains(r'.build_commit == $build_commit'));
    expect(runner, contains('.asset_sha256.background'));
    expect(runner, contains('.asset_sha256.founder'));
    expect(runner, contains('.asset_sha256.bandit'));
    expect(runner, contains('.asset_sha256.elite'));
    expect(runner, contains(r'.viewport.device_pixel_ratio == $expected_dpr'));
    expect(runner, contains(r'.viewport.refresh_rate_hz == $expected_refresh'));
  });
}

bool _isAncestor(String commit) {
  final result = Process.runSync('git', [
    'merge-base',
    '--is-ancestor',
    commit,
    'HEAD',
  ]);
  return result.exitCode == 0;
}

String _assetPath(String name) =>
    'tools/phase0minus_probe/assets/phase0b/runtime/$name';

String _sha256(String path) {
  final result = Process.runSync('shasum', ['-a', '256', path]);
  expect(result.exitCode, equals(0));
  return (result.stdout as String).split(' ').first;
}

String _fileSha256(String path) {
  final result = Process.runSync('shasum', ['-a', '256', path]);
  expect(result.exitCode, equals(0));
  return (result.stdout as String).split(' ').first;
}
