import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/config/probe_config.dart';

void main() {
  late String source;
  late ProbeConfig config;

  setUpAll(() {
    source = File('assets/probe_scenarios.yaml').readAsStringSync();
    config = ProbeConfig.parse(source);
  });

  test('scenario schema has the fixed three tiers and two viewports', () {
    expect(config.schemaVersion, 1);
    expect(config.fixedSeed, 20260812);
    expect(config.tier('baseline_10').totalEnemies, 10);
    expect(config.tier('target_20_plus_1').normalEnemies, 20);
    expect(config.tier('target_20_plus_1').eliteEnemies, 1);
    expect(config.tier('stress_30').totalEnemies, 30);
    expect(config.viewport('desktop_1280x720').width, 1280);
    expect(config.viewport('desktop_1280x720').height, 720);
    expect(config.viewport('desktop_1440x900').width, 1440);
    expect(config.viewport('desktop_1440x900').height, 900);
  });

  test('scenario checksum is the SHA-256 of exact source bytes', () {
    expect(config.checksum, sha256.convert(utf8.encode(source)).toString());
  });

  test('invalid or incomplete schema is rejected', () {
    expect(() => ProbeConfig.parse('schema_version: 2'), throwsFormatException);
    expect(() => ProbeConfig.parse('- not_a_map'), throwsFormatException);
  });
}
