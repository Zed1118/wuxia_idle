import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('human package runner builds root app once and never launches GUI', () {
    final script = File(
      'tools/route_c_gate/prepare_route_c_human_package.sh',
    ).readAsStringSync();

    expect(script, contains('flutter build macos --profile --no-pub'));
    expect(script, contains('route_c_human_gate.dart prepare'));
    expect(script, contains('phase0a_battle_playable'));
    expect(script, contains(r'ditto "$source_app" "$package_app"'));
    expect(script, contains('phase0a_debug_battle.yaml'));
    expect(script, isNot(contains(r'open "$package_app"')));
  });

  test('human aggregator re-hashes returned package artifacts', () {
    final source = File('tool/route_c_human_gate.dart').readAsStringSync();

    expect(source, contains("_required(options, 'app')"));
    expect(source, contains("_required(options, 'fixture')"));
    expect(source, contains('actualBinaryChecksum'));
    expect(source, contains('actualFixtureChecksum'));
    expect(source, contains("'INCONCLUSIVE'"));
  });
}
