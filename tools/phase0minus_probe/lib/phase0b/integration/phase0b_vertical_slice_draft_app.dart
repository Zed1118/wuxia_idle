/// Phase 0B vertical slice draft mode (`phase0b_vertical_slice_draft`).
///
/// NOT FINAL: this is the first engineering integration slice — a real
/// [EncounterOrchestrator] run drives the real [FeedbackHudController] HUD
/// through the composition-layer bridge. It is not connected to production
/// battle, drops, rewards, saves, art, or audio, writes no Gate evidence,
/// and must never replace any Phase 0−/0A/0B observation matrix.
library;

import 'dart:async' as async;

import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phase0minus_probe/phase0b/encounter/encounter_orchestrator.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_cues.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_state.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_view.dart';
import 'package:phase0minus_probe/phase0b/integration/encounter_feedback_adapter.dart';
import 'package:phase0minus_probe/phase0b/playable/style_profiles.dart';

/// Non-Gate claim shown on screen and pinned by tests.
const verticalSliceDraftNonGateClaim = 'gate_eligible=false';

/// NOT FINAL — Phase 0B vertical slice draft entry metadata.
final class Phase0bVerticalSliceDraftMetadata {
  Phase0bVerticalSliceDraftMetadata._();

  static const modeId = 'phase0b_vertical_slice_draft';
  static const gateEligible = false;
  static const claim = 'phase0b_vertical_slice_draft_not_final_review_only';
}

/// The fixed draft scenario. Rebuilt verbatim on every reset so a run is
/// deterministic for a fixed input sequence.
EncounterOrchestrator buildVerticalSliceScenario() => EncounterOrchestrator(
  seed: 20260814,
  style: DraftStyleKind.surgeCurrent,
  heroStart: Vector2(1600, 500),
  groups: const [
    EncounterGroupSetup(id: 0, count: 6, seed: 20260816, cameraLeft: 1400),
    EncounterGroupSetup(
      id: 1,
      count: 6,
      seed: 20260817,
      cameraLeft: 1500,
      activateAt: 12,
    ),
  ],
  bossSpawn: Vector2(1900, 500),
);

final class Phase0bVerticalSliceDraftApp extends StatefulWidget {
  const Phase0bVerticalSliceDraftApp({super.key});

  @override
  State<Phase0bVerticalSliceDraftApp> createState() =>
      _Phase0bVerticalSliceDraftAppState();
}

final class _Phase0bVerticalSliceDraftAppState
    extends State<Phase0bVerticalSliceDraftApp> {
  static const double _dt = 1 / 30;
  static const double _moveStep = 48;

  late EncounterOrchestrator _orchestrator;
  late FeedbackHudController _controller;
  late EncounterFeedbackBridge _bridge;
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'phase0b-vertical-slice-draft',
  );
  async.Timer? _timer;
  double _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _buildRun();
    _timer = async.Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _tick(),
    );
  }

  /// Fresh orchestrator + controller + mute cue sink + bridge. This is the
  /// reset path: same seed, empty HUD, empty cue counter, empty loot feed.
  void _buildRun() {
    _orchestrator = buildVerticalSliceScenario();
    _controller = FeedbackHudController(cueSink: SilentFeedbackCueSink());
    _bridge = EncounterFeedbackBridge(
      orchestrator: _orchestrator,
      controller: _controller,
    );
    // Drain EncounterStarted so the style plaque matches the run.
    _bridge.sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _tick() {
    if (_orchestrator.battleConcluded) return;
    setState(() {
      _orchestrator.advance(_dt);
      _elapsed += _dt;
      _bridge.sync();
    });
  }

  void _reset() {
    _controller.dispose();
    setState(() {
      _elapsed = 0;
      _buildRun();
    });
    // The end panel's reset button holds focus while shown; hand keyboard
    // focus back to the run key listener after the reset lands.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _reset();
      return;
    }
    // Terminal input lock: only reset is accepted once the run concludes.
    if (_orchestrator.battleConcluded) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyA:
      case LogicalKeyboardKey.arrowLeft:
        _orchestrator.moveHeroBy(-_moveStep);
      case LogicalKeyboardKey.keyD:
      case LogicalKeyboardKey.arrowRight:
        _orchestrator.moveHeroBy(_moveStep);
      case LogicalKeyboardKey.keyQ:
        _orchestrator.castGather();
      case LogicalKeyboardKey.keyE:
        _orchestrator.castClear();
      case LogicalKeyboardKey.digit1:
        _orchestrator.setStyle(DraftStyleKind.surgeCurrent);
      case LogicalKeyboardKey.digit2:
        _orchestrator.setStyle(DraftStyleKind.sinisterDraft);
      default:
        return;
    }
    setState(_bridge.sync);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF171815),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: ValueListenableBuilder<FeedbackHudState>(
          valueListenable: _controller,
          builder: (context, state, _) => SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FeedbackHud(state: state, onReset: _reset),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 14,
                  child: Center(child: IgnorePointer(child: _DraftBanner())),
                ),
                Positioned(
                  left: 18,
                  bottom: 18,
                  child: IgnorePointer(child: _KeyHelp(elapsed: _elapsed)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

final class _DraftBanner extends StatelessWidget {
  const _DraftBanner();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(color: Color(0xD9181916)),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        'VERTICAL SLICE DRAFT · NOT FINAL ENCOUNTER × FEEDBACK / NON-GATE\n'
        '$verticalSliceDraftNonGateClaim · no saves · '
        'no real drops or rewards · memory-only loot',
        style: TextStyle(color: Color(0xFFECE2CD), fontSize: 13),
      ),
    ),
  );
}

final class _KeyHelp extends StatelessWidget {
  const _KeyHelp({required this.elapsed});

  final double elapsed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: Color(0x99181916)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        't=${elapsed.toStringAsFixed(1)}s\n'
        'A/D or ←/→ move · Q gather · E clear · 1/2 style · R reset',
        style: const TextStyle(color: Color(0xFFECE2CD), fontSize: 11),
      ),
    ),
  );
}
