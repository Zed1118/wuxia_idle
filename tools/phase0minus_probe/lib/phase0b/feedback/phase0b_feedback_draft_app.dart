/// Phase 0B presentation feedback draft mode (`phase0b_feedback_draft`).
///
/// NOT FINAL: this is a keyboard-driven presentation draft for the base
/// HUD, in-memory loot display, and the mute audio-cue contract. It is
/// not connected to gameplay (a separate slice), production drops,
/// rewards, saves, or any Gate, and ships no real art or audio.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_state.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_view.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_loot.dart';

/// Non-Gate claim shown on screen and pinned by tests.
const feedbackDraftNonGateClaim = 'gate_eligible=false';

final class Phase0bFeedbackDraftApp extends StatefulWidget {
  const Phase0bFeedbackDraftApp({super.key});

  @override
  State<Phase0bFeedbackDraftApp> createState() =>
      _Phase0bFeedbackDraftAppState();
}

final class _Phase0bFeedbackDraftAppState
    extends State<Phase0bFeedbackDraftApp> {
  final FeedbackHudController _controller = FeedbackHudController();
  final FocusNode _focusNode = FocusNode(debugLabel: 'phase0b-feedback-draft');
  int _lootCycle = 0;
  FeedbackEndState _lastEndState = FeedbackEndState.none;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_restoreFocusAfterReset);
  }

  /// The end panel's reset button takes focus while shown; once the reset
  /// lands, hand keyboard focus back to the demo key listener.
  void _restoreFocusAfterReset() {
    final current = _controller.value.endState;
    if (current == FeedbackEndState.none &&
        _lastEndState != FeedbackEndState.none) {
      _focusNode.requestFocus();
    }
    _lastEndState = current;
  }

  /// Deterministic demo drops; labels are draft placeholders, not
  /// production items.
  static const _demoLoot = <(String, LootKind)>[
    ('silver taels', LootKind.currency),
    ('iron shard', LootKind.material),
    ('worn manual', LootKind.gear),
  ];

  @override
  void dispose() {
    _controller.removeListener(_restoreFocusAfterReset);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final FeedbackEvent? feedbackEvent = switch (event.logicalKey) {
      LogicalKeyboardKey.digit1 => const EnemyHit(heavy: false),
      LogicalKeyboardKey.digit2 => const EnemyHit(heavy: true),
      LogicalKeyboardKey.digit3 => const PlayerDamaged(0.18),
      LogicalKeyboardKey.digit4 => DangerPresented(_nextDanger()),
      LogicalKeyboardKey.digit5 => const DangerResolved(broken: true),
      LogicalKeyboardKey.digit6 => _nextBossPhase(),
      LogicalKeyboardKey.digit7 => _nextLoot(),
      LogicalKeyboardKey.digit8 => StylePresented(_nextStyle()),
      LogicalKeyboardKey.digit9 => const ResourceAdjusted(-0.2),
      LogicalKeyboardKey.digit0 => const ResourceAdjusted(0.2),
      LogicalKeyboardKey.keyV => const BattleConcluded(
        FeedbackEndState.victory,
      ),
      LogicalKeyboardKey.keyX => const BattleConcluded(FeedbackEndState.defeat),
      LogicalKeyboardKey.keyR => const BattleReset(),
      _ => null,
    };
    if (feedbackEvent == null) return;
    _controller.apply(feedbackEvent);
  }

  FeedbackDanger _nextDanger() => switch (_controller.value.danger) {
    FeedbackDanger.none => FeedbackDanger.telegraph,
    FeedbackDanger.telegraph => FeedbackDanger.imminent,
    FeedbackDanger.imminent => FeedbackDanger.none,
  };

  BossPhasePresented _nextBossPhase() {
    final state = _controller.value;
    return BossPhasePresented(
      phase: state.bossPhase % state.bossPhaseTotal + 1,
      total: state.bossPhaseTotal,
    );
  }

  LootPresented _nextLoot() {
    final (label, kind) = _demoLoot[_lootCycle % _demoLoot.length];
    _lootCycle += 1;
    return LootPresented(label: label, kind: kind);
  }

  FeedbackStyle _nextStyle() =>
      FeedbackStyle.values[(_controller.value.style.index + 1) %
          FeedbackStyle.values.length];

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
                  child: FeedbackHud(
                    state: state,
                    onReset: () => _controller.apply(const BattleReset()),
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 14,
                  child: Center(child: IgnorePointer(child: _DraftBanner())),
                ),
                const Positioned(
                  left: 18,
                  bottom: 18,
                  child: IgnorePointer(child: _KeyHelp()),
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
        'FEEDBACK DRAFT · NOT FINAL HUD / AUDIO / LOOT\n'
        '$feedbackDraftNonGateClaim · no saves · no real drops or rewards',
        style: TextStyle(color: Color(0xFFECE2CD), fontSize: 13),
      ),
    ),
  );
}

final class _KeyHelp extends StatelessWidget {
  const _KeyHelp();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(color: Color(0x99181916)),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        '1/2 hit · 3 hurt · 4 telegraph · 5 break · 6 phase · '
        '7 loot · 8 style · 9/0 qi · V win · X lose · R reset',
        style: TextStyle(color: Color(0xFFECE2CD), fontSize: 11),
      ),
    ),
  );
}
