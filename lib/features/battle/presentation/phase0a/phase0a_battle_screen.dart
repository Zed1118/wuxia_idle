import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../shared/audio/audio_assets.dart';
import '../../../../shared/audio/sound_manager.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../../application/phase0a/phase0a_player_input_adapter.dart';
import '../../application/phase0a/phase0a_numeric_skill_binding.dart';
import '../../application/phase0a/phase0a_wave_battle_flow.dart';
import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import '../hp_bar.dart';
import 'phase0a_battle_controller.dart';
import 'phase0a_presentation_tokens.dart';
import 'phase0a_sfx.dart';
import 'phase0a_skill_seals.dart';
import 'phase0a_stage.dart';
import 'phase0a_vfx_controller.dart';
import 'phase0a_visual_roster.dart';

final class Phase0aBattleScreen extends StatefulWidget {
  const Phase0aBattleScreen({
    super.key,
    required this.controller,
    this.autoStep = true,
    this.feedbackHoldSeconds = Phase0aPresentationTokens.feedbackHoldSeconds,
    this.retryFlowBuilder,
    this.numericSkillBindings = const Phase0aNumericSkillBindings.empty(),
  }) : assert(feedbackHoldSeconds > 0);

  final Phase0aBattleController controller;
  final bool autoStep;
  final double feedbackHoldSeconds;

  /// 终局「再战」的新 flow 装配器;为 null 时终局不出现重试入口
  /// (静态验收路由等纯展示场景保持只读)。
  final Future<Phase0aWaveBattleFlow> Function()? retryFlowBuilder;

  final Phase0aNumericSkillBindings numericSkillBindings;

  @override
  State<Phase0aBattleScreen> createState() => _Phase0aBattleScreenState();
}

class _Phase0aBattleScreenState extends State<Phase0aBattleScreen>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final Ticker _ticker;
  Duration? _lastElapsed;
  double _accumulatorSeconds = 0;
  final List<_HeldFeedback> _heldFeedback = <_HeldFeedback>[];
  final Map<String, double> _hitFlashRemaining = <String, double>{};
  final Map<String, double> _hpEmphasisRemaining = <String, double>{};
  bool _retryInFlight = false;
  bool _primaryAttackHeld = false;
  ArenaVector? _pointerAimDirection;

  /// Esc 暂停态(0C):暂停期间帧回调零推进(不记性能样本),
  /// 键鼠指令均不受理;再按 Esc 恢复。
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'phase0a-battle-input');
    widget.controller.addListener(_refresh);
    _ticker = createTicker(_onFrame)..start();
  }

  @override
  void didUpdateWidget(covariant Phase0aBattleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
    _lastElapsed = null;
    _accumulatorSeconds = 0;
    _heldFeedback.clear();
    _hitFlashRemaining.clear();
    _hpEmphasisRemaining.clear();
    _paused = false;
    _primaryAttackHeld = false;
    _pointerAimDirection = null;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _acceptsBattleInput =>
      !_paused && widget.controller.outcome == Phase0aBattleOutcome.ongoing;

  ArenaVector _pointerAim(Offset localPosition, Phase0aStage stage) {
    final player = widget.controller.state.player;
    final delta = stage.screenToWorld(localPosition) - player.position;
    return delta.lengthSquared > 0 ? delta.normalized() : player.facing;
  }

  void _enqueuePointerAttack() {
    final aim = _pointerAimDirection;
    if (!_acceptsBattleInput || aim == null) return;
    widget.controller.enqueue(
      Phase0aPlayerCommand(attack: true, attackAimDirection: aim),
    );
  }

  void _onStagePointerDown(PointerDownEvent event, Phase0aStage stage) {
    if ((event.buttons & kPrimaryMouseButton) == 0 || !_acceptsBattleInput) {
      return;
    }
    _primaryAttackHeld = true;
    _pointerAimDirection = _pointerAim(event.localPosition, stage);
    _enqueuePointerAttack();
    _focusNode.requestFocus();
  }

  void _onStagePointerMove(PointerMoveEvent event, Phase0aStage stage) {
    if (!_primaryAttackHeld ||
        (event.buttons & kPrimaryMouseButton) == 0 ||
        !_acceptsBattleInput) {
      return;
    }
    _pointerAimDirection = _pointerAim(event.localPosition, stage);
  }

  void _stopPointerAttack() {
    _primaryAttackHeld = false;
    _pointerAimDirection = null;
  }

  void _refresh() {
    if (widget.controller.lastEvents.isNotEmpty) {
      final playerId = widget.controller.state.player.id;
      for (final event in widget.controller.lastEvents) {
        final sfxAsset = phase0aSfxAssetForEvent(event, playerId: playerId);
        if (sfxAsset != null) {
          SoundManager.instance.playSfxPath(sfxAsset);
        }
      }
    }
    if (widget.controller.feedback.isNotEmpty) {
      for (final entry in widget.controller.feedback) {
        if (entry.kind == Phase0aVfxKind.damagePopup &&
            entry.targetId != null) {
          _hitFlashRemaining[entry.targetId!] =
              Phase0aPresentationTokens.hitFlashSeconds;
          _hpEmphasisRemaining[entry.targetId!] =
              Phase0aPresentationTokens.hpEmphasisSeconds;
        }
        if (_isAttackFeedback(entry.kind)) {
          _heldFeedback.removeWhere(
            (held) => _isAttackFeedback(held.entry.kind),
          );
        } else if (_isSingletonFeedback(entry.kind)) {
          _heldFeedback.removeWhere((held) => held.entry.kind == entry.kind);
        }
        _heldFeedback.add(_HeldFeedback(entry, widget.feedbackHoldSeconds));
      }
      final overflow =
          _heldFeedback.length - Phase0aPresentationTokens.maxEntries;
      if (overflow > 0) _heldFeedback.removeRange(0, overflow);
    }
    if (mounted) setState(() {});
  }

  static bool _isSingletonFeedback(Phase0aVfxKind kind) => switch (kind) {
    Phase0aVfxKind.meleeSlash ||
    Phase0aVfxKind.palmTrail ||
    Phase0aVfxKind.gatherVortex ||
    Phase0aVfxKind.clearBurst ||
    Phase0aVfxKind.waveBanner ||
    Phase0aVfxKind.outcomeSeal => true,
    Phase0aVfxKind.damagePopup ||
    Phase0aVfxKind.gatherPull ||
    Phase0aVfxKind.defeatInk => false,
  };

  static bool _isAttackFeedback(Phase0aVfxKind kind) =>
      kind == Phase0aVfxKind.meleeSlash || kind == Phase0aVfxKind.palmTrail;

  static bool _advanceActorTimers(
    Map<String, double> timers,
    double deltaSeconds,
  ) {
    final expired = <String>[];
    for (final entry in timers.entries) {
      final remaining = entry.value - deltaSeconds;
      if (remaining <= 0) {
        expired.add(entry.key);
      } else {
        timers[entry.key] = remaining;
      }
    }
    for (final id in expired) {
      timers.remove(id);
    }
    return expired.isNotEmpty;
  }

  void _onFrame(Duration elapsed) {
    // 暂停中:世界零推进(反馈计时/domain 步进均冻结)。
    if (_paused) return;
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) return;
    final deltaSeconds =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    for (final held in _heldFeedback) {
      held.remainingSeconds -= deltaSeconds;
    }
    final previousFeedbackCount = _heldFeedback.length;
    _heldFeedback.removeWhere((held) => held.remainingSeconds <= 0);
    final transientChanged =
        _advanceActorTimers(_hitFlashRemaining, deltaSeconds) |
        _advanceActorTimers(_hpEmphasisRemaining, deltaSeconds);
    if ((previousFeedbackCount != _heldFeedback.length || transientChanged) &&
        mounted) {
      setState(() {});
    }
    if (!widget.autoStep ||
        widget.controller.outcome != Phase0aBattleOutcome.ongoing) {
      return;
    }
    _accumulatorSeconds += deltaSeconds;
    var steps = 0;
    while (_accumulatorSeconds >= widget.controller.fixedDeltaSeconds &&
        steps < Phase0aPresentationTokens.maxCatchUpTicksPerFrame) {
      if (_primaryAttackHeld) _enqueuePointerAttack();
      widget.controller.step();
      _accumulatorSeconds -= widget.controller.fixedDeltaSeconds;
      steps++;
      if (widget.controller.outcome != Phase0aBattleOutcome.ongoing) break;
    }
    if (steps == Phase0aPresentationTokens.maxCatchUpTicksPerFrame) {
      _accumulatorSeconds = 0;
    }
  }

  /// 终局「再战」(9B):装配新 flow 换入 controller,清全部局部表现态。
  /// 仅在终局且有 builder 时可触发(按钮与 Enter 两入口都过 `_retryInFlight`)。
  Future<void> _retry() async {
    final builder = widget.retryFlowBuilder;
    if (builder == null || _retryInFlight) return;
    setState(() => _retryInFlight = true);
    SoundManager.instance.playSfx(SfxId.uiTap);
    try {
      final newFlow = await builder();
      if (!mounted) return;
      widget.controller.restart(newFlow);
      _heldFeedback.clear();
      _hitFlashRemaining.clear();
      _hpEmphasisRemaining.clear();
      _accumulatorSeconds = 0;
      _lastElapsed = null;
      _paused = false;
    } finally {
      if (mounted) setState(() => _retryInFlight = false);
    }
    _focusNode.requestFocus();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (widget.controller.outcome != Phase0aBattleOutcome.ongoing) {
      // 终局态唯一有效键:Enter = 再战(9B)。
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          widget.retryFlowBuilder != null &&
          !_retryInFlight) {
        _retry();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    // Esc 暂停/继续(0C,spec §3.1):仅进行中可暂停;暂停中除 Esc 外不受理。
    if (key == LogicalKeyboardKey.escape) {
      setState(() {
        _paused = !_paused;
        if (_paused) _stopPointerAttack();
        if (!_paused) _lastElapsed = null; // 恢复首帧重建 delta 基准,不吞暂停时长
      });
      return KeyEventResult.handled;
    }
    if (_paused) return KeyEventResult.ignored;
    final command = switch (key) {
      LogicalKeyboardKey.keyA => const Phase0aPlayerCommand(left: true),
      LogicalKeyboardKey.keyD => const Phase0aPlayerCommand(right: true),
      LogicalKeyboardKey.keyW => const Phase0aPlayerCommand(up: true),
      LogicalKeyboardKey.keyS => const Phase0aPlayerCommand(down: true),
      LogicalKeyboardKey.keyJ => const Phase0aPlayerCommand(attack: true),
      LogicalKeyboardKey.keyQ => const Phase0aPlayerCommand(gather: true),
      LogicalKeyboardKey.keyR => const Phase0aPlayerCommand(clear: true),
      LogicalKeyboardKey.digit1 ||
      LogicalKeyboardKey.numpad1 => const Phase0aPlayerCommand(skillHotkey: 1),
      LogicalKeyboardKey.digit2 ||
      LogicalKeyboardKey.numpad2 => const Phase0aPlayerCommand(skillHotkey: 2),
      LogicalKeyboardKey.digit3 ||
      LogicalKeyboardKey.numpad3 => const Phase0aPlayerCommand(skillHotkey: 3),
      LogicalKeyboardKey.digit4 ||
      LogicalKeyboardKey.numpad4 => const Phase0aPlayerCommand(skillHotkey: 4),
      LogicalKeyboardKey.digit5 ||
      LogicalKeyboardKey.numpad5 => const Phase0aPlayerCommand(skillHotkey: 5),
      LogicalKeyboardKey.digit6 ||
      LogicalKeyboardKey.numpad6 => const Phase0aPlayerCommand(skillHotkey: 6),
      _ => null,
    };
    if (command == null) return KeyEventResult.ignored;
    widget.controller.enqueue(command);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: WuxiaUi.ink,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final stage = Phase0aStage(viewport: size);
            return Stack(
              key: const ValueKey('phase0a_battle_screen'),
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Listener(
                    key: const ValueKey('phase0a_stage_input_layer'),
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (event) => _onStagePointerDown(event, stage),
                    onPointerMove: (event) => _onStagePointerMove(event, stage),
                    onPointerUp: (_) => _stopPointerAttack(),
                    onPointerCancel: (_) => _stopPointerAttack(),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RepaintBoundary(
                          key: const ValueKey('phase0a_static_background'),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/scenes/battle_mountain_pass_stage_v2.png',
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                              ),
                              const ColoredBox(color: Color(0x380F0E0B)),
                              const CustomPaint(painter: _StageWashPainter()),
                            ],
                          ),
                        ),
                        ..._buildActors(controller, stage),
                        _FeedbackLayer(
                          controller: controller,
                          stage: stage,
                          entries: [
                            for (final held in _heldFeedback) held.entry,
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _PlayerHud(
                  controller: controller,
                  healthEmphasized: _hpEmphasisRemaining.containsKey(
                    controller.state.player.id,
                  ),
                ),
                if (widget.numericSkillBindings.equipped.isNotEmpty)
                  Positioned(
                    left: Phase0aPresentationTokens.hudInset,
                    right: Phase0aPresentationTokens.hudInset,
                    bottom: Phase0aPresentationTokens.skillHudBottom,
                    child: Center(
                      child: Phase0aNumericSkillSeals(
                        bindings: widget.numericSkillBindings,
                        slots: {
                          for (final slot in controller.state.skillSlots)
                            slot.slot: slot,
                        },
                        qiCurrent: controller.state.player.qiCurrent,
                        onPressed: (hotkey) {
                          if (_paused) return;
                          controller.enqueue(
                            Phase0aPlayerCommand(skillHotkey: hotkey),
                          );
                        },
                      ),
                    ),
                  ),
                Positioned(
                  right: Phase0aPresentationTokens.skillHudRight,
                  bottom: Phase0aPresentationTokens.skillHudBottom,
                  child: Phase0aSkillSeals(
                    gatherSlot: _displaySlot(controller, 'gather'),
                    clearSlot: _displaySlot(controller, 'clear'),
                    qiCurrent: controller.state.player.qiCurrent,
                    onGather: _paused
                        ? () {}
                        : () => controller.enqueue(
                            const Phase0aPlayerCommand(gather: true),
                          ),
                    onClear: _paused
                        ? () {}
                        : () => controller.enqueue(
                            const Phase0aPlayerCommand(clear: true),
                          ),
                  ),
                ),
                // Esc 暂停横幅(0C):盖在 HUD/技能印之上,暂停中唯一新增可见物。
                if (_paused)
                  const Center(
                    child: SizedBox(
                      key: ValueKey('phase0a_paused_banner'),
                      width: Phase0aPresentationTokens.vfxBannerWidth,
                      height: Phase0aPresentationTokens.vfxBannerHeight,
                      child: CustomPaint(
                        painter: _PaperBannerPainter(),
                        child: Center(
                          child: Text(
                            UiStrings.phase0aPausedBanner,
                            style: TextStyle(
                              color: WuxiaUi.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // 终局「再战」入口(9B):封签由 IgnorePointer 反馈层展示,
                // 按钮必须落在主 Stack 才能收手势;无 builder 时纯展示不出按钮。
                if (controller.outcome != Phase0aBattleOutcome.ongoing &&
                    widget.retryFlowBuilder != null)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height:
                              Phase0aPresentationTokens.vfxOutcomeSize +
                              Phase0aPresentationTokens.retryButtonTopGap,
                        ),
                        _RetryButton(onPressed: _retryInFlight ? null : _retry),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildActors(
    Phase0aBattleController controller,
    Phase0aStage stage,
  ) {
    final actors = stage.sortActors([
      controller.state.player,
      ...controller.state.enemies,
    ]);
    return [
      for (final actor in actors) _positionedActor(controller, stage, actor),
    ];
  }

  Widget _positionedActor(
    Phase0aBattleController controller,
    Phase0aStage stage,
    Phase0aActor actor,
  ) {
    final foot = stage.worldToScreen(actor.position);
    final scale = stage.depthScale(actor.position.y);
    final width = Phase0aPresentationTokens.actorWidth * scale;
    final height = Phase0aPresentationTokens.actorHeight * scale;
    return AnimatedPositioned(
      key: ValueKey('phase0a_actor_position_${actor.id}'),
      duration: Duration(
        microseconds:
            (controller.fixedDeltaSeconds * Duration.microsecondsPerSecond)
                .round(),
      ),
      curve: Curves.linear,
      left: foot.dx - width / 2,
      top: foot.dy - height,
      width: width,
      height: height,
      child: RepaintBoundary(
        key: ValueKey('phase0a_actor_${actor.id}'),
        child: _ActorStandee(
          key: ValueKey('phase0a_standee_${actor.id}'),
          actor: actor,
          visual: controller.roster.visualFor(actor.id),
          isHitFlashing: _hitFlashRemaining.containsKey(actor.id),
          isHealthEmphasized: _hpEmphasisRemaining.containsKey(actor.id),
        ),
      ),
    );
  }

  static Phase0aSkillSlot _slot(Phase0aArenaState state, String id) =>
      state.skillSlots.firstWhere((slot) => slot.slot == id);

  static Phase0aSkillSlot _displaySlot(
    Phase0aBattleController controller,
    String id,
  ) {
    final slot = _slot(controller.state, id);
    return controller.outcome == Phase0aBattleOutcome.ongoing
        ? slot
        : slot.copyWith(availability: Phase0aSkillAvailability.down);
  }
}

final class _HeldFeedback {
  _HeldFeedback(this.entry, this.remainingSeconds);

  final Phase0aVfxEntry entry;
  double remainingSeconds;
}

/// 终局「再战」纸签按钮(9B)。宣纸底 + 墨字 + 绛红描边,守水墨克制基调;
/// 禁用态(装配中)降透明度,不换色。键盘焦点金边环对齐 PlaqueButton
/// 体例(9C):Tab 落点可见。
class _RetryButton extends StatefulWidget {
  const _RetryButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      // 桌面语义门禁(CLAUDE §8.2):裸 GestureDetector 四项皆无,
      // 用 FocusableActionDetector 补焦点/键盘激活/鼠标光标。
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: GestureDetector(
          key: const ValueKey('phase0a_retry_button'),
          onTap: widget.onPressed,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: WuxiaUi.paper,
                    border: Border.all(color: WuxiaUi.jiang, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Phase0aPresentationTokens.retryButtonPaddingH,
                  vertical: Phase0aPresentationTokens.retryButtonPaddingV,
                ),
                child: Text(
                  UiStrings.phase0aRetryLabel,
                  style: TextStyle(
                    color: WuxiaUi.ink,
                    fontSize: Phase0aPresentationTokens.retryButtonFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // 键盘 focus 高亮:金边环(PlaqueButton 同体例,9C)。
              if (_focused)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: WuxiaUi.gold,
                          width: Phase0aPresentationTokens.focusRingWidth,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActorStandee extends StatelessWidget {
  const _ActorStandee({
    super.key,
    required this.actor,
    required this.visual,
    required this.isHitFlashing,
    required this.isHealthEmphasized,
  });

  final Phase0aActor actor;
  final Phase0aActorVisual visual;
  final bool isHitFlashing;
  final bool isHealthEmphasized;

  @override
  Widget build(BuildContext context) {
    final enemy = actor.side == Phase0aSide.enemy;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 0,
          child: Container(
            width: Phase0aPresentationTokens.depthShadowWidth,
            height: Phase0aPresentationTokens.depthShadowHeight,
            decoration: BoxDecoration(
              color: WuxiaUi.ink.withValues(
                alpha: Phase0aPresentationTokens.depthShadowOpacity,
              ),
              borderRadius: BorderRadius.circular(
                Phase0aPresentationTokens.depthShadowHeight,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          height: Phase0aPresentationTokens.actorImageHeight,
          left: 0,
          right: 0,
          child: ColorFiltered(
            key: isHitFlashing
                ? ValueKey('phase0a_hit_flash_${actor.id}')
                : null,
            colorFilter: ColorFilter.mode(
              WuxiaUi.paper.withValues(
                alpha: isHitFlashing
                    ? Phase0aPresentationTokens.hitFlashOpacity
                    : 0,
              ),
              BlendMode.srcATop,
            ),
            child: Image.asset(
              visual.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        if (enemy)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _HitEmphasisFrame(
              key: isHealthEmphasized
                  ? ValueKey('phase0a_hp_emphasis_${actor.id}')
                  : null,
              active: isHealthEmphasized,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    visual.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WuxiaUi.paper,
                      fontSize: Phase0aPresentationTokens.actorNameFontSize,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: WuxiaUi.ink, blurRadius: 3)],
                    ),
                  ),
                  const SizedBox(
                    height: Phase0aPresentationTokens.actorLabelGap,
                  ),
                  SizedBox(
                    width: Phase0aPresentationTokens.actorHpWidth,
                    child: HpBar(
                      key: ValueKey('phase0a_hp_${actor.id}'),
                      current: actor.currentHealth,
                      max: actor.maxHealth,
                      height: Phase0aPresentationTokens.actorHpHeight,
                      tightLabel: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HitEmphasisFrame extends StatelessWidget {
  const _HitEmphasisFrame({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: active
          ? WuxiaUi.paper.withValues(
              alpha: Phase0aPresentationTokens.hpEmphasisFillOpacity,
            )
          : Colors.transparent,
      border: Border.all(
        color: active ? WuxiaUi.qingOnDark : Colors.transparent,
        width: Phase0aPresentationTokens.hpEmphasisBorderWidth,
      ),
      borderRadius: BorderRadius.circular(
        Phase0aPresentationTokens.hpEmphasisRadius,
      ),
      boxShadow: active
          ? [
              BoxShadow(
                color: WuxiaUi.paper.withValues(
                  alpha: Phase0aPresentationTokens.hpEmphasisGlowOpacity,
                ),
                blurRadius: Phase0aPresentationTokens.hpEmphasisGlowBlur,
              ),
            ]
          : null,
    ),
    child: child,
  );
}

class _PlayerHud extends StatelessWidget {
  const _PlayerHud({required this.controller, required this.healthEmphasized});

  final Phase0aBattleController controller;
  final bool healthEmphasized;

  @override
  Widget build(BuildContext context) {
    final player = controller.state.player;
    return Positioned(
      key: const ValueKey('phase0a_player_hud'),
      left: Phase0aPresentationTokens.hudInset,
      bottom: Phase0aPresentationTokens.hudInset,
      width: Phase0aPresentationTokens.hudWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WuxiaUi.paper.withValues(
            alpha: Phase0aPresentationTokens.hudPaperOpacity,
          ),
          border: Border.all(
            color: WuxiaUi.ink,
            width: Phase0aPresentationTokens.hudBorderWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Phase0aPresentationTokens.hudPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.roster.nameOf(player.id),
                style: const TextStyle(
                  color: WuxiaUi.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Phase0aPresentationTokens.hudGap),
              _HitEmphasisFrame(
                key: healthEmphasized
                    ? const ValueKey('phase0a_hp_emphasis_player')
                    : null,
                active: healthEmphasized,
                child: HpBar(
                  key: const ValueKey('phase0a_hp_player'),
                  current: player.currentHealth,
                  max: player.maxHealth,
                  height: Phase0aPresentationTokens.hudBarHeight,
                  labelPrefix: '${UiStrings.phase0aPlayerHealth} ',
                  tightLabel: true,
                ),
              ),
              const SizedBox(height: Phase0aPresentationTokens.hudGap),
              HpBar(
                key: const ValueKey('phase0a_player_qi'),
                current: player.qiCurrent,
                max: player.qiMax,
                height: Phase0aPresentationTokens.hudBarHeight,
                isInternalForce: true,
                labelPrefix: '${UiStrings.phase0aPlayerQi} ',
                tightLabel: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackLayer extends StatelessWidget {
  const _FeedbackLayer({
    required this.controller,
    required this.stage,
    required this.entries,
  });

  final Phase0aBattleController controller;
  final Phase0aStage stage;
  final List<Phase0aVfxEntry> entries;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    var popupIndex = 0;
    for (final entry in entries) {
      switch (entry.kind) {
        case Phase0aVfxKind.damagePopup:
          children.add(_damagePopup(entry, popupIndex++));
        case Phase0aVfxKind.meleeSlash:
          children.add(
            _inkVfx(
              entry,
              _InkEffect.melee,
              vfxKey: const ValueKey('phase0a_melee_slash'),
            ),
          );
        case Phase0aVfxKind.palmTrail:
          children.add(_palmTrail(entry));
        case Phase0aVfxKind.gatherVortex:
          children.add(
            _inkVfx(
              entry,
              _InkEffect.gather,
              vfxKey: const ValueKey('phase0a_gather_vortex'),
            ),
          );
        case Phase0aVfxKind.gatherPull:
          children.add(_gatherPull(entry));
        case Phase0aVfxKind.clearBurst:
          children.add(
            _inkVfx(
              entry,
              _InkEffect.clear,
              vfxKey: const ValueKey('phase0a_clear_burst'),
            ),
          );
        case Phase0aVfxKind.defeatInk:
          children.add(
            _inkVfx(
              entry,
              _InkEffect.defeat,
              vfxKey: const ValueKey('phase0a_defeat_ink'),
              containerKey: ValueKey('phase0a_defeat_ink_${entry.targetId}'),
            ),
          );
        case Phase0aVfxKind.waveBanner:
          children.add(_waveBanner(entry));
        case Phase0aVfxKind.outcomeSeal:
          break;
      }
    }
    if (controller.outcome != Phase0aBattleOutcome.ongoing) {
      children.add(_outcomeSeal(controller.outcome));
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          key: const ValueKey('phase0a_feedback_layer'),
          child: Stack(children: children),
        ),
      ),
    );
  }

  Widget _damagePopup(Phase0aVfxEntry entry, int index) {
    // 使用事件发生时的世界坐标快照(entry.anchor),不反查当前 state。
    // 目标死亡后已从 controller.state 移除,直接查 id 会 fallback
    // 到屏幕中心,导致伤害数字位置错误。
    final anchor = entry.anchor != null
        ? stage.worldToScreen(entry.anchor!)
        : stage.safeRect.center;
    return Positioned(
      key: ValueKey('phase0a_popup_$index'),
      left: anchor.dx,
      top:
          anchor.dy -
          Phase0aPresentationTokens.actorHeight -
          index * Phase0aPresentationTokens.vfxPopupGap,
      child: Transform.translate(
        offset: const Offset(-12, 0),
        child: Text(
          '${entry.damage}',
          style: TextStyle(
            color: entry.isCritical ? WuxiaUi.jiang : WuxiaUi.ink,
            fontSize: Phase0aPresentationTokens.vfxPopupFontSize,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: WuxiaUi.paper, blurRadius: 1),
              Shadow(color: WuxiaUi.paper, blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }

  /// 掌风轨迹:出手者→目标连线的世界坐标映射到屏幕,
  /// 以连线中点为中心、以连线方向为旋转角度绘制。
  Widget _palmTrail(Phase0aVfxEntry entry) {
    final src = entry.source;
    final dst = entry.vfxTarget;
    if (src == null || dst == null) {
      return const SizedBox.shrink();
    }
    final screenSrc = stage.worldToScreen(src);
    final screenDst = stage.worldToScreen(dst);
    final mid = Offset(
      (screenSrc.dx + screenDst.dx) / 2,
      (screenSrc.dy + screenDst.dy) / 2,
    );
    final angle = math.atan2(
      screenDst.dy - screenSrc.dy,
      screenDst.dx - screenSrc.dx,
    );
    final size = Phase0aPresentationTokens.vfxCenterSize;
    return Positioned(
      left: mid.dx - size / 2,
      top: mid.dy - size / 2,
      width: size,
      height: size,
      child: Transform.rotate(
        angle: angle,
        child: CustomPaint(
          key: const ValueKey('phase0a_palm_trail'),
          size: Size.square(size),
          painter: const _InkEffectPainter(_InkEffect.palm),
        ),
      ),
    );
  }

  /// Q 拉拢轨迹:以事件发生时的目标→玩家快照绘制弯曲墨线。
  Widget _gatherPull(Phase0aVfxEntry entry) {
    final source = entry.source;
    final target = entry.vfxTarget;
    final targetId = entry.targetId;
    if (source == null || target == null || targetId == null) {
      return const SizedBox.shrink();
    }
    final screenSource = stage.worldToScreen(source);
    final screenTarget = stage.worldToScreen(target);
    final padding = Phase0aPresentationTokens.gatherPullPadding;
    final left = math.min(screenSource.dx, screenTarget.dx) - padding;
    final top = math.min(screenSource.dy, screenTarget.dy) - padding;
    final width = (screenSource.dx - screenTarget.dx).abs() + padding * 2;
    final height = (screenSource.dy - screenTarget.dy).abs() + padding * 2;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: CustomPaint(
        key: ValueKey('phase0a_gather_pull_$targetId'),
        painter: _GatherPullPainter(
          source: screenSource - Offset(left, top),
          target: screenTarget - Offset(left, top),
        ),
      ),
    );
  }

  /// 单点水墨 VFX(近战墨痕 / Q 涡旋 / R 墨爆 / 死亡墨散):
  /// 以 [Phase0aVfxEntry.anchor] 的世界坐标快照映射到屏幕。
  Widget _inkVfx(
    Phase0aVfxEntry entry,
    _InkEffect effect, {
    required Key vfxKey,
    Key? containerKey,
  }) {
    final anchor = entry.anchor;
    if (anchor == null) {
      return const SizedBox.shrink();
    }
    final screen = stage.worldToScreen(anchor);
    final size = switch (effect) {
      _InkEffect.melee => Phase0aPresentationTokens.vfxMeleeSize,
      _InkEffect.defeat when entry.defeatKind == Phase0aDefeatKind.elite =>
        Phase0aPresentationTokens.vfxEliteDefeatSize,
      _ => Phase0aPresentationTokens.vfxCenterSize,
    };
    return Positioned(
      left: screen.dx - size / 2,
      top: screen.dy - size / 2,
      width: size,
      height: size,
      child: SizedBox.square(
        key: containerKey,
        dimension: size,
        child: CustomPaint(
          key: vfxKey,
          size: Size.square(size),
          painter: _InkEffectPainter(effect, defeatKind: entry.defeatKind),
        ),
      ),
    );
  }

  Widget _waveBanner(Phase0aVfxEntry entry) => Positioned(
    key: const ValueKey('phase0a_wave_banner'),
    top: Phase0aPresentationTokens.vfxBannerTop,
    left: (stage.viewport.width - Phase0aPresentationTokens.vfxBannerWidth) / 2,
    width: Phase0aPresentationTokens.vfxBannerWidth,
    height: Phase0aPresentationTokens.vfxBannerHeight,
    child: CustomPaint(
      painter: const _PaperBannerPainter(),
      child: Center(
        child: Text(
          UiStrings.phase0aWaveBanner(entry.waveIndex!, entry.waveTotal!),
          style: const TextStyle(
            color: WuxiaUi.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    ),
  );

  Widget _outcomeSeal(Phase0aBattleOutcome outcome) => Center(
    child: CustomPaint(
      key: const ValueKey('phase0a_outcome_seal'),
      size: const Size.square(Phase0aPresentationTokens.vfxOutcomeSize),
      painter: const _OutcomeSealPainter(),
      child: SizedBox.square(
        dimension: Phase0aPresentationTokens.vfxOutcomeSize,
        child: Center(
          child: Text(
            outcome == Phase0aBattleOutcome.victory
                ? UiStrings.phase0aVictorySeal
                : UiStrings.phase0aDefeatSeal,
            style: const TextStyle(
              color: WuxiaUi.paper,
              fontSize: Phase0aPresentationTokens.vfxOutcomeFontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
}

enum _InkEffect { melee, palm, gather, clear, defeat }

class _InkEffectPainter extends CustomPainter {
  const _InkEffectPainter(this.effect, {this.defeatKind});

  final _InkEffect effect;
  final Phase0aDefeatKind? defeatKind;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ink = Paint()
      ..color = WuxiaUi.ink.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = Phase0aPresentationTokens.vfxStrokeWidth;
    final wash = Paint()
      ..color = WuxiaUi.jiang.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = Phase0aPresentationTokens.vfxThinStrokeWidth;
    switch (effect) {
      case _InkEffect.melee:
        final rising = Path()
          ..moveTo(size.width * 0.18, size.height * 0.78)
          ..quadraticBezierTo(
            size.width * 0.48,
            size.height * 0.30,
            size.width * 0.84,
            size.height * 0.16,
          );
        final falling = Path()
          ..moveTo(size.width * 0.28, size.height * 0.18)
          ..quadraticBezierTo(
            size.width * 0.58,
            size.height * 0.54,
            size.width * 0.78,
            size.height * 0.82,
          );
        canvas.drawPath(
          rising,
          Paint()
            ..color = WuxiaUi.qing.withValues(alpha: 0.90)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = Phase0aPresentationTokens.vfxStrokeWidth * 1.35,
        );
        canvas.drawPath(falling, ink);
        canvas.drawCircle(
          Offset(size.width * 0.72, size.height * 0.28),
          Phase0aPresentationTokens.gatherPullTargetDotRadius,
          Paint()..color = WuxiaUi.jiang.withValues(alpha: 0.58),
        );
      case _InkEffect.palm:
        final body = Path()
          ..moveTo(size.width * 0.07, size.height * 0.57)
          ..cubicTo(
            size.width * 0.33,
            size.height * 0.24,
            size.width * 0.68,
            size.height * 0.25,
            size.width * 0.93,
            size.height * 0.43,
          )
          ..cubicTo(
            size.width * 0.68,
            size.height * 0.50,
            size.width * 0.35,
            size.height * 0.72,
            size.width * 0.12,
            size.height * 0.70,
          )
          ..close();
        canvas.drawPath(
          body,
          Paint()..color = WuxiaUi.qing.withValues(alpha: 0.78),
        );
        final dryBrush = Path()
          ..moveTo(size.width * 0.12, size.height * 0.61)
          ..quadraticBezierTo(
            size.width * 0.48,
            size.height * 0.40,
            size.width * 0.86,
            size.height * 0.44,
          );
        canvas.drawPath(dryBrush, ink);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: size.width * 0.27),
          -1.35,
          1.95,
          false,
          wash,
        );
      case _InkEffect.gather:
        for (var i = 0; i < 3; i++) {
          canvas.drawArc(
            Rect.fromCircle(
              center: center,
              radius: size.width * (0.16 + i * 0.09),
            ),
            i * 0.8,
            4.7,
            false,
            i.isEven ? ink : wash,
          );
        }
      case _InkEffect.clear:
        for (var i = 0; i < Phase0aPresentationTokens.vfxSpokeCount; i++) {
          final angle =
              i * math.pi * 2 / Phase0aPresentationTokens.vfxSpokeCount;
          final start = Offset(
            center.dx + math.cos(angle) * size.width * 0.10,
            center.dy + math.sin(angle) * size.height * 0.10,
          );
          final end = Offset(
            center.dx + math.cos(angle) * size.width * 0.44,
            center.dy + math.sin(angle) * size.height * 0.44,
          );
          canvas.drawLine(start, end, i.isEven ? ink : wash);
        }
        canvas.drawCircle(center, size.width * 0.24, ink);
      case _InkEffect.defeat:
        final elite = defeatKind == Phase0aDefeatKind.elite;
        final count = elite
            ? Phase0aPresentationTokens.vfxSpokeCount * 2
            : Phase0aPresentationTokens.vfxSpokeCount;
        if (elite) {
          canvas.drawCircle(
            center,
            size.width * 0.22,
            Paint()
              ..color = WuxiaUi.jiang.withValues(alpha: 0.42)
              ..style = PaintingStyle.stroke
              ..strokeWidth = Phase0aPresentationTokens.vfxThinStrokeWidth,
          );
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: size.width * 0.34),
            -0.8,
            4.9,
            false,
            ink,
          );
        }
        for (var i = 0; i < count; i++) {
          final angle = i * math.pi * 2 / count;
          final point = Offset(
            center.dx + math.cos(angle) * size.width * (elite ? 0.37 : 0.31),
            center.dy + math.sin(angle) * size.height * (elite ? 0.29 : 0.22),
          );
          canvas.drawCircle(
            point,
            i.isEven ? 5 : 3,
            Paint()
              ..color = elite && i % 3 == 0
                  ? WuxiaUi.jiang.withValues(alpha: 0.64)
                  : WuxiaUi.ink.withValues(alpha: 0.72),
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _InkEffectPainter oldDelegate) =>
      oldDelegate.effect != effect || oldDelegate.defeatKind != defeatKind;
}

class _GatherPullPainter extends CustomPainter {
  const _GatherPullPainter({required this.source, required this.target});

  final Offset source;
  final Offset target;

  @override
  void paint(Canvas canvas, Size size) {
    final delta = target - source;
    final distance = delta.distance;
    if (distance == 0) return;
    final normal = Offset(-delta.dy / distance, delta.dx / distance);
    final midpoint = Offset(
      (source.dx + target.dx) / 2,
      (source.dy + target.dy) / 2,
    );
    final control =
        midpoint + normal * Phase0aPresentationTokens.gatherPullCurveBend;
    final echoControl =
        midpoint - normal * Phase0aPresentationTokens.gatherPullEchoBend;
    final path = Path()
      ..moveTo(source.dx, source.dy)
      ..quadraticBezierTo(control.dx, control.dy, target.dx, target.dy);
    final echoPath = Path()
      ..moveTo(source.dx, source.dy)
      ..quadraticBezierTo(echoControl.dx, echoControl.dy, target.dx, target.dy);
    final startTangent = control - source;
    final endTangent = target - control;
    final startNormal = Offset(
      -startTangent.dy / startTangent.distance,
      startTangent.dx / startTangent.distance,
    );
    final endNormal = Offset(
      -endTangent.dy / endTangent.distance,
      endTangent.dx / endTangent.distance,
    );
    final ribbonStartWidth =
        Phase0aPresentationTokens.gatherPullRibbonStartWidth;
    final ribbonEndWidth = Phase0aPresentationTokens.gatherPullRibbonEndWidth;
    final ribbon = Path()
      ..moveTo(
        source.dx + startNormal.dx * ribbonStartWidth,
        source.dy + startNormal.dy * ribbonStartWidth,
      )
      ..quadraticBezierTo(
        control.dx + normal.dx * ribbonStartWidth / 2,
        control.dy + normal.dy * ribbonStartWidth / 2,
        target.dx + endNormal.dx * ribbonEndWidth,
        target.dy + endNormal.dy * ribbonEndWidth,
      )
      ..lineTo(
        target.dx - endNormal.dx * ribbonEndWidth,
        target.dy - endNormal.dy * ribbonEndWidth,
      )
      ..quadraticBezierTo(
        control.dx - normal.dx * ribbonStartWidth / 3,
        control.dy - normal.dy * ribbonStartWidth / 3,
        source.dx - startNormal.dx * ribbonStartWidth,
        source.dy - startNormal.dy * ribbonStartWidth,
      )
      ..close();
    canvas.drawPath(
      ribbon,
      Paint()..color = WuxiaUi.qing.withValues(alpha: 0.46),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = WuxiaUi.qing.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = Phase0aPresentationTokens.gatherPullStrokeWidth,
    );
    canvas.drawPath(
      echoPath,
      Paint()
        ..color = WuxiaUi.ink.withValues(alpha: 0.48)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = Phase0aPresentationTokens.gatherPullEchoStrokeWidth,
    );
    for (final t in const <double>[0.32, 0.58, 0.78]) {
      final point = Offset(
        (1 - t) * (1 - t) * source.dx +
            2 * (1 - t) * t * control.dx +
            t * t * target.dx,
        (1 - t) * (1 - t) * source.dy +
            2 * (1 - t) * t * control.dy +
            t * t * target.dy,
      );
      canvas.drawCircle(
        point,
        Phase0aPresentationTokens.gatherPullDropletRadius * (1 - t * 0.45),
        Paint()..color = WuxiaUi.qing.withValues(alpha: 0.68),
      );
    }
    canvas.drawCircle(
      source,
      Phase0aPresentationTokens.gatherPullSourceSplashRadius,
      Paint()..color = WuxiaUi.qing.withValues(alpha: 0.54),
    );
    canvas.drawCircle(
      target,
      Phase0aPresentationTokens.gatherPullTargetDotRadius,
      Paint()..color = WuxiaUi.jiang.withValues(alpha: 0.62),
    );
  }

  @override
  bool shouldRepaint(covariant _GatherPullPainter oldDelegate) =>
      oldDelegate.source != source || oldDelegate.target != target;
}

class _StageWashPainter extends CustomPainter {
  const _StageWashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          WuxiaUi.paper.withValues(alpha: 0.08),
          WuxiaUi.ink.withValues(
            alpha: Phase0aPresentationTokens.stageShadeOpacity,
          ),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _StageWashPainter oldDelegate) => false;
}

class _PaperBannerPainter extends CustomPainter {
  const _PaperBannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.24)
      ..lineTo(size.width * 0.06, 0)
      ..lineTo(size.width * 0.94, size.height * 0.08)
      ..lineTo(size.width, size.height * 0.78)
      ..lineTo(size.width * 0.90, size.height)
      ..lineTo(size.width * 0.08, size.height * 0.90)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = WuxiaUi.paper.withValues(alpha: 0.92),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = WuxiaUi.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Phase0aPresentationTokens.hudBorderWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _PaperBannerPainter oldDelegate) => false;
}

class _OutcomeSealPainter extends CustomPainter {
  const _OutcomeSealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..color = WuxiaUi.jiang.withValues(alpha: 0.92),
    );
    canvas.drawRect(
      rect.deflate(8),
      Paint()
        ..color = WuxiaUi.paper
        ..style = PaintingStyle.stroke
        ..strokeWidth = Phase0aPresentationTokens.vfxStrokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _OutcomeSealPainter oldDelegate) => false;
}
