import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/run/probe_run_controller.dart';
import 'package:phase0minus_probe/workload/probe_game.dart';
import 'package:window_manager/window_manager.dart';

const _tierId = String.fromEnvironment('PROBE_TIER', defaultValue: 'stress_30');
const _viewportId = String.fromEnvironment(
  'PROBE_VIEWPORT',
  defaultValue: 'desktop_1280x720',
);
const _runId = String.fromEnvironment(
  'PROBE_RUN_ID',
  defaultValue: 'local-smoke',
);
const _durationScaleText = String.fromEnvironment(
  'PROBE_DURATION_SCALE',
  defaultValue: '1.0',
);
const _autoCloseText = String.fromEnvironment(
  'PROBE_AUTO_CLOSE',
  defaultValue: 'true',
);
const _outputRoot = String.fromEnvironment(
  'PROBE_OUTPUT_ROOT',
  defaultValue: 'build/results',
);
const _repositoryRoot = String.fromEnvironment(
  'PROBE_REPOSITORY_ROOT',
  defaultValue: '../..',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final config = await ProbeConfig.load();
  final viewport = config.viewport(_viewportId);
  final tier = config.tier(_tierId);
  final durationScale = double.parse(_durationScaleText);
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: Size(viewport.width, viewport.height),
      minimumSize: Size(viewport.width, viewport.height),
      maximumSize: Size(viewport.width, viewport.height),
      center: true,
      title: 'Phase 0-minus Performance Probe',
      titleBarStyle: TitleBarStyle.hidden,
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );
  runApp(
    ProbeApp(
      config: config,
      tier: tier,
      viewport: viewport,
      runId: _runId,
      durationScale: durationScale,
      autoClose: _autoCloseText == 'true',
      outputRoot: _outputRoot,
      repositoryRoot: _repositoryRoot,
    ),
  );
}

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
    controller.start();
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
