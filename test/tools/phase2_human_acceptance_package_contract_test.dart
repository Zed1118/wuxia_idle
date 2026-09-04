import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/phase2_human_acceptance_package.dart';

void main() {
  const commit = '0123456789abcdef0123456789abcdef01234567';
  const appHash =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const fixtureHash =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  const archiveHash =
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

  test('package runner freezes a clean checked-out profile build', () {
    final script = File(
      'tools/phase2_acceptance/prepare_consolidated_human_package.sh',
    ).readAsStringSync();

    expect(script, contains('flutter build macos --profile --no-pub'));
    expect(script, contains('refusing to package a dirty worktree'));
    expect(script, contains('candidate must be the checked-out HEAD'));
    expect(script, contains('refusing to replace an existing package'));
    expect(script, contains(r'ditto "$source_app" "$package_app"'));
    expect(script, contains('phase0a_debug_battle.yaml'));
    expect(script, contains('phase2_human_acceptance_package.dart'));
    expect(script, isNot(contains(r'open "$package_app"')));
  });

  test('manifest starts pending and never substitutes formal gates', () {
    final manifest = buildPackageManifest(
      commit: commit,
      appChecksum: appHash,
      fixtureChecksum: fixtureHash,
      archiveChecksum: archiveHash,
    );

    expect(manifest['schema'], 'phase2-consolidated-human-package-v1');
    expect(manifest['commit'], commit);
    expect(manifest['entry_mode'], 'production_root_app');
    expect(manifest['evidence_state'], 'PENDING_HUMAN_EXECUTION');
    expect(manifest['formal_gates_closed'], isEmpty);
    expect(manifest['human_gate_substituted'], isFalse);
    expect(manifest['windows_gate_substituted'], isFalse);
    expect(manifest['app_sha256'], appHash);
    expect(manifest['fixture_sha256'], fixtureHash);
    expect(manifest['archive_sha256'], archiveHash);
    expect(manifest['covered_milestones'], <String>[
      'M2',
      'M3',
      'M4',
      'M5',
      'M6',
    ]);
  });

  test('checklist freezes exact artifacts and current acceptance scope', () {
    final template = File(
      'docs/dispatch/phase2_consolidated_human_acceptance_template.md',
    ).readAsStringSync();
    final rendered = renderConsolidatedChecklist(template, <String, String>{
      'COMMIT': commit,
      'APP_SHA256': appHash,
      'FIXTURE_SHA256': fixtureHash,
      'ARCHIVE_SHA256': archiveHash,
    });

    for (final value in <String>[commit, appHash, fixtureHash, archiveHash]) {
      expect(rendered, contains(value));
    }
    expect(rendered, contains('生产根入口'));
    expect(rendered, contains('补充证据，不能替代正式验收'));
    for (final milestone in <String>['M2', 'M3', 'M4', 'M5', 'M6']) {
      expect(rendered, contains(milestone));
    }
    for (final weapon in <String>['剑', '重兵', '软兵', '双兵', '暗器']) {
      expect(rendered, contains(weapon));
    }
    for (final mode in <String>['九霄塔', '轻功', '守城', '心魔', '断魂庄', '百草岭']) {
      expect(rendered, contains(mode));
    }
    for (final control in <String>[
      'WASD',
      'J',
      'Space',
      'Q',
      'R',
      '1–6',
      'Esc',
      'Enter',
    ]) {
      expect(rendered, contains(control));
    }
    expect(rendered, contains('NOT_RUN'));
    expect(rendered, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
  });

  test('checklist renderer rejects unresolved placeholders', () {
    expect(
      () => renderConsolidatedChecklist('still {{UNKNOWN}}', const {}),
      throwsStateError,
    );
  });
}
