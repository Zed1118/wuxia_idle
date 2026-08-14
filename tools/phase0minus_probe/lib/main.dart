import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/gameplay/combat_rules.dart';
import 'package:phase0minus_probe/gameplay/gameplay_game.dart';
import 'package:phase0minus_probe/gameplay/gameplay_replay_controller.dart';
import 'package:phase0minus_probe/human_gate/playtest_identity.dart';
import 'package:phase0minus_probe/human_gate/playtest_report.dart';
import 'package:phase0minus_probe/human_gate/readability_stimulus_app.dart';
import 'package:phase0minus_probe/phase0b/feedback/phase0b_feedback_draft_app.dart';
import 'package:phase0minus_probe/phase0b/joint/phase0b_joint_compare_app.dart';
import 'package:phase0minus_probe/phase0b/load/phase0b_art_load_app.dart';
import 'package:phase0minus_probe/phase0b/phase0b_art_gallery_app.dart';
import 'package:phase0minus_probe/phase0b/phase0b_runtime_app.dart';
import 'package:phase0minus_probe/phase0b/scroll/phase0b_scroll_observation_app.dart';
import 'package:phase0minus_probe/phase0b/scroll/phase0b_scroll_review_app.dart';
import 'package:phase0minus_probe/run/probe_run_controller.dart';
import 'package:phase0minus_probe/workload/probe_game.dart';
import 'package:window_manager/window_manager.dart';

const _tierDefine = String.fromEnvironment(
  'PROBE_TIER',
  defaultValue: 'stress_30',
);
const _viewportDefine = String.fromEnvironment(
  'PROBE_VIEWPORT',
  defaultValue: 'desktop_1280x720',
);
const _runIdDefine = String.fromEnvironment(
  'PROBE_RUN_ID',
  defaultValue: 'local-smoke',
);
const _durationScaleDefine = String.fromEnvironment(
  'PROBE_DURATION_SCALE',
  defaultValue: '1.0',
);
const _autoCloseDefine = String.fromEnvironment(
  'PROBE_AUTO_CLOSE',
  defaultValue: 'true',
);
const _outputRootDefine = String.fromEnvironment(
  'PROBE_OUTPUT_ROOT',
  defaultValue: 'build/results',
);
const _repositoryRootDefine = String.fromEnvironment(
  'PROBE_REPOSITORY_ROOT',
  defaultValue: '../..',
);
const _windowXDefine = String.fromEnvironment('PROBE_WINDOW_X');
const _windowYDefine = String.fromEnvironment('PROBE_WINDOW_Y');
const _modeDefine = String.fromEnvironment(
  'PROBE_MODE',
  defaultValue: 'benchmark',
);
const _buildCommitDefine = String.fromEnvironment(
  'PROBE_BUILD_COMMIT',
  defaultValue: 'uncommitted-local-build',
);
const _panoramaSha256Define = String.fromEnvironment(
  'PHASE0B_PANORAMA_SHA256',
  defaultValue: 'unverified-local-asset',
);
const _artLoadBackgroundSha256Define = String.fromEnvironment(
  'PHASE0B_ARTLOAD_BG_SHA256',
  defaultValue: 'unverified-local-asset',
);
const _artLoadFounderSha256Define = String.fromEnvironment(
  'PHASE0B_ARTLOAD_FOUNDER_SHA256',
  defaultValue: 'unverified-local-asset',
);
const _artLoadBanditSha256Define = String.fromEnvironment(
  'PHASE0B_ARTLOAD_BANDIT_SHA256',
  defaultValue: 'unverified-local-asset',
);
const _artLoadEliteSha256Define = String.fromEnvironment(
  'PHASE0B_ARTLOAD_ELITE_SHA256',
  defaultValue: 'unverified-local-asset',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final config = await ProbeConfig.load();
  final mode = _runtime('PROBE_MODE', _modeDefine);
  if (mode != 'benchmark' &&
      mode != 'playtest' &&
      mode != 'phase0a_replay' &&
      mode != 'readability' &&
      mode != 'phase0b_gallery' &&
      mode != 'phase0b_runtime' &&
      mode != 'phase0b_joint_compare' &&
      mode != 'phase0b_art_load' &&
      mode != 'phase0b_scroll_profile' &&
      mode != 'phase0b_scroll_review' &&
      mode != 'phase0b_feedback_draft') {
    throw ArgumentError.value(
      mode,
      'PROBE_MODE',
      'benchmark, playtest, phase0a_replay, readability, phase0b_gallery, '
          'phase0b_runtime, phase0b_joint_compare, phase0b_art_load, '
          'phase0b_scroll_profile, phase0b_scroll_review, or '
          'phase0b_feedback_draft',
    );
  }
  final viewport = config.viewport(_runtime('PROBE_VIEWPORT', _viewportDefine));
  final tier = config.tier(_runtime('PROBE_TIER', _tierDefine));
  final runId = _runtime('PROBE_RUN_ID', _runIdDefine);
  final durationScale = double.parse(
    _runtime('PROBE_DURATION_SCALE', _durationScaleDefine),
  );
  final autoClose = _runtime('PROBE_AUTO_CLOSE', _autoCloseDefine) == 'true';
  final outputRoot = _runtime('PROBE_OUTPUT_ROOT', _outputRootDefine);
  final repositoryRoot = _runtime(
    'PROBE_REPOSITORY_ROOT',
    _repositoryRootDefine,
  );
  final windowXText = _runtime('PROBE_WINDOW_X', _windowXDefine);
  final windowYText = _runtime('PROBE_WINDOW_Y', _windowYDefine);
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: Size(viewport.width, viewport.height),
      minimumSize: mode == 'benchmark' || mode == 'phase0a_replay'
          ? Size(viewport.width - 64, viewport.height - 64)
          : Size(viewport.width, viewport.height),
      maximumSize: Size(viewport.width + 100, viewport.height + 100),
      center: true,
      title: switch (mode) {
        'playtest' => 'Phase 0A Gameplay Greybox',
        'phase0a_replay' => 'Phase 0A Deterministic Replay',
        'readability' => 'Phase 0A Readability Stimuli',
        'phase0b_gallery' => 'Phase 0B Art Sample Gallery',
        'phase0b_runtime' => 'Phase 0B Pose Atlas Runtime',
        'phase0b_joint_compare' => 'Phase 0B Animation Route Compare',
        'phase0b_art_load' => 'Phase 0B Art Load Replay',
        'phase0b_scroll_profile' => 'Phase 0B Scrolling World Observation',
        'phase0b_scroll_review' => 'Phase 0B Scrolling World Review',
        'phase0b_feedback_draft' => 'Phase 0B Feedback Draft (NOT FINAL)',
        _ => 'Phase 0-minus Performance Probe',
      },
      titleBarStyle: TitleBarStyle.hidden,
    ),
    () async {
      await windowManager.show();
      await windowManager.setAlwaysOnTop(mode == 'phase0a_replay');
      if (windowXText.isNotEmpty && windowYText.isNotEmpty) {
        await windowManager.setPosition(
          Offset(double.parse(windowXText), double.parse(windowYText)),
        );
      }
      await windowManager.focus();
    },
  );
  final Widget app = switch (mode) {
    'playtest' => GameplayPlaytestApp(config: config, outputRoot: outputRoot),
    'readability' => const ReadabilityStimulusApp(),
    'phase0b_gallery' => const Phase0bArtGalleryApp(),
    'phase0b_runtime' => const Phase0bRuntimeApp(),
    'phase0b_joint_compare' => const Phase0bJointCompareApp(),
    'phase0b_scroll_review' => const Phase0bScrollReviewApp(),
    'phase0b_feedback_draft' => const Phase0bFeedbackDraftApp(),
    'phase0b_scroll_profile' => Phase0bScrollObservationApp(
      runId: runId,
      outputRoot: outputRoot,
      durationScale: durationScale,
      autoClose: autoClose,
      viewportId: viewport.id,
      expectedWidth: viewport.width,
      expectedHeight: viewport.height,
      buildCommit: _runtime('PROBE_BUILD_COMMIT', _buildCommitDefine),
      panoramaSha256: _runtime(
        'PHASE0B_PANORAMA_SHA256',
        _panoramaSha256Define,
      ),
    ),
    'phase0b_art_load' => Phase0bArtLoadApp(
      runId: runId,
      outputRoot: outputRoot,
      durationScale: durationScale,
      autoClose: autoClose,
      viewportId: viewport.id,
      expectedWidth: viewport.width,
      expectedHeight: viewport.height,
      buildCommit: _runtime('PROBE_BUILD_COMMIT', _buildCommitDefine),
      assetSha256: {
        'background': _runtime(
          'PHASE0B_ARTLOAD_BG_SHA256',
          _artLoadBackgroundSha256Define,
        ),
        'founder': _runtime(
          'PHASE0B_ARTLOAD_FOUNDER_SHA256',
          _artLoadFounderSha256Define,
        ),
        'bandit': _runtime(
          'PHASE0B_ARTLOAD_BANDIT_SHA256',
          _artLoadBanditSha256Define,
        ),
        'elite': _runtime(
          'PHASE0B_ARTLOAD_ELITE_SHA256',
          _artLoadEliteSha256Define,
        ),
      },
    ),
    'phase0a_replay' => GameplayReplayApp(
      config: config,
      viewport: viewport,
      runId: runId,
      durationScale: durationScale,
      autoClose: autoClose,
      outputRoot: '$outputRoot/phase0a-replays',
      repositoryRoot: repositoryRoot,
    ),
    _ => ProbeApp(
      config: config,
      tier: tier,
      viewport: viewport,
      runId: runId,
      durationScale: durationScale,
      autoClose: autoClose,
      outputRoot: outputRoot,
      repositoryRoot: repositoryRoot,
    ),
  };
  runApp(app);
}

String _runtime(String key, String compileTimeValue) =>
    Platform.environment[key] ?? compileTimeValue;

final class ProbeApp extends StatefulWidget {
  const ProbeApp({
    required this.config,
    required this.tier,
    required this.viewport,
    required this.runId,
    required this.durationScale,
    required this.autoClose,
    required this.outputRoot,
    required this.repositoryRoot,
    super.key,
  });

  final ProbeConfig config;
  final ProbeTier tier;
  final ProbeViewport viewport;
  final String runId;
  final double durationScale;
  final bool autoClose;
  final String outputRoot;
  final String repositoryRoot;

  @override
  State<ProbeApp> createState() => _ProbeAppState();
}

final class _ProbeAppState extends State<ProbeApp> {
  late final ProbeGame game = ProbeGame(
    config: widget.config,
    tier: widget.tier,
  );
  late final ProbeRunController controller = ProbeRunController(
    game: game,
    config: widget.config,
    tier: widget.tier,
    viewport: widget.viewport,
    runId: widget.runId,
    durationScale: widget.durationScale,
    autoClose: widget.autoClose,
    outputRoot: widget.outputRoot,
    repositoryRoot: widget.repositoryRoot,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_calibrateViewportAndStart()),
    );
  }

  Future<void> _calibrateViewportAndStart() async {
    final calibrated = await _calibrateLogicalViewport(
      View.of(context),
      widget.viewport,
    );
    if (!mounted) return;
    if (!calibrated) {
      debugPrint('PROBE_VIEWPORT_CALIBRATION_FAIL ${widget.viewport.id}');
      await windowManager.close();
      return;
    }
    await controller.start();
  }

  @override
  void dispose() {
    controller.dispose();
    game.hud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: GameWidget<ProbeGame>(
        game: game,
        initialActiveOverlays: const ['probeHud'],
        overlayBuilderMap: {
          'probeHud': (context, game) => ProbeHud(game: game),
        },
      ),
    ),
  );
}

final class ProbeHud extends StatelessWidget {
  const ProbeHud({required this.game, super.key});

  final ProbeGame game;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ValueListenableBuilder<ProbeHudState>(
      valueListenable: game.hud,
      builder: (context, state, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Meter(value: state.health, color: const Color(0xff8a332e)),
              const SizedBox(height: 6),
              _Meter(value: state.energy, color: const Color(0xff3f6159)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Cooldown(value: state.cooldownA),
                  const SizedBox(width: 8),
                  _Cooldown(value: state.cooldownB),
                  const SizedBox(width: 12),
                  DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xaaeee6d2)),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${state.tier} | enemies=${state.enemyCount}',
                        style: const TextStyle(color: Color(0xff252d29)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _Meter extends StatelessWidget {
  const _Meter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: 10,
      color: color,
      backgroundColor: const Color(0x55252d29),
    ),
  );
}

final class _Cooldown extends StatelessWidget {
  const _Cooldown({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 42,
    child: CircularProgressIndicator(
      value: value,
      strokeWidth: 4,
      color: const Color(0xff3f6159),
      backgroundColor: const Color(0x55252d29),
    ),
  );
}

final class GameplayReplayApp extends StatefulWidget {
  const GameplayReplayApp({
    required this.config,
    required this.viewport,
    required this.runId,
    required this.durationScale,
    required this.autoClose,
    required this.outputRoot,
    required this.repositoryRoot,
    super.key,
  });

  final ProbeConfig config;
  final ProbeViewport viewport;
  final String runId;
  final double durationScale;
  final bool autoClose;
  final String outputRoot;
  final String repositoryRoot;

  @override
  State<GameplayReplayApp> createState() => _GameplayReplayAppState();
}

final class _GameplayReplayAppState extends State<GameplayReplayApp> {
  late final GameplayGame game = GameplayGame(
    config: widget.config,
    deterministicReplay: true,
  );
  late final GameplayReplayController controller = GameplayReplayController(
    game: game,
    config: widget.config,
    viewport: widget.viewport,
    runId: widget.runId,
    durationScale: widget.durationScale,
    autoClose: widget.autoClose,
    outputRoot: widget.outputRoot,
    repositoryRoot: widget.repositoryRoot,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_calibrateViewportAndStart()),
    );
  }

  Future<void> _calibrateViewportAndStart() async {
    final calibrated = await _calibrateLogicalViewport(
      View.of(context),
      widget.viewport,
    );
    if (!mounted) return;
    if (!calibrated) {
      debugPrint('PHASE0A_VIEWPORT_CALIBRATION_FAIL ${widget.viewport.id}');
      await windowManager.close();
      return;
    }
    await controller.start();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: GameWidget<GameplayGame>(
        game: game,
        initialActiveOverlays: const ['gameplayHud'],
        overlayBuilderMap: {
          'gameplayHud': (context, game) => GameplayHud(game: game),
        },
      ),
    ),
  );
}

Future<bool> _calibrateLogicalViewport(
  ui.FlutterView view,
  ProbeViewport viewport,
) async {
  var consecutiveMatches = 0;
  for (var attempt = 1; attempt <= 20; attempt++) {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final actual = view.physicalSize / view.devicePixelRatio;
    final widthDelta = viewport.width - actual.width;
    final heightDelta = viewport.height - actual.height;
    final matches = widthDelta.abs() < 0.5 && heightDelta.abs() < 0.5;
    debugPrint(
      'PROBE_VIEWPORT_CALIBRATION attempt=$attempt '
      'actual=${actual.width}x${actual.height} match=$matches',
    );
    if (matches) {
      consecutiveMatches++;
      if (consecutiveMatches >= 3) return true;
      continue;
    }
    consecutiveMatches = 0;
    final outer = await windowManager.getSize();
    await windowManager.setSize(
      Size(outer.width + widthDelta, outer.height + heightDelta),
    );
  }
  return false;
}

final class GameplayPlaytestApp extends StatefulWidget {
  const GameplayPlaytestApp({
    required this.config,
    required this.outputRoot,
    super.key,
  });

  final ProbeConfig config;
  final String outputRoot;

  @override
  State<GameplayPlaytestApp> createState() => _GameplayPlaytestAppState();
}

final class _GameplayPlaytestAppState extends State<GameplayPlaytestApp> {
  Future<void> _reportWriteQueue = Future<void>.value();
  late final PlaytestIdentity _identity = PlaytestIdentity.fromEnvironment();
  late final GameplayGame game = GameplayGame(
    config: widget.config,
    onSessionEnded: (report) {
      _reportWriteQueue = _reportWriteQueue.then(
        (_) => _writeReport(Map<String, Object?>.from(report)),
      );
      unawaited(_reportWriteQueue);
    },
  );
  final FocusNode _focusNode = FocusNode(debugLabel: 'phase0a-playtest');

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) game.clearInput();
  }

  @override
  void dispose() {
    game.clearInput();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _writeReport(Map<String, Object?> report) async {
    final directory = Directory('${widget.outputRoot}/phase0a-playtests');
    await directory.create(recursive: true);
    final sessionSerial = report['session_serial'] as int? ?? 0;
    final runId =
        '${_identity.sessionId}-${_identity.participantId}-'
        'slot${_identity.slot.toString().padLeft(2, '0')}-'
        'run${sessionSerial.toString().padLeft(2, '0')}';
    final file = File('${directory.path}/$runId.json');
    final structuredReport = <String, Object?>{
      'schema_version': phase0aHumanGateSchemaVersion,
      ..._identity.toJson(),
      'scenario_checksum': widget.config.checksum,
      'build_commit': _buildCommitDefine,
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
      'logical_viewport': {'width': game.size.x, 'height': game.size.y},
      'run_id': runId,
      ...report,
    };
    final validation = validatePlaytestReport(structuredReport);
    if (!validation.isValid) {
      throw StateError(
        'Refusing invalid playtest report: ${validation.errors}',
      );
    }
    await writeJsonAtomically(file, structuredReport);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerHover: (event) => game.updatePointer(
          Vector2(event.localPosition.dx, event.localPosition.dy),
        ),
        onPointerMove: (event) => game.updatePointer(
          Vector2(event.localPosition.dx, event.localPosition.dy),
        ),
        onPointerDown: (event) {
          game.updatePointer(
            Vector2(event.localPosition.dx, event.localPosition.dy),
          );
          if (event.buttons == 1) game.setPrimaryHeld(true);
          _focusNode.requestFocus();
        },
        onPointerUp: (_) => game.setPrimaryHeld(false),
        onPointerCancel: (_) => game.setPrimaryHeld(false),
        child: GameWidget<GameplayGame>(
          game: game,
          focusNode: _focusNode,
          autofocus: true,
          initialActiveOverlays: const ['gameplayHud'],
          overlayBuilderMap: {
            'gameplayHud': (context, game) => GameplayHud(game: game),
          },
        ),
      ),
    ),
  );
}

final class GameplayHud extends StatelessWidget {
  const GameplayHud({required this.game, super.key});

  final GameplayGame game;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<GameplayHudState>(
    valueListenable: game.hud,
    builder: (context, state, _) => Stack(
      children: [
        IgnorePointer(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xcceee6d2)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 310,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PHASE 0A  |  WASD · LMB · SPACE · Q · R',
                              style: TextStyle(
                                color: Color(0xff252d29),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _LabeledMeter(
                              label: 'HP',
                              value: state.health,
                              color: const Color(0xff8a332e),
                            ),
                            const SizedBox(height: 5),
                            _LabeledMeter(
                              label: 'QI',
                              value: state.qi,
                              color: const Color(0xff3f6159),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Wave ${state.wave}/3  ·  enemies ${state.enemyCount}  ·  '
                              'Space ${(state.movementArtCooldown * 3.2).toStringAsFixed(1)}s  ·  '
                              'Q ${(state.gatherCooldown * 6.5).toStringAsFixed(1)}s',
                              style: const TextStyle(color: Color(0xff252d29)),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              state.message,
                              style: const TextStyle(color: Color(0xff672d2a)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(color: Color(0xaa252d29)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'kills ${state.counters['kills'] ?? 0}  ·  '
                          'chain ${state.counters['maximum_chain'] ?? 0}  ·  '
                          'breaks ${state.counters['break_successes'] ?? 0}',
                          style: const TextStyle(color: Color(0xffeee6d2)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state.phase == GameplayPhase.victory ||
            state.phase == GameplayPhase.defeat)
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff672d2a),
                foregroundColor: const Color(0xffeee6d2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
              ),
              onPressed: game.requestReplay,
              child: const Text('PLAY AGAIN'),
            ),
          ),
      ],
    ),
  );
}

final class _LabeledMeter extends StatelessWidget {
  const _LabeledMeter({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 24,
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
      Expanded(
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 9,
          color: color,
          backgroundColor: const Color(0x44252d29),
        ),
      ),
    ],
  );
}
