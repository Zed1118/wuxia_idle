import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Windows runner measures the root production app and rejects old probe',
    () {
      final runner = File(
        'tools/route_c_gate/run_route_c_windows_profile.ps1',
      ).readAsStringSync();
      expect(runner, contains('wuxia_idle.exe'));
      expect(runner, contains('Profile/data/app.so'));
      expect(runner, contains(r'Get-FileHash -Algorithm SHA256 $AppPayload'));
      expect(runner, contains(r'& $Launcher @Arguments'));
      expect(runner, contains('phase0a_battle_profile'));
      expect(runner, contains('data/phase0a_debug_battle.yaml'));
      expect(runner, contains('sample-seconds=60'));
      expect(runner, contains('warmup-seconds=12'));
      expect(runner, contains('cooldown-seconds=30'));
      expect(runner, contains('native-content-viewport=true'));
      expect(runner, isNot(contains('phase0minus_probe.exe')));
      expect(runner, isNot(contains('probe_scenarios.yaml')));
      expect(runner, contains('GC_TELEMETRY_COLLECTED'));
      expect(runner, contains('sampled_frames -ge 3000'));
      expect(runner, contains('p99_total_span_ms -lt 16.6'));
      expect(runner, contains('valid_for_windows_physical_gate'));
      expect(runner, contains('windows_physical_attested'));
      expect(runner, contains(r'$env:SESSIONNAME'));
      expect(runner, contains(r'$ActualSessionName -ne "Console"'));
      expect(runner, isNot(contains('cpu_at_or_below_target')));
      expect(runner, isNot(contains('gpu_at_or_below_target')));
      expect(runner, isNot(contains('ram_matches_target')));
    },
  );

  test('Windows native shell treats requested dimensions as client size', () {
    final source = File('windows/runner/win32_window.cpp').readAsStringSync();

    expect(source, contains('WindowRectForClientSize'));
    expect(source, contains('AdjustWindowRectExForDpi'));
    expect(
      source,
      contains(
        'Scale(size.width, scale_factor), Scale(size.height, scale_factor)',
      ),
    );
    expect(
      source,
      contains('Scale(1280, scale_factor), Scale(720, scale_factor)'),
    );

    final entrypoint = File('windows/runner/main.cpp').readAsStringSync();
    expect(entrypoint, contains('ProfileViewportFromArguments'));
    expect(entrypoint, contains('--battle-profile-viewport='));
  });

  test(
    'matrix is exactly two viewports times three runs and remains fail closed',
    () {
      final matrix = File(
        'tools/route_c_gate/run_route_c_windows_matrix.ps1',
      ).readAsStringSync();
      expect(RegExp(r'-Repeat 3').allMatches(matrix), hasLength(2));
      expect(matrix, contains('-Viewport "1280x720"'));
      expect(matrix, contains('-Viewport "1440x900"'));
      expect(matrix, contains('route_c_gate_preflight.dart'));
      expect(matrix, contains('Profile/data/app.so'));
      expect(matrix, contains('app.so'));
      expect(matrix, contains('phase0a_debug_battle.yaml'));
      expect(matrix, contains('Copy-Item -Force'));
      expect(matrix, contains('SHA256SUMS.txt'));
    },
  );

  test('documented Windows host capture does not dirty the candidate tree', () {
    final ignore = File('.gitignore').readAsStringSync();
    final handoff = File(
      'docs/phase0/route-c-external-gate-preflight.md',
    ).readAsStringSync();

    expect(
      handoff,
      contains(r'-HostManifest .\windows_physical_gate_manifest.captured.json'),
    );
    expect(
      ignore.split('\n'),
      contains('/windows_physical_gate_manifest.captured.json'),
    );
  });

  test('preflight hashing supports the Windows matrix host', () {
    final source = File('tool/route_c_gate_preflight.dart').readAsStringSync();

    expect(source, contains('Platform.isWindows'));
    expect(source, contains("Process.run('certutil'"));
    expect(source, contains("'-hashfile'"));
    expect(source, contains("Process.run('shasum'"));
    expect(source, contains("File('\$windowsRoot/app.so')"));
    expect(
      source,
      isNot(contains('package/wuxia_idle.app/Contents/MacOS/wuxia_idle')),
    );
    expect(source, isNot(contains("File('\$windowsRoot/wuxia_idle.exe')")));
  });

  test('Route C preflight no longer requires six human sessions', () {
    final source = File('tool/route_c_gate_preflight.dart').readAsStringSync();
    final mainSource = source.substring(source.indexOf('Future<void> main'));
    final matrix = File(
      'tools/route_c_gate/run_route_c_windows_matrix.ps1',
    ).readAsStringSync();

    expect(mainSource, isNot(contains("options['human-dir']")));
    expect(mainSource, isNot(contains('validateHumanEvidence(')));
    expect(matrix, isNot(contains('Human Gate remains independent')));
  });

  test(
    'macOS runner measures the same root production app and raw contract',
    () {
      final runner = File(
        'tools/route_c_gate/run_route_c_macos_profile.sh',
      ).readAsStringSync();

      expect(runner, contains('wuxia_idle.app/Contents/MacOS/wuxia_idle'));
      expect(runner, contains('App.framework/Versions/A/App'));
      expect(runner, contains(r'shasum -a 256 "$app_payload"'));
      expect(runner, contains(r'caffeinate -dimsu "$launcher"'));
      expect(runner, contains('phase0a_battle_profile'));
      expect(runner, contains('data/phase0a_debug_battle.yaml'));
      expect(runner, contains('sample-seconds=60'));
      expect(runner, contains('warmup-seconds=12'));
      expect(runner, contains('cooldown-seconds=30'));
      expect(runner, contains('GC_TELEMETRY_COLLECTED'));
      expect(runner, contains('.sampled_frames >= 3000'));
      expect(runner, contains('.p99_total_span_ms < 16.6'));
      expect(runner, contains('Library/Containers/com.pen.wuxia.wuxiaIdle'));
      expect(runner, contains('cp -R "\$app_run_dir/." "\$run_dir/"'));
      expect(runner, contains('VISUAL_WINDOW_W="\$expected_width"'));
      expect(runner, contains('VISUAL_WINDOW_H="\$expected_height"'));
      expect(runner, contains('native-content-viewport=true'));
      expect(runner, isNot(contains('phase0minus_probe.app')));
    },
  );

  test('macOS matrix is exactly two viewports times three production runs', () {
    final matrix = File(
      'tools/route_c_gate/run_route_c_macos_matrix.sh',
    ).readAsStringSync();

    expect(matrix, contains('1280x720 3'));
    expect(matrix, contains('1440x900 3'));
    expect(matrix, contains('ROUTE_C_SKIP_BUILD=true'));
    expect(matrix, contains('App.framework/Versions/A/App'));
    expect(matrix, contains('app_aot_payload'));
    expect(matrix, contains('phase0a_debug_battle.yaml'));
    expect(matrix, contains('SHA256SUMS.txt'));
  });

  test(
    'macOS Profile can collect localhost GC telemetry without widening release',
    () {
      final profile = File(
        'macos/Runner/DebugProfile.entitlements',
      ).readAsStringSync();
      final release = File(
        'macos/Runner/Release.entitlements',
      ).readAsStringSync();

      expect(profile, contains('com.apple.security.network.client'));
      expect(profile, contains('com.apple.security.network.server'));
      expect(release, isNot(contains('com.apple.security.network.client')));
      expect(release, isNot(contains('com.apple.security.network.server')));
    },
  );

  test('macOS acceptance sizing pins every viewport to the main display', () {
    final window = File(
      'macos/Runner/MainFlutterWindow.swift',
    ).readAsStringSync();

    expect(window, contains('VISUAL_WINDOW_W'));
    expect(window, contains('NSScreen.screens.first ?? self.screen'));
    expect(window, isNot(contains('if let screen = NSScreen.main')));
    expect(window, isNot(contains('self.screen ?? NSScreen.screens.first')));
  });

  test(
    'production profiler closes the desktop window after evidence flush',
    () {
      final profiler = File(
        'lib/features/debug/application/battle_frame_profile.dart',
      ).readAsStringSync();

      expect(profiler, contains('await windowManager.close()'));
      expect(profiler, isNot(contains('SystemNavigator.pop()')));
      expect(
        profiler.indexOf('await _writeEvidence(config, summary)'),
        lessThan(profiler.indexOf('await windowManager.close()')),
      );
    },
  );
}
