import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hostScript = File(
    '${Directory.current.path}/scripts/host_phase0a_human_session_macos.sh',
  );

  test('frozen schedule balances cohort and AB/BA order', () async {
    final result = await Process.run('zsh', [
      hostScript.path,
      '--print-schedule',
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect((result.stdout as String).trim().split('\n'), const [
      'P01 idle AB',
      'P02 idle BA',
      'P03 arpg AB',
      'P04 arpg BA',
      'P05 mixed AB',
      'P06 mixed BA',
    ]);
  });

  test('host runs AB/BA serially and rejects duplicate participant', () async {
    final package = await _fakePackage();
    addTearDown(() => package.delete(recursive: true));

    final abTrace = File('${package.path}/ab.trace');
    final ab = await _runHost(hostScript, package, 'P01', abTrace);
    expect(ab.exitCode, 0, reason: '${ab.stdout}\n${ab.stderr}');
    expect(await abTrace.readAsLines(), const [
      'comparison',
      'playtest',
      'readability',
    ]);
    expect(
      File('${package.path}/results/sessions/P01/session.state').existsSync(),
      isTrue,
    );
    final state = await File(
      '${package.path}/results/sessions/P01/session.state',
    ).readAsString();
    expect(
      state,
      matches(RegExp(r'session_id=phase0a-p01-[0-9]{8}t[0-9]{6}z')),
    );
    expect(state, contains('status=COMPLETE'));
    expect(
      await File(
        '${package.path}/results/sessions/P01/execution.events',
      ).readAsLines(),
      const [
        'comparison_complete',
        'gameplay_complete',
        'readability_complete',
      ],
    );

    final duplicate = await _runHost(hostScript, package, 'P01', abTrace);
    expect(duplicate.exitCode, 68);
    expect(duplicate.stderr, contains('DUPLICATE_PARTICIPANT'));

    final baTrace = File('${package.path}/ba.trace');
    final ba = await _runHost(hostScript, package, 'P02', baTrace);
    expect(ba.exitCode, 0, reason: '${ba.stdout}\n${ba.stderr}');
    expect(await baTrace.readAsLines(), const [
      'playtest',
      'comparison',
      'readability',
    ]);
  });

  test('host rejects a mutated frozen document before launch', () async {
    final package = await _fakePackage();
    addTearDown(() => package.delete(recursive: true));
    await File('${package.path}/键位卡.md').writeAsString('mutated');

    final result = await _runHost(
      hostScript,
      package,
      'P03',
      File('${package.path}/mutated.trace'),
    );
    expect(result.exitCode, 66);
    expect(result.stderr, contains('HASH_MISMATCH:keycard_checksum'));
  });
}

Future<ProcessResult> _runHost(
  File hostScript,
  Directory package,
  String participant,
  File trace,
) => Process.run(
  'zsh',
  [hostScript.path, participant],
  environment: {
    ...Platform.environment,
    'PHASE0A_PACKAGE_DIR': package.path,
    'PHASE0A_TEST_TRACE': trace.path,
  },
);

Future<Directory> _fakePackage() async {
  final root = await Directory.systemTemp.createTemp('phase0a-host-test-');
  final comparison = File(
    '${root.path}/挂机武侠_当前点招对照.app/Contents/MacOS/wuxia_idle',
  );
  final gameplay = File(
    '${root.path}/挂机武侠_Phase0A.app/Contents/MacOS/phase0minus_probe',
  );
  await comparison.parent.create(recursive: true);
  await gameplay.parent.create(recursive: true);
  const traceScript = '''#!/bin/zsh
set -euo pipefail
echo "\${PROBE_MODE:-comparison}" >> "\$PHASE0A_TEST_TRACE"
''';
  await comparison.writeAsString(traceScript);
  await gameplay.writeAsString(traceScript);
  await Process.run('chmod', ['+x', comparison.path, gameplay.path]);
  final gameplayAssets = Directory(
    '${root.path}/挂机武侠_Phase0A.app/Contents/Frameworks/'
    'App.framework/Resources/flutter_assets',
  );
  await Directory(
    '${gameplayAssets.path}/assets/readability',
  ).create(recursive: true);
  final embeddedAssetManifest = File('${gameplayAssets.path}/AssetManifest.bin')
    ..writeAsStringSync('asset-manifest');
  final embeddedScenario = File(
    '${gameplayAssets.path}/assets/probe_scenarios.yaml',
  )..writeAsStringSync('scenario');
  final embeddedReadabilityManifest = File(
    '${gameplayAssets.path}/assets/readability/manifest.json',
  )..writeAsStringSync('{}');
  final embeddedFrame = File(
    '${gameplayAssets.path}/assets/readability/frame.png',
  )..writeAsStringSync('embedded-frame');

  final keycard = File('${root.path}/键位卡.md')..writeAsStringSync('keycard');
  final protocol = File('${root.path}/试玩记录.md')..writeAsStringSync('protocol');
  final comparisonProtocol = File('${root.path}/对照说明.md')
    ..writeAsStringSync('comparison');
  final schedule = File('${root.path}/匿名排期.json')..writeAsStringSync('{}');
  final questionnaire = File('${root.path}/问卷模板.json')
    ..writeAsStringSync(
      File(
        '${Directory.current.path}/config/phase0a_human_session.template.json',
      ).readAsStringSync(),
    );
  final packagedHost = File('${root.path}/主持试玩.command')
    ..writeAsStringSync(hostScriptSource);
  final validator = File('${root.path}/phase0a_human_gate')
    ..writeAsStringSync('validator');
  final readability = Directory('${root.path}/可读性五帧');
  await readability.create(recursive: true);
  final stimulus = File('${readability.path}/frame.png')
    ..writeAsStringSync('png');
  final readabilityManifest = File('${readability.path}/manifest.json')
    ..writeAsStringSync('{}');
  final checksumFile = File('${readability.path}/checksums.sha256');
  await checksumFile.writeAsString('${_sha(stimulus)}  frame.png\n');

  File('${root.path}/MANIFEST.txt').writeAsStringSync(
    [
      'commit=fake-clean-commit',
      'comparison_binary_checksum=${_sha(comparison)}',
      'gameplay_binary_checksum=${_sha(gameplay)}',
      'embedded_asset_manifest_checksum=${_sha(embeddedAssetManifest)}',
      'embedded_scenario_checksum=${_sha(embeddedScenario)}',
      'embedded_readability_manifest_checksum=${_sha(embeddedReadabilityManifest)}',
      'embedded_readability_frames_checksum=${_frameListSha([embeddedFrame])}',
      'keycard_checksum=${_sha(keycard)}',
      'protocol_checksum=${_sha(protocol)}',
      'comparison_protocol_checksum=${_sha(comparisonProtocol)}',
      'schedule_checksum=${_sha(schedule)}',
      'questionnaire_template_checksum=${_sha(questionnaire)}',
      'host_checksum=${_sha(packagedHost)}',
      'validator_checksum=${_sha(validator)}',
      'readability_manifest_checksum=${_sha(readabilityManifest)}',
      'readability_checksums_checksum=${_sha(checksumFile)}',
    ].join('\n'),
  );
  return root;
}

String get hostScriptSource => File(
  '${Directory.current.path}/scripts/host_phase0a_human_session_macos.sh',
).readAsStringSync();

String _sha(File file) => sha256.convert(file.readAsBytesSync()).toString();

String _frameListSha(List<File> frames) {
  final lines = frames
      .map((frame) => '${_sha(frame)}  ${frame.uri.pathSegments.last}\n')
      .join();
  return sha256.convert(lines.codeUnits).toString();
}
