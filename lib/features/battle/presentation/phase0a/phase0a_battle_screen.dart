import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/domain/enums.dart';
import '../../../../shared/audio/audio_assets.dart';
import '../../../../shared/audio/sound_manager.dart';
import '../../../../shared/strings.dart';
import '../../../../shared/theme/wuxia_tokens.dart';
import '../../application/phase0a/phase0a_battle_flow.dart';
import '../../application/phase0a/phase0a_player_input_adapter.dart';
import '../../application/phase0a/phase0a_numeric_skill_binding.dart';
import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/basic_attack_chain.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import '../../../../shared/widgets/combat_hp_bar.dart';
import 'phase0a_battle_controller.dart';
import 'phase0a_actor_render_motion.dart';
import 'phase0a_camera_dead_zone.dart';
import 'phase0a_offscreen_indicator.dart';
import 'phase0a_parallax_background.dart';
import 'phase0a_presentation_tokens.dart';
import 'phase0a_sfx.dart';
import 'phase0a_skill_seals.dart';
import 'phase0a_stage.dart';
import 'phase0a_vfx_controller.dart';
import 'phase0a_visual_roster.dart';

String get _phase0aDodgeKeyLabel =>
    UiStrings.phase0aDefenseDodgeKey.replaceFirst('Z', 'Space');

final class Phase0aBattleScreen extends StatefulWidget {
  const Phase0aBattleScreen({
    super.key,
    required this.controller,
    this.autoStep = true,
    this.feedbackHoldSeconds = Phase0aPresentationTokens.feedbackHoldSeconds,
    this.retryFlowBuilder,
    this.numericSkillBindings = const Phase0aNumericSkillBindings.empty(),
    this.botCommandBuilder,
  }) : assert(feedbackHoldSeconds > 0);

  final Phase0aBattleController controller;
  final bool autoStep;
  final double feedbackHoldSeconds;

  /// 终局「再战」的新 flow 装配器;为 null 时终局不出现重试入口
  /// (静态验收路由等纯展示场景保持只读)。
  final Future<Phase0aBattleFlow> Function()? retryFlowBuilder;

  final Phase0aNumericSkillBindings numericSkillBindings;

  /// Foreground bot input. Commands still enter the same controller/reducer
  /// once per fixed tick; null keeps the existing human input path.
  final Phase0aPlayerCommand Function(Phase0aArenaState state)?
  botCommandBuilder;

  @override
  State<Phase0aBattleScreen> createState() => _Phase0aBattleScreenState();
}

class _Phase0aBattleScreenState extends State<Phase0aBattleScreen>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final Ticker _ticker;
  late final ValueNotifier<int> _feedbackFrame;
  late final ValueNotifier<int> _indicatorFrame;
  Duration? _lastElapsed;
  double _accumulatorSeconds = 0;
  final List<_HeldFeedback> _heldFeedback = <_HeldFeedback>[];
  int _nextFeedbackId = 0;
  final Map<String, double> _hitFlashRemaining = <String, double>{};
  final Map<String, double> _hpEmphasisRemaining = <String, double>{};
  final Map<String, double> _actionPulseRemaining = <String, double>{};
  final Map<String, Phase0aActorRenderMotion> _actorRenderMotions =
      <String, Phase0aActorRenderMotion>{};
  ArenaVector? _cameraRenderPosition;
  final List<String> _actorPaintOrder = <String>[];
  int? _lastActorLayerTick;
  bool _retryInFlight = false;
  bool _primaryAttackHeld = false;
  bool _primaryAttackKeyHeld = false;
  final Set<LogicalKeyboardKey> _heldMovementKeys = <LogicalKeyboardKey>{};
  ArenaVector? _pointerAimDirection;

  /// Esc 暂停态(0C):暂停期间帧回调零推进(不记性能样本),
  /// 键鼠指令均不受理;再按 Esc 恢复。
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'phase0a-battle-input');
    _feedbackFrame = ValueNotifier<int>(0);
    _indicatorFrame = ValueNotifier<int>(0);
    _syncActorRenderTargets();
    _resetCameraRenderPosition();
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
    _nextFeedbackId = 0;
    _hitFlashRemaining.clear();
    _hpEmphasisRemaining.clear();
    _actionPulseRemaining.clear();
    _actorRenderMotions.clear();
    _actorPaintOrder.clear();
    _lastActorLayerTick = null;
    _syncActorRenderTargets();
    _resetCameraRenderPosition();
    _paused = false;
    _primaryAttackHeld = false;
    _primaryAttackKeyHeld = false;
    _heldMovementKeys.clear();
    _pointerAimDirection = null;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _ticker.dispose();
    _feedbackFrame.dispose();
    _indicatorFrame.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _acceptsBattleInput =>
      widget.botCommandBuilder == null &&
      !_paused &&
      widget.controller.outcome == Phase0aBattleOutcome.ongoing;

  ArenaVector _pointerAim(Offset localPosition, Phase0aStage stage) {
    final player = widget.controller.state.player;
    final delta = stage.screenToWorld(localPosition) - player.position;
    return delta.lengthSquared > 0 ? delta.normalized() : player.facing;
  }

  ArenaVector _nearestEnemyAim() {
    final state = widget.controller.state;
    final player = state.player;
    Phase0aActor? nearest;
    var nearestDistance = double.infinity;
    for (final enemy in state.enemies) {
      if (!enemy.isAlive) continue;
      final distance = (enemy.position - player.position).lengthSquared;
      if (distance < nearestDistance) {
        nearest = enemy;
        nearestDistance = distance;
      }
    }
    if (nearest == null) return player.facing;
    final delta = nearest.position - player.position;
    return delta.lengthSquared > 0 ? delta.normalized() : player.facing;
  }

  ArenaVector? _heldAttackAim() {
    if (_primaryAttackHeld) return _pointerAimDirection;
    if (_primaryAttackKeyHeld) return _nearestEnemyAim();
    return null;
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

  void _clearHeldInput() {
    _primaryAttackKeyHeld = false;
    _heldMovementKeys.clear();
    _stopPointerAttack();
  }

  List<Phase0aActor> _currentActors() => <Phase0aActor>[
    widget.controller.state.player,
    ...widget.controller.state.enemies,
  ];

  void _syncActorRenderTargets({bool preserveAdvancingSlash = false}) {
    final actors = _currentActors();
    final actorIds = actors.map((actor) => actor.id).toSet();
    _actorRenderMotions.removeWhere((id, _) => !actorIds.contains(id));
    final advancingActorIds = preserveAdvancingSlash
        ? {
            for (final event in widget.controller.lastEvents)
              if (event is Phase0aAttackStarted &&
                  event.basicAttackSegment?.id == swordBasicAttackSegmentIds[2])
                event.actor,
          }
        : const <String>{};
    for (final actor in actors) {
      final motion = _actorRenderMotions.putIfAbsent(
        actor.id,
        () => Phase0aActorRenderMotion(actor.position),
      );
      final advancingSlash = advancingActorIds.contains(actor.id);
      motion.retarget(
        actor.position,
        durationSeconds: advancingSlash
            ? Phase0aPresentationTokens.basicAttackAdvanceRenderSeconds
            : widget.controller.fixedDeltaSeconds,
        preserveUntilComplete: advancingSlash,
      );
    }
  }

  bool _advanceActorRenderMotions(double deltaSeconds) {
    var changed = false;
    for (final motion in _actorRenderMotions.values) {
      changed = motion.advance(deltaSeconds) || changed;
    }
    final playerRenderPosition = _actorRenderPosition(
      widget.controller.state.player,
    );
    final previousCamera = _cameraRenderPosition ?? playerRenderPosition;
    final nextCamera = Phase0aCameraDeadZone.follow(
      current: previousCamera,
      target: playerRenderPosition,
      halfWidth: Phase0aPresentationTokens.cameraDeadZoneHalfWidth,
      halfHeight: Phase0aPresentationTokens.cameraDeadZoneHalfHeight,
    );
    if (nextCamera != previousCamera) {
      _cameraRenderPosition = nextCamera;
      changed = true;
    }
    return changed;
  }

  void _resetCameraRenderPosition() {
    _cameraRenderPosition = _actorRenderPosition(
      widget.controller.state.player,
    );
  }

  ArenaVector _actorRenderPosition(Phase0aActor actor) =>
      _actorRenderMotions[actor.id]?.current ?? actor.position;

  List<Phase0aActor> _stableActorPaintOrder(
    List<Phase0aActor> actors,
    Phase0aStage stage,
    Map<String, ArenaVector> renderPositions,
  ) {
    final tick = widget.controller.state.tick;
    final previousTick = _lastActorLayerTick;
    if (previousTick != null && tick < previousTick) {
      _actorPaintOrder.clear();
    }
    _lastActorLayerTick = tick;

    final actorById = <String, Phase0aActor>{
      for (final actor in actors) actor.id: actor,
    };
    _actorPaintOrder.removeWhere((id) => !actorById.containsKey(id));

    final footYById = <String, double>{
      for (final actor in actors)
        actor.id: stage.worldToScreen(renderPositions[actor.id]!).dy,
    };
    final initialOrder = stage.sortActors(
      actors,
      positionOf: (actor) => renderPositions[actor.id]!,
    );
    for (final actor in initialOrder) {
      if (_actorPaintOrder.contains(actor.id)) continue;
      final insertAt = _actorPaintOrder.indexWhere((otherId) {
        final byY = footYById[actor.id]!.compareTo(footYById[otherId]!);
        return byY < 0 || (byY == 0 && actor.id.compareTo(otherId) < 0);
      });
      _actorPaintOrder.insert(
        insertAt < 0 ? _actorPaintOrder.length : insertAt,
        actor.id,
      );
    }

    // 既有前后关系只有在实际渲染脚底越过滞回带后才交换。相邻交换
    // 循环同时覆盖正反两个方向，也不会引入玩家或阵营优先级。
    var changed = true;
    while (changed) {
      changed = false;
      for (var index = 0; index < _actorPaintOrder.length - 1; index++) {
        final backId = _actorPaintOrder[index];
        final frontId = _actorPaintOrder[index + 1];
        if (footYById[backId]! <=
            footYById[frontId]! +
                Phase0aPresentationTokens.actorLayerHysteresisPixels) {
          continue;
        }
        _actorPaintOrder[index] = frontId;
        _actorPaintOrder[index + 1] = backId;
        changed = true;
      }
    }

    return <Phase0aActor>[for (final id in _actorPaintOrder) actorById[id]!];
  }

  bool _isMovementKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.keyA ||
      key == LogicalKeyboardKey.keyD ||
      key == LogicalKeyboardKey.keyW ||
      key == LogicalKeyboardKey.keyS;

  Phase0aPlayerCommand _heldCommand() => Phase0aPlayerCommand(
    left: _heldMovementKeys.contains(LogicalKeyboardKey.keyA),
    right: _heldMovementKeys.contains(LogicalKeyboardKey.keyD),
    up: _heldMovementKeys.contains(LogicalKeyboardKey.keyW),
    down: _heldMovementKeys.contains(LogicalKeyboardKey.keyS),
    attack: _primaryAttackKeyHeld || _primaryAttackHeld,
    attackAimDirection: _heldAttackAim(),
  );

  void _enqueueHeldInput() {
    if (!_acceptsBattleInput) return;
    final command = _heldCommand();
    if (command.left ||
        command.right ||
        command.up ||
        command.down ||
        command.attack) {
      widget.controller.enqueue(command);
    }
  }

  void _refresh() {
    _syncActorRenderTargets(preserveAdvancingSlash: true);
    if (widget.controller.outcome != Phase0aBattleOutcome.ongoing) {
      _clearHeldInput();
    }
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
        if (!_reserveDamagePopupResident(entry)) continue;
        if (entry.kind == Phase0aVfxKind.skillCast && entry.actorId != null) {
          _actionPulseRemaining[entry.actorId!] =
              Phase0aPresentationTokens.actorActionPulseSeconds;
        }
        if (_isAttackFeedback(entry.kind)) {
          if (entry.actorId != null) {
            _actionPulseRemaining[entry.actorId!] =
                Phase0aPresentationTokens.actorActionPulseSeconds;
          }
          _heldFeedback.removeWhere(
            (held) => _isAttackFeedback(held.entry.kind),
          );
        } else if (_isBossMechanicFeedback(entry.kind)) {
          _heldFeedback.removeWhere(
            (held) => _isBossMechanicFeedback(held.entry.kind),
          );
        } else if (_isSingletonFeedback(entry.kind)) {
          _heldFeedback.removeWhere((held) => held.entry.kind == entry.kind);
        }
        _heldFeedback.add(
          _HeldFeedback(
            id: _nextFeedbackId++,
            entry: entry,
            lifetimeSeconds: _feedbackLifetime(entry.kind),
          ),
        );
      }
      _scheduleDamagePopupAggregation(widget.controller.feedback);
      final overflow =
          _heldFeedback.length - Phase0aPresentationTokens.maxEntries;
      if (overflow > 0) _heldFeedback.removeRange(0, overflow);
    }
    if (mounted) setState(() {});
  }

  bool _reserveDamagePopupResident(Phase0aVfxEntry incoming) {
    if (incoming.kind != Phase0aVfxKind.damagePopup) return true;
    if (_mergeStatusDamagePopup(incoming)) return false;
    final targetId = incoming.targetId;
    if (targetId != null) {
      while (true) {
        final sameTarget = _heldFeedback
            .where(
              (held) =>
                  held.entry.kind == Phase0aVfxKind.damagePopup &&
                  held.entry.targetId == targetId,
            )
            .toList();
        if (sameTarget.length <
            Phase0aPresentationTokens.maxResidentDamagePopupsPerTarget) {
          break;
        }
        if (!_evictDamagePopup(sameTarget, incoming)) return false;
      }
    }

    while (true) {
      final residents = _heldFeedback
          .where((held) => held.entry.kind == Phase0aVfxKind.damagePopup)
          .toList();
      if (residents.length <
          Phase0aPresentationTokens.maxResidentDamagePopups) {
        break;
      }
      if (!_evictDamagePopup(residents, incoming)) return false;
    }
    return true;
  }

  bool _mergeStatusDamagePopup(Phase0aVfxEntry incoming) {
    final windowKey = incoming.statusDamageWindowKey;
    if (windowKey == null) return false;
    final index = _heldFeedback.indexWhere(
      (held) =>
          held.entry.statusDamageWindowKey == windowKey &&
          held.elapsedSeconds <= Phase0aPresentationTokens.damagePopupSeconds,
    );
    if (index < 0) return false;
    final resident = _heldFeedback[index];
    final residentEntry = resident.entry;
    _heldFeedback[index] = _HeldFeedback(
      id: resident.id,
      entry: Phase0aVfxEntry(
        kind: Phase0aVfxKind.damagePopup,
        targetId: incoming.targetId,
        damage: (residentEntry.damage ?? 0) + (incoming.damage ?? 0),
        isCritical: residentEntry.isCritical || incoming.isCritical,
        damageGroupId: incoming.damageGroupId,
        statusDamageWindowKey: windowKey,
        damageTargetClass: incoming.damageTargetClass,
        hitCount: residentEntry.hitCount + incoming.hitCount,
        anchor: incoming.anchor ?? residentEntry.anchor,
      ),
      lifetimeSeconds: _feedbackLifetime(Phase0aVfxKind.damagePopup),
    );
    return true;
  }

  bool _evictDamagePopup(
    List<_HeldFeedback> residents,
    Phase0aVfxEntry incoming,
  ) {
    final eviction = Phase0aDamagePopupResidentPolicy.evictionIndex(
      residents.map((held) => held.entry).toList(),
      incoming,
    );
    if (eviction < 0) return false;
    _heldFeedback.remove(residents[eviction]);
    return true;
  }

  void _scheduleDamagePopupAggregation(List<Phase0aVfxEntry> feedback) {
    final aggregates = const Phase0aDamagePopupAggregator()
        .collapse(feedback)
        .where(
          (entry) =>
              entry.kind == Phase0aVfxKind.damagePopup && entry.hitCount > 1,
        )
        .toList();
    if (aggregates.isEmpty) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var changed = false;
      for (final aggregate in aggregates) {
        final groupId = aggregate.damageGroupId;
        final before = _heldFeedback.length;
        _heldFeedback.removeWhere(
          (held) =>
              held.entry.kind == Phase0aVfxKind.damagePopup &&
              held.entry.damageGroupId == groupId &&
              held.entry.damageTargetClass ==
                  Phase0aDamagePopupTargetClass.ordinaryEnemy,
        );
        changed = changed || _heldFeedback.length != before;
        if (!_reserveDamagePopupResident(aggregate)) continue;
        _heldFeedback.add(
          _HeldFeedback(
            id: _nextFeedbackId++,
            entry: aggregate,
            lifetimeSeconds: _feedbackLifetime(aggregate.kind),
          ),
        );
        changed = true;
      }
      if (changed) setState(() {});
    });
  }

  static bool _isSingletonFeedback(Phase0aVfxKind kind) => switch (kind) {
    Phase0aVfxKind.meleeSlash ||
    Phase0aVfxKind.palmTrail ||
    Phase0aVfxKind.gatherVortex ||
    Phase0aVfxKind.clearBurst ||
    Phase0aVfxKind.bossChargeWarning ||
    Phase0aVfxKind.bossChargeInterrupted ||
    Phase0aVfxKind.postureBroken ||
    Phase0aVfxKind.guardIntercepted ||
    Phase0aVfxKind.guardianCoop ||
    Phase0aVfxKind.defenseStarted ||
    Phase0aVfxKind.defenseResolved ||
    Phase0aVfxKind.skillCast ||
    Phase0aVfxKind.waveBanner ||
    Phase0aVfxKind.outcomeSeal => true,
    Phase0aVfxKind.damagePopup ||
    Phase0aVfxKind.gatherPull ||
    Phase0aVfxKind.defeatInk ||
    Phase0aVfxKind.skillImpact => false,
  };

  static bool _isAttackFeedback(Phase0aVfxKind kind) =>
      kind == Phase0aVfxKind.meleeSlash || kind == Phase0aVfxKind.palmTrail;

  static bool _isBossMechanicFeedback(Phase0aVfxKind kind) =>
      kind == Phase0aVfxKind.bossChargeWarning ||
      kind == Phase0aVfxKind.bossChargeInterrupted ||
      kind == Phase0aVfxKind.postureBroken ||
      kind == Phase0aVfxKind.guardIntercepted ||
      kind == Phase0aVfxKind.guardianCoop ||
      kind == Phase0aVfxKind.defenseStarted ||
      kind == Phase0aVfxKind.defenseResolved;

  double _feedbackLifetime(Phase0aVfxKind kind) {
    // 视觉验收路由会显式延长 hold，必须继续尊重该公开契约。
    if (widget.feedbackHoldSeconds !=
        Phase0aPresentationTokens.feedbackHoldSeconds) {
      return widget.feedbackHoldSeconds;
    }
    return switch (kind) {
      Phase0aVfxKind.damagePopup =>
        Phase0aPresentationTokens.damagePopupSeconds,
      Phase0aVfxKind.meleeSlash => Phase0aPresentationTokens.meleeVfxSeconds,
      Phase0aVfxKind.palmTrail => Phase0aPresentationTokens.palmTrailSeconds,
      Phase0aVfxKind.skillCast => Phase0aPresentationTokens.skillCastVfxSeconds,
      Phase0aVfxKind.skillImpact =>
        Phase0aPresentationTokens.skillImpactVfxSeconds,
      Phase0aVfxKind.gatherVortex ||
      Phase0aVfxKind.gatherPull => Phase0aPresentationTokens.gatherVfxSeconds,
      Phase0aVfxKind.clearBurst => Phase0aPresentationTokens.clearVfxSeconds,
      Phase0aVfxKind.defeatInk => Phase0aPresentationTokens.defeatVfxSeconds,
      Phase0aVfxKind.bossChargeWarning =>
        Phase0aPresentationTokens.bossChargeFeedbackSeconds,
      Phase0aVfxKind.bossChargeInterrupted =>
        Phase0aPresentationTokens.bossInterruptFeedbackSeconds,
      Phase0aVfxKind.postureBroken =>
        Phase0aPresentationTokens.postureBreakFeedbackSeconds,
      Phase0aVfxKind.guardIntercepted =>
        Phase0aPresentationTokens.guardMechanicFeedbackSeconds,
      Phase0aVfxKind.guardianCoop =>
        Phase0aPresentationTokens.guardMechanicFeedbackSeconds,
      Phase0aVfxKind.defenseStarted || Phase0aVfxKind.defenseResolved =>
        Phase0aPresentationTokens.defenseFeedbackSeconds,
      Phase0aVfxKind.waveBanner || Phase0aVfxKind.outcomeSeal =>
        Phase0aPresentationTokens.feedbackHoldSeconds,
    };
  }

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
    final actorRenderingChanged = _advanceActorRenderMotions(deltaSeconds);
    for (final held in _heldFeedback) {
      held.remainingSeconds -= deltaSeconds;
      held.elapsedSeconds += deltaSeconds;
    }
    final previousFeedbackCount = _heldFeedback.length;
    _heldFeedback.removeWhere((held) => held.remainingSeconds <= 0);
    if (_heldFeedback.isNotEmpty) _feedbackFrame.value++;
    _indicatorFrame.value++;
    final transientChanged =
        _advanceActorTimers(_hitFlashRemaining, deltaSeconds) |
        _advanceActorTimers(_hpEmphasisRemaining, deltaSeconds) |
        _advanceActorTimers(_actionPulseRemaining, deltaSeconds);
    if ((previousFeedbackCount != _heldFeedback.length ||
            transientChanged ||
            actorRenderingChanged) &&
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
      // Held input is sampled once per fixed simulation tick. It does not
      // depend on OS key-repeat cadence and therefore stays deterministic.
      final botCommandBuilder = widget.botCommandBuilder;
      if (botCommandBuilder == null) {
        _enqueueHeldInput();
        widget.controller.step();
      } else {
        widget.controller.step(botCommandBuilder(widget.controller.state));
      }
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
      _actorRenderMotions.clear();
      _actorPaintOrder.clear();
      _lastActorLayerTick = null;
      _syncActorRenderTargets();
      _resetCameraRenderPosition();
      _clearHeldInput();
      _heldFeedback.clear();
      _hitFlashRemaining.clear();
      _hpEmphasisRemaining.clear();
      _actionPulseRemaining.clear();
      _accumulatorSeconds = 0;
      _lastElapsed = null;
      _paused = false;
    } finally {
      if (mounted) setState(() => _retryInFlight = false);
    }
    _focusNode.requestFocus();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyUpEvent) {
      if (_isMovementKey(key)) {
        _heldMovementKeys.remove(key);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyJ) {
        _primaryAttackKeyHeld = false;
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (event is KeyRepeatEvent &&
        (_isMovementKey(key) || key == LogicalKeyboardKey.keyJ)) {
      // Held movement/attack is sampled once per fixed tick. Consuming the
      // platform repeat prevents macOS from treating it as an unhandled key
      // (the audible alert) without enqueueing duplicate gameplay commands.
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (widget.controller.outcome != Phase0aBattleOutcome.ongoing) {
      _clearHeldInput();
      // 终局态唯一有效键:Enter = 再战(9B)。
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          widget.retryFlowBuilder != null &&
          !_retryInFlight) {
        _retry();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    // Esc 暂停/继续(0C,spec §3.1):仅进行中可暂停;暂停中除 Esc 外不受理。
    if (key == LogicalKeyboardKey.escape) {
      setState(() {
        _paused = !_paused;
        if (_paused) _clearHeldInput();
        if (!_paused) _lastElapsed = null; // 恢复首帧重建 delta 基准,不吞暂停时长
      });
      return KeyEventResult.handled;
    }
    if (_paused) return KeyEventResult.ignored;
    if (_isMovementKey(key)) {
      _heldMovementKeys.add(key);
      widget.controller.enqueue(_heldCommand());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyJ) {
      _primaryAttackKeyHeld = true;
      widget.controller.enqueue(_heldCommand());
      return KeyEventResult.handled;
    }
    final command = switch (key) {
      LogicalKeyboardKey.space => const Phase0aPlayerCommand(
        defenseAction: Phase0aDefenseAction.dodge,
      ),
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
      onFocusChange: (focused) {
        if (!focused) _clearHeldInput();
      },
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: WuxiaUi.ink,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final stage = Phase0aStage(
              viewport: size,
              cameraCenter:
                  _cameraRenderPosition ??
                  _actorRenderPosition(controller.state.player),
            );
            final offscreenIndicators = selectPhase0aOffscreenIndicators(
              state: controller.state,
              stage: stage,
              roster: controller.roster,
              positionOf: _actorRenderPosition,
            );
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
                              Phase0aParallaxBackground(
                                cameraOffset: stage.cameraWorldRect.center,
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
                          entries: _heldFeedback,
                          feedbackFrame: _feedbackFrame,
                          numericSkillBindings: widget.numericSkillBindings,
                        ),
                        if (offscreenIndicators.isNotEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                key: const ValueKey(
                                  'phase0a_offscreen_indicators',
                                ),
                                painter: Phase0aOffscreenIndicatorPainter(
                                  indicators: offscreenIndicators,
                                  frame: _indicatorFrame,
                                ),
                              ),
                            ),
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
                if (controller.state.winCondition?.isSurviveTicks == true)
                  _SurviveConditionBanner(
                    requiredTicks:
                        controller.state.winCondition!.surviveTicksRequired!,
                    currentTick: controller.state.tick,
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
    final currentActors = _currentActors();
    final renderPositions = <String, ArenaVector>{
      for (final actor in currentActors) actor.id: _actorRenderPosition(actor),
    };
    final actors = _stableActorPaintOrder(
      currentActors,
      stage,
      renderPositions,
    );
    return [
      for (final actor in actors)
        _positionedActor(controller, stage, actor, renderPositions[actor.id]!),
    ];
  }

  Widget _positionedActor(
    Phase0aBattleController controller,
    Phase0aStage stage,
    Phase0aActor actor,
    ArenaVector renderPosition,
  ) {
    final foot = stage.worldToScreen(renderPosition);
    final scale = stage.depthScale(renderPosition.y);
    final width = Phase0aPresentationTokens.actorWidth * scale;
    final height = Phase0aPresentationTokens.actorHeight * scale;
    final guardianLabelOffsetX = _guardianLabelOffsetX(
      controller.state.enemies,
      actor,
    );
    final guardianWardActive =
        actor.side == Phase0aSide.enemy &&
        actor.guardianWardMult != null &&
        actor.guardianDefIds.isNotEmpty &&
        controller.state.enemies.any(
          (guardian) =>
              guardian.isAlive &&
              actor.guardianDefIds.any(
                (id) => guardian.id == id || guardian.id.startsWith('${id}_w'),
              ),
        );
    return Positioned(
      key: ValueKey('phase0a_actor_position_${actor.id}'),
      left: foot.dx - width / 2,
      top: foot.dy - height,
      width: width,
      height: height,
      child: RepaintBoundary(
        key: ValueKey('phase0a_actor_${actor.id}'),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _ActorStandee(
                key: ValueKey('phase0a_actor_visual_${actor.id}'),
                actor: actor,
                visual: controller.roster.visualFor(actor.id),
                guardianWardActive: guardianWardActive,
                isHitFlashing: _hitFlashRemaining.containsKey(actor.id),
                isHealthEmphasized: _hpEmphasisRemaining.containsKey(actor.id),
                isActionPulsing: _actionPulseRemaining.containsKey(actor.id),
                guardianLabelOffsetX: guardianLabelOffsetX,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox.shrink(
                key: ValueKey('phase0a_standee_${actor.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _guardianLabelOffsetX(
    List<Phase0aActor> enemies,
    Phase0aActor actor,
  ) {
    if (actor.side != Phase0aSide.enemy) return 0;
    final guardianIds = <String>{
      for (final boss in enemies) ...boss.guardianDefIds,
    };
    final guardians = enemies
        .where(
          (candidate) => guardianIds.any(
            (id) => candidate.id == id || candidate.id.startsWith('${id}_w'),
          ),
        )
        .toList();
    final ordered = guardians.toList()
      ..sort((a, b) {
        final byY = a.position.y.compareTo(b.position.y);
        return byY != 0 ? byY : a.id.compareTo(b.id);
      });
    final index = ordered.indexWhere((candidate) => candidate.id == actor.id);
    if (index < 0) return 0;
    final magnitude =
        Phase0aPresentationTokens.guardianLabelLaneOffset * (index ~/ 2 + 1);
    return index.isEven ? -magnitude : magnitude;
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
  _HeldFeedback({
    required this.id,
    required this.entry,
    required this.lifetimeSeconds,
  }) : remainingSeconds = lifetimeSeconds;

  final int id;
  final Phase0aVfxEntry entry;
  final double lifetimeSeconds;
  double remainingSeconds;
  double elapsedSeconds = 0;

  double get progress =>
      (1 - remainingSeconds / lifetimeSeconds).clamp(0.0, 1.0);
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
    required this.isActionPulsing,
    required this.guardianWardActive,
    required this.guardianLabelOffsetX,
  });

  final Phase0aActor actor;
  final Phase0aActorVisual visual;
  final bool isHitFlashing;
  final bool isHealthEmphasized;
  final bool isActionPulsing;
  final bool guardianWardActive;
  final double guardianLabelOffsetX;

  @override
  Widget build(BuildContext context) {
    final enemy = actor.side == Phase0aSide.enemy;
    final accent = visual.isElite
        ? WuxiaUi.gold
        : enemy
        ? WuxiaUi.jiang
        : WuxiaUi.qingOnDark;
    final postureOpen = enemy && (actor.posture?.isVulnerable ?? false);
    final motionOffset = isHitFlashing
        ? Offset(
            -actor.facing.x * Phase0aPresentationTokens.actorHitSlideFraction,
            -actor.facing.y * Phase0aPresentationTokens.actorHitSlideFraction,
          )
        : isActionPulsing
        ? Offset(
            actor.facing.x * Phase0aPresentationTokens.actorActionSlideFraction,
            actor.facing.y * Phase0aPresentationTokens.actorActionSlideFraction,
          )
        : Offset.zero;
    final motionScale = isHitFlashing
        ? Phase0aPresentationTokens.actorHitScale
        : isActionPulsing
        ? Phase0aPresentationTokens.actorActionScale
        : 1.0;
    final motionDuration = Duration(
      microseconds:
          (Phase0aPresentationTokens.actorMotionTweenSeconds *
                  Duration.microsecondsPerSecond)
              .round(),
    );
    final showThreatLabel =
        enemy &&
        (visual.isElite ||
            isHealthEmphasized ||
            actor.vulnerabilityMult != null ||
            actor.chargingCast != null ||
            actor.staggerTicksRemaining > 0 ||
            guardianWardActive ||
            guardianLabelOffsetX != 0);
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          bottom: 0,
          child: Container(
            key: ValueKey('phase0a_ground_mark_${actor.id}'),
            width: visual.isElite
                ? Phase0aPresentationTokens.groundMarkEliteWidth
                : Phase0aPresentationTokens.groundMarkWidth,
            height: Phase0aPresentationTokens.groundMarkHeight,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: Phase0aPresentationTokens.groundMarkFillOpacity,
              ),
              border: Border.all(
                color: accent.withValues(
                  alpha: Phase0aPresentationTokens.groundMarkBorderOpacity,
                ),
                width: Phase0aPresentationTokens.groundMarkBorderWidth,
              ),
              borderRadius: BorderRadius.circular(
                Phase0aPresentationTokens.groundMarkHeight,
              ),
            ),
          ),
        ),
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (guardianWardActive)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: ValueKey('phase0a_guardian_ward_ring'),
                      painter: _GuardianWardRingPainter(),
                    ),
                  ),
                ),
              if (isHitFlashing)
                SizedBox(key: ValueKey('phase0a_impact_${actor.id}')),
              if (isActionPulsing)
                SizedBox(key: ValueKey('phase0a_action_${actor.id}')),
              AnimatedSlide(
                key: ValueKey('phase0a_actor_slide_${actor.id}'),
                offset: motionOffset,
                duration: motionDuration,
                curve: Curves.easeOutCubic,
                child: AnimatedScale(
                  key: ValueKey('phase0a_actor_scale_${actor.id}'),
                  scale: motionScale,
                  duration: motionDuration,
                  curve: Curves.easeOutBack,
                  child: AnimatedRotation(
                    key: postureOpen
                        ? ValueKey('phase0a_posture_unbalanced_${actor.id}')
                        : null,
                    turns: postureOpen
                        ? Phase0aPresentationTokens.postureUnbalancedTurns
                        : 0,
                    duration: motionDuration,
                    curve: Curves.easeOutBack,
                    alignment: Alignment.bottomCenter,
                    child: ColorFiltered(
                      key: isHitFlashing
                          ? ValueKey('phase0a_hit_flash_${actor.id}')
                          : postureOpen
                          ? ValueKey('phase0a_posture_wash_${actor.id}')
                          : null,
                      colorFilter: ColorFilter.mode(
                        (postureOpen ? WuxiaUi.gold : WuxiaUi.paper).withValues(
                          alpha: isHitFlashing
                              ? Phase0aPresentationTokens.hitFlashOpacity
                              : postureOpen
                              ? Phase0aPresentationTokens
                                    .postureUnbalancedWashOpacity
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
                ),
              ),
            ],
          ),
        ),
        if (showThreatLabel)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Transform.translate(
              key: guardianLabelOffsetX == 0
                  ? null
                  : ValueKey('phase0a_guardian_label_lane_${actor.id}'),
              offset: Offset(guardianLabelOffsetX, 0),
              child: _HitEmphasisFrame(
                key: isHealthEmphasized
                    ? ValueKey('phase0a_hp_emphasis_${actor.id}')
                    : null,
                active: isHealthEmphasized,
                accentColor: accent,
                idleFillColor: WuxiaUi.ink.withValues(
                  alpha: Phase0aPresentationTokens.enemyLabelIdleFillOpacity,
                ),
                idleBorderColor: accent.withValues(
                  alpha: Phase0aPresentationTokens.enemyLabelIdleBorderOpacity,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      visual.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: visual.isElite ? WuxiaUi.gold : WuxiaUi.paper,
                        fontSize: Phase0aPresentationTokens.actorNameFontSize,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(color: WuxiaUi.ink, blurRadius: 3),
                        ],
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
          ),
        if (enemy &&
            actor.posture != null &&
            (actor.vulnerabilityMult != null ||
                actor.posture!.isVulnerable ||
                actor.posture!.accumulated > 0))
          Positioned(
            left: 0,
            right: 0,
            top:
                Phase0aPresentationTokens.actorHpHeight +
                Phase0aPresentationTokens.actorNameFontSize +
                Phase0aPresentationTokens.bossStatusGap * 2,
            child: Center(
              child: _PostureBar(
                key: ValueKey(
                  actor.posture!.isVulnerable
                      ? 'phase0a_vulnerability_open_${actor.id}'
                      : actor.vulnerabilityMult != null
                      ? 'phase0a_vulnerability_guarded_${actor.id}'
                      : 'phase0a_posture_bar_${actor.id}',
                ),
                actorId: actor.id,
                accumulated: actor.posture!.accumulated,
                capacity: actor.posture!.config.capacity,
                isVulnerable: actor.posture!.isVulnerable,
                guarded: actor.vulnerabilityMult != null,
              ),
            ),
          ),
        if (enemy && actor.chargingCast != null)
          Positioned(
            left: 0,
            right: 0,
            top:
                Phase0aPresentationTokens.actorHpHeight +
                Phase0aPresentationTokens.actorNameFontSize +
                Phase0aPresentationTokens.bossStatusGap * 9,
            child: Center(
              child: _BossStatusTag(
                key: ValueKey('phase0a_charge_warning_${actor.id}'),
                label:
                    '${UiStrings.phase0aBossChargeWarning} ${actor.chargeTicksRemaining}',
                accent: WuxiaUi.jiang,
              ),
            ),
          ),
        if (enemy && actor.staggerTicksRemaining > 0)
          Positioned(
            left: 0,
            right: 0,
            top:
                Phase0aPresentationTokens.actorHpHeight +
                Phase0aPresentationTokens.actorNameFontSize +
                Phase0aPresentationTokens.bossStatusGap * 9,
            child: Center(
              child: _BossStatusTag(
                key: ValueKey('phase0a_staggered_${actor.id}'),
                label:
                    '${UiStrings.phase0aStaggered} ${actor.staggerTicksRemaining}',
                accent: WuxiaUi.gold,
              ),
            ),
          ),
        if (enemy && guardianWardActive)
          Positioned(
            left: 0,
            right: 0,
            top:
                Phase0aPresentationTokens.actorHpHeight +
                Phase0aPresentationTokens.actorNameFontSize +
                Phase0aPresentationTokens.bossStatusGap * 5,
            child: Center(
              child: _BossStatusTag(
                key: ValueKey('phase0a_guardian_ward_${actor.id}'),
                label: UiStrings.guardianWardActiveLabel,
                accent: WuxiaUi.gold,
              ),
            ),
          ),
      ],
    );
  }
}

class _PostureBar extends StatelessWidget {
  const _PostureBar({
    super.key,
    required this.actorId,
    required this.accumulated,
    required this.capacity,
    required this.isVulnerable,
    required this.guarded,
  });

  final String actorId;
  final double accumulated;
  final double capacity;
  final bool isVulnerable;
  final bool guarded;

  @override
  Widget build(BuildContext context) {
    final fraction = capacity <= 0
        ? 0.0
        : (accumulated / capacity).clamp(0.0, 1.0);
    final accent = isVulnerable
        ? WuxiaUi.gold
        : guarded
        ? WuxiaUi.qingOnDark
        : WuxiaUi.jiang;
    final label = isVulnerable
        ? UiStrings.phase0aVulnerabilityOpen
        : guarded
        ? UiStrings.phase0aVulnerabilityGuarded
        : UiStrings.phase0aPostureLabel;
    return Semantics(
      container: true,
      label: UiStrings.phase0aPostureSemantics(
        accumulated.ceil(),
        capacity.ceil(),
        isVulnerable: isVulnerable,
      ),
      child: SizedBox(
        width: Phase0aPresentationTokens.postureBarWidth,
        height: Phase0aPresentationTokens.postureBarHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: WuxiaUi.ink.withValues(
              alpha: Phase0aPresentationTokens.postureBarTrackOpacity,
            ),
            border: Border.all(
              color: accent,
              width: Phase0aPresentationTokens.postureBarBorderWidth,
            ),
            borderRadius: BorderRadius.circular(
              Phase0aPresentationTokens.postureBarHeight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              Phase0aPresentationTokens.postureBarHeight,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                FractionallySizedBox(
                  key: ValueKey('phase0a_posture_fill_$actorId'),
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: ColoredBox(
                    color: accent.withValues(
                      alpha: Phase0aPresentationTokens.postureBarFillOpacity,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: WuxiaUi.paper,
                      fontSize:
                          Phase0aPresentationTokens.postureBarLabelFontSize,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: WuxiaUi.ink, blurRadius: 2)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BossStatusTag extends StatelessWidget {
  const _BossStatusTag({super.key, required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: WuxiaUi.ink.withValues(alpha: 0.82),
      border: Border.all(
        color: accent,
        width: Phase0aPresentationTokens.bossStatusBorderWidth,
      ),
      borderRadius: BorderRadius.circular(
        Phase0aPresentationTokens.bossStatusRadius,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Phase0aPresentationTokens.bossStatusPaddingH,
        vertical: Phase0aPresentationTokens.bossStatusPaddingV,
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: accent,
          fontSize: Phase0aPresentationTokens.bossStatusFontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _GuardianWardRingPainter extends CustomPainter {
  const _GuardianWardRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      Phase0aPresentationTokens.guardianWardRingInset,
      Phase0aPresentationTokens.guardianWardRingInset,
      size.width - Phase0aPresentationTokens.guardianWardRingInset * 2,
      size.height - Phase0aPresentationTokens.guardianWardRingInset * 2,
    );
    final paint = Paint()
      ..color = WuxiaUi.gold.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = Phase0aPresentationTokens.guardianWardRingStrokeWidth;
    canvas.drawOval(rect, paint);
    canvas.drawArc(rect, -0.8, 1.8, false, paint..color = WuxiaUi.paper);
  }

  @override
  bool shouldRepaint(covariant _GuardianWardRingPainter oldDelegate) => false;
}

class _HitEmphasisFrame extends StatelessWidget {
  const _HitEmphasisFrame({
    super.key,
    required this.active,
    required this.child,
    this.accentColor = WuxiaUi.qingOnDark,
    this.idleFillColor = Colors.transparent,
    this.idleBorderColor = Colors.transparent,
  });

  final bool active;
  final Widget child;
  final Color accentColor;
  final Color idleFillColor;
  final Color idleBorderColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: active
          ? accentColor.withValues(
              alpha: Phase0aPresentationTokens.hpEmphasisFillOpacity,
            )
          : idleFillColor,
      border: Border.all(
        color: active ? accentColor : idleBorderColor,
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
    final defenseAvailable = player.defenseCooldownRemaining <= 0;
    final defenseStatus = defenseAvailable
        ? UiStrings.skillReady
        : UiStrings.phase0aSealCooldown(player.defenseCooldownRemaining);
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
              const SizedBox(height: Phase0aPresentationTokens.hudGap),
              Semantics(
                container: true,
                label: _phase0aDodgeKeyLabel,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    _DefenseActionStatus(
                      actionId: 'dodge',
                      label: _phase0aDodgeKeyLabel,
                      status: defenseStatus,
                      available: defenseAvailable,
                      labelColor: player.dodgeTicksRemaining > 0
                          ? WuxiaUi.qing
                          : WuxiaUi.ink,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefenseActionStatus extends StatelessWidget {
  const _DefenseActionStatus({
    required this.actionId,
    required this.label,
    required this.status,
    required this.available,
    required this.labelColor,
  });

  final String actionId;
  final String label;
  final String status;
  final bool available;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        key: ValueKey<String>('phase0a_defense_label_$actionId'),
        style: TextStyle(
          color: labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        status,
        key: ValueKey<String>('phase0a_defense_status_$actionId'),
        style: TextStyle(
          color: available ? WuxiaUi.jiang : WuxiaUi.muted,
          fontSize: 12,
        ),
      ),
    ],
  );
}

class _FeedbackLayer extends StatefulWidget {
  const _FeedbackLayer({
    required this.controller,
    required this.stage,
    required this.entries,
    required this.feedbackFrame,
    required this.numericSkillBindings,
  });

  final Phase0aBattleController controller;
  final Phase0aStage stage;
  final List<_HeldFeedback> entries;
  final ValueListenable<int> feedbackFrame;
  final Phase0aNumericSkillBindings numericSkillBindings;

  @override
  State<_FeedbackLayer> createState() => _FeedbackLayerState();
}

class _FeedbackLayerState extends State<_FeedbackLayer> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.feedbackFrame,
      builder: (context, _, child) => _buildFeedbackLayer(),
    );
  }

  Widget _buildFeedbackLayer() {
    final children = <Widget>[];
    var popupIndex = 0;
    final orderedEntries = widget.entries.asMap().entries.toList()
      ..sort((left, right) {
        final byPriority = phase0aVfxPaintPriority(
          left.value.entry.kind,
        ).compareTo(phase0aVfxPaintPriority(right.value.entry.kind));
        return byPriority != 0 ? byPriority : left.key.compareTo(right.key);
      });
    for (final indexedEntry in orderedEntries) {
      final held = indexedEntry.value;
      final entry = held.entry;
      switch (entry.kind) {
        case Phase0aVfxKind.damagePopup:
          children.add(_damagePopup(held, popupIndex++));
        case Phase0aVfxKind.meleeSlash:
          children.add(
            _inkVfx(
              held,
              _InkEffect.melee,
              vfxKey: const ValueKey('phase0a_melee_slash'),
            ),
          );
        case Phase0aVfxKind.palmTrail:
          children.add(_palmTrail(held));
        case Phase0aVfxKind.skillCast:
          children.add(_skillVfx(held, _SkillVfxPhase.cast));
        case Phase0aVfxKind.skillImpact:
          children.add(_skillVfx(held, _SkillVfxPhase.impact));
        case Phase0aVfxKind.gatherVortex:
          children.add(
            _inkVfx(
              held,
              _InkEffect.gather,
              vfxKey: const ValueKey('phase0a_gather_vortex'),
            ),
          );
        case Phase0aVfxKind.gatherPull:
          children.add(_gatherPull(held));
        case Phase0aVfxKind.clearBurst:
          children.add(
            _inkVfx(
              held,
              _InkEffect.clear,
              vfxKey: const ValueKey('phase0a_clear_burst'),
            ),
          );
        case Phase0aVfxKind.defeatInk:
          children.add(
            _inkVfx(
              held,
              _InkEffect.defeat,
              vfxKey: const ValueKey('phase0a_defeat_ink'),
              containerKey: ValueKey('phase0a_defeat_ink_${entry.targetId}'),
            ),
          );
        case Phase0aVfxKind.waveBanner:
          children.add(_waveBanner(entry));
        case Phase0aVfxKind.bossChargeWarning:
          children.add(
            _bossMechanicBanner(
              key: const ValueKey('phase0a_boss_charge_banner'),
              label: UiStrings.phase0aBossChargeWarning,
              accent: WuxiaUi.jiang,
            ),
          );
        case Phase0aVfxKind.bossChargeInterrupted:
          children.add(
            _bossMechanicBanner(
              key: const ValueKey('phase0a_boss_interrupt_banner'),
              label: UiStrings.phase0aBossChargeInterrupted,
              accent: WuxiaUi.gold,
            ),
          );
        case Phase0aVfxKind.postureBroken:
          children.add(_postureBreakVfx(held));
        case Phase0aVfxKind.guardIntercepted:
          children.add(
            _guardianMechanicVfx(
              held,
              key: ValueKey('phase0a_guard_intercept_${held.id}'),
              label: UiStrings.phase0aGuardianIntercepted,
              accent: WuxiaUi.gold,
            ),
          );
        case Phase0aVfxKind.guardianCoop:
          children.add(
            _guardianMechanicVfx(
              held,
              key: ValueKey('phase0a_guardian_coop_${held.id}'),
              label: UiStrings.coopStrikeCaption,
              accent: WuxiaUi.jiang,
            ),
          );
        case Phase0aVfxKind.defenseStarted:
          children.add(
            _bossMechanicBanner(
              key: ValueKey('phase0a_defense_start_${held.id}'),
              label: _phase0aDodgeKeyLabel,
              accent: WuxiaUi.qingOnDark,
            ),
          );
        case Phase0aVfxKind.defenseResolved:
          children.add(
            _bossMechanicBanner(
              key: ValueKey('phase0a_defense_resolved_${held.id}'),
              label: _phase0aDodgeKeyLabel,
              accent: WuxiaUi.gold,
            ),
          );
        case Phase0aVfxKind.outcomeSeal:
          break;
      }
    }
    if (widget.controller.outcome != Phase0aBattleOutcome.ongoing) {
      children.add(_outcomeSeal(widget.controller.outcome));
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          key: const ValueKey('phase0a_feedback_layer'),
          child: Stack(
            key: const ValueKey('phase0a_feedback_stack'),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _postureBreakVfx(_HeldFeedback held) {
    final entry = held.entry;
    final anchor = entry.anchor;
    if (anchor == null) return const SizedBox.shrink();
    final screen = widget.stage.worldToScreen(anchor);
    const size = Phase0aPresentationTokens.postureBreakVfxSize;
    final targetKey = entry.targetId ?? '${held.id}';
    return Positioned(
      key: ValueKey('phase0a_posture_break_$targetKey'),
      left: screen.dx - size / 2,
      top: screen.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: _feedbackOpacity(held.progress),
        child: Transform.scale(
          scale: 0.72 + 0.28 * Curves.easeOutBack.transform(held.progress),
          child: CustomPaint(
            key: ValueKey('phase0a_posture_break_paint_$targetKey'),
            size: const Size.square(size),
            painter: _PostureBreakPainter(progress: held.progress),
            child: const Center(
              child: Text(
                UiStrings.phase0aPostureBroken,
                style: TextStyle(
                  color: WuxiaUi.gold,
                  fontSize: Phase0aPresentationTokens.vfxOutcomeFontSize,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: WuxiaUi.ink, blurRadius: 5),
                    Shadow(color: WuxiaUi.paper, blurRadius: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bossMechanicBanner({
    required Key key,
    required String label,
    required Color accent,
  }) {
    final left =
        (widget.stage.safeRect.center.dx -
                Phase0aPresentationTokens.vfxBannerWidth / 2)
            .clamp(
              widget.stage.safeRect.left,
              widget.stage.safeRect.right -
                  Phase0aPresentationTokens.vfxBannerWidth,
            )
            .toDouble();
    final top =
        (Phase0aPresentationTokens.vfxBannerTop +
                Phase0aPresentationTokens.vfxBannerHeight +
                Phase0aPresentationTokens.bossMechanicBannerTopGap)
            .clamp(
              widget.stage.safeRect.top,
              widget.stage.safeRect.bottom -
                  Phase0aPresentationTokens.vfxBannerHeight,
            )
            .toDouble();
    return Positioned(
      key: key,
      left: left,
      top: top,
      width: Phase0aPresentationTokens.vfxBannerWidth,
      height: Phase0aPresentationTokens.vfxBannerHeight,
      child: CustomPaint(
        painter: const _PaperBannerPainter(),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: Phase0aPresentationTokens.vfxOutcomeFontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _guardianMechanicVfx(
    _HeldFeedback held, {
    required Key key,
    required String label,
    required Color accent,
  }) {
    final entry = held.entry;
    final source = entry.source;
    final target = entry.vfxTarget;
    if (source == null || target == null) return const SizedBox.shrink();
    final screenSource = widget.stage.worldToScreen(source);
    final screenTarget = widget.stage.worldToScreen(target);
    final left = math.min(screenSource.dx, screenTarget.dx) - 48;
    final top = math.min(screenSource.dy, screenTarget.dy) - 48;
    final width = (screenSource.dx - screenTarget.dx).abs() + 96;
    final height = (screenSource.dy - screenTarget.dy).abs() + 96;
    return Positioned(
      key: key,
      left: left,
      top: top,
      width: width,
      height: height,
      child: Opacity(
        opacity: _feedbackOpacity(held.progress),
        child: CustomPaint(
          painter: _GuardianMechanicPainter(
            source: screenSource - Offset(left, top),
            target: screenTarget - Offset(left, top),
            accent: accent,
            progress: held.progress,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: _BossStatusTag(label: label, accent: accent),
          ),
        ),
      ),
    );
  }

  Widget _damagePopup(_HeldFeedback held, int index) {
    final entry = held.entry;
    final isAggregate = entry.hitCount > 1;
    // 使用事件发生时的世界坐标快照(entry.anchor),不反查当前 state。
    // 目标死亡后已从 controller.state 移除,直接查 id 会 fallback
    // 到屏幕中心,导致伤害数字位置错误。
    final anchor = entry.anchor != null
        ? widget.stage.worldToScreen(entry.anchor!)
        : widget.stage.safeRect.center;
    const aggregateWidth = 180.0;
    final left = isAggregate
        ? (anchor.dx - aggregateWidth / 2)
              .clamp(
                widget.stage.safeRect.left,
                widget.stage.safeRect.right - aggregateWidth,
              )
              .toDouble()
        : anchor.dx;
    return Positioned(
      key: ValueKey('phase0a_popup_${held.id}'),
      left: left,
      top:
          anchor.dy -
          Phase0aPresentationTokens.actorHeight -
          Phase0aPresentationTokens.vfxPopupLift -
          index * Phase0aPresentationTokens.vfxPopupGap,
      width: isAggregate ? aggregateWidth : null,
      child: Opacity(
        opacity: _feedbackOpacity(held.progress),
        child: Transform.translate(
          offset: Offset(isAggregate ? 0 : -12, -held.progress * 64),
          child: Transform.scale(
            scale:
                0.84 +
                0.16 *
                    Curves.easeOut.transform(
                      (held.progress / 0.28).clamp(0.0, 1.0),
                    ),
            child: Text(
              isAggregate
                  ? '${entry.damage} ×${entry.hitCount}'
                  : '${entry.damage}',
              key: isAggregate
                  ? ValueKey<String>(
                      'phase0a_damage_group_${entry.damageGroupId}',
                    )
                  : null,
              textAlign: isAggregate ? TextAlign.center : null,
              style: TextStyle(
                color: entry.isCritical ? WuxiaUi.jiang : WuxiaUi.ink,
                fontSize: Phase0aPresentationTokens.vfxPopupFontSize,
                fontWeight: FontWeight.w900,
                shadows: entry.isCritical
                    ? const [
                        Shadow(color: WuxiaUi.gold, blurRadius: 7),
                        Shadow(color: WuxiaUi.paper, blurRadius: 2),
                        Shadow(color: WuxiaUi.ink, blurRadius: 1),
                      ]
                    : const [
                        Shadow(color: WuxiaUi.paper, blurRadius: 1),
                        Shadow(color: WuxiaUi.paper, blurRadius: 4),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 掌风轨迹:出手者→目标连线的世界坐标映射到屏幕,
  /// 以连线中点为中心、以连线方向为旋转角度绘制。
  Widget _palmTrail(_HeldFeedback held) {
    final entry = held.entry;
    final src = entry.source;
    final dst = entry.vfxTarget;
    if (src == null || dst == null) {
      return const SizedBox.shrink();
    }
    final screenSrc = widget.stage.worldToScreen(src);
    final screenDst = widget.stage.worldToScreen(dst);
    final mid = Offset(
      (screenSrc.dx + screenDst.dx) / 2,
      (screenSrc.dy + screenDst.dy) / 2,
    );
    final angle = math.atan2(
      screenDst.dy - screenSrc.dy,
      screenDst.dx - screenSrc.dx,
    );
    final distance = (screenDst - screenSrc).distance;
    final width = distance + Phase0aPresentationTokens.palmTrailPadding * 2;
    final height = Phase0aPresentationTokens.palmTrailHeight;
    return Positioned(
      key: ValueKey('phase0a_palm_trail_${held.id}'),
      left: mid.dx - width / 2,
      top: mid.dy - height / 2,
      width: width,
      height: height,
      child: Opacity(
        opacity: _feedbackOpacity(held.progress),
        child: Transform.rotate(
          angle: angle,
          child: KeyedSubtree(
            key: entry.basicAttackSegmentId == null
                ? null
                : ValueKey(
                    'phase0a_sword_segment_${entry.basicAttackSegmentId}',
                  ),
            child: CustomPaint(
              key: const ValueKey('phase0a_palm_trail'),
              size: Size(width, height),
              painter: _InkEffectPainter(
                _InkEffect.palm,
                progress: held.progress,
                isCritical: entry.isCritical,
                basicAttackSegmentId: entry.basicAttackSegmentId,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 数字技能两段墨势。流派只取正式 binding 的 typed 语义，且同时核对
  /// hotkey / skillId，避免槽位换装后把旧事件画成另一招。
  Widget _skillVfx(_HeldFeedback held, _SkillVfxPhase phase) {
    final entry = held.entry;
    final hotkey = entry.hotkey;
    final skillId = entry.skillId;
    final anchor = entry.anchor;
    if (hotkey == null || skillId == null || anchor == null) {
      return const SizedBox.shrink();
    }
    final binding = widget.numericSkillBindings.bindingFor(hotkey);
    if (binding == null || binding.skill.id != skillId) {
      return const SizedBox.shrink();
    }
    final isUltimate = binding.skill.type == SkillType.ultimate;
    final baseSize = phase == _SkillVfxPhase.cast
        ? Phase0aPresentationTokens.skillCastVfxSize
        : Phase0aPresentationTokens.skillImpactVfxSize;
    final size =
        baseSize *
        (isUltimate ? Phase0aPresentationTokens.skillUltimateVfxScale : 1);
    final screen = widget.stage.worldToScreen(anchor);
    final keyStem = 'phase0a_skill_${phase.name}_${binding.visualSchool.name}';
    return Positioned(
      key: ValueKey('${keyStem}_${held.id}'),
      left: screen.dx - size / 2,
      top: screen.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: _feedbackOpacity(held.progress),
        child: Transform.scale(
          scale: 0.74 + 0.26 * Curves.easeOut.transform(held.progress),
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
              key: ValueKey('${keyStem}_paint_${held.id}'),
              size: Size.square(size),
              painter: _SkillVfxPainter(
                school: binding.visualSchool,
                phase: phase,
                progress: held.progress,
                isUltimate: isUltimate,
                isAoe: binding.targetType == TargetType.aoe,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Q 拉拢轨迹:以事件发生时的目标→玩家快照绘制弯曲墨线。
  Widget _gatherPull(_HeldFeedback held) {
    final entry = held.entry;
    final source = entry.source;
    final target = entry.vfxTarget;
    final targetId = entry.targetId;
    if (source == null || target == null || targetId == null) {
      return const SizedBox.shrink();
    }
    final screenSource = widget.stage.worldToScreen(source);
    final screenTarget = widget.stage.worldToScreen(target);
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
      child: Opacity(
        opacity: _feedbackOpacity(held.progress),
        child: CustomPaint(
          key: ValueKey('phase0a_gather_pull_$targetId'),
          painter: _GatherPullPainter(
            source: screenSource - Offset(left, top),
            target: screenTarget - Offset(left, top),
          ),
        ),
      ),
    );
  }

  /// 单点水墨 VFX(近战墨痕 / Q 涡旋 / R 墨爆 / 死亡墨散):
  /// 以 [Phase0aVfxEntry.anchor] 的世界坐标快照映射到屏幕。
  Widget _inkVfx(
    _HeldFeedback held,
    _InkEffect effect, {
    required Key vfxKey,
    Key? containerKey,
  }) {
    final entry = held.entry;
    final anchor = entry.anchor;
    if (anchor == null) {
      return const SizedBox.shrink();
    }
    final screen = widget.stage.worldToScreen(anchor);
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
      child: Opacity(
        opacity: _feedbackOpacity(held.progress),
        child: Transform.scale(
          scale: 0.78 + 0.22 * Curves.easeOut.transform(held.progress),
          child: SizedBox.square(
            key:
                containerKey ??
                (entry.basicAttackSegmentId == null
                    ? null
                    : ValueKey(
                        'phase0a_sword_segment_${entry.basicAttackSegmentId}',
                      )),
            dimension: size,
            child: CustomPaint(
              key: vfxKey,
              size: Size.square(size),
              painter: _InkEffectPainter(
                effect,
                defeatKind: entry.defeatKind,
                progress: held.progress,
                isCritical: entry.isCritical,
                basicAttackSegmentId: entry.basicAttackSegmentId,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _feedbackOpacity(double progress) {
    if (progress < 0.16) return progress / 0.16;
    if (progress < 0.68) return 1;
    return (1 - progress) / 0.32;
  }

  Widget _waveBanner(Phase0aVfxEntry entry) => Positioned(
    key: const ValueKey('phase0a_wave_banner'),
    top: Phase0aPresentationTokens.vfxBannerTop,
    left:
        (widget.stage.viewport.width -
            Phase0aPresentationTokens.vfxBannerWidth) /
        2,
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
            outcome == Phase0aBattleOutcome.victory &&
                    widget.controller.state.winCondition?.isSurviveTicks == true
                ? UiStrings.battleResultSurvived
                : outcome == Phase0aBattleOutcome.victory
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

final class _SurviveConditionBanner extends StatelessWidget {
  const _SurviveConditionBanner({
    required this.requiredTicks,
    required this.currentTick,
  });

  final int requiredTicks;
  final int currentTick;

  @override
  Widget build(BuildContext context) {
    final remaining = (requiredTicks - currentTick).clamp(0, requiredTicks);
    final met = remaining == 0;
    return Positioned(
      key: const ValueKey('phase0a_survive_condition_banner'),
      top: Phase0aPresentationTokens.hudInset,
      left: Phase0aPresentationTokens.hudInset,
      child: Semantics(
        label: met
            ? UiStrings.surviveConditionMet(requiredTicks)
            : UiStrings.surviveConditionRemaining(requiredTicks, remaining),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xD9E8D8B8),
            border: Border.all(
              color: met ? WuxiaUi.gold : const Color(0xB36D5940),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(
              met
                  ? UiStrings.surviveConditionMet(requiredTicks)
                  : UiStrings.surviveConditionRemaining(
                      requiredTicks,
                      remaining,
                    ),
              style: TextStyle(
                color: WuxiaUi.ink,
                fontSize: 16,
                fontWeight: met ? FontWeight.w700 : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostureBreakPainter extends CustomPainter {
  const _PostureBreakPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final reveal = Curves.easeOutCubic.transform(
      Phase0aPresentationTokens.vfxReveal(progress),
    );
    final fade = Phase0aPresentationTokens.vfxFade(progress);
    final radius = size.shortestSide * 0.39 * reveal;
    final ink = Paint()
      ..color = WuxiaUi.ink.withValues(alpha: 0.82 * fade)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = Phase0aPresentationTokens.vfxStrokeWidth;
    final gold = Paint()
      ..color = WuxiaUi.gold.withValues(alpha: 0.72 * fade)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = Phase0aPresentationTokens.vfxThinStrokeWidth;
    final ring = Rect.fromCircle(center: center, radius: radius);
    const segments = 6;
    for (var i = 0; i < segments; i++) {
      final start = math.pi * 2 * i / segments + 0.08;
      canvas.drawArc(ring, start, math.pi * 0.23, false, i.isEven ? ink : gold);
    }
    const cracks = 8;
    for (var i = 0; i < cracks; i++) {
      final angle = math.pi * 2 * i / cracks;
      final inner =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.18;
      final elbow =
          center +
          Offset(
                math.cos(angle + (i.isEven ? 0.13 : -0.13)),
                math.sin(angle + (i.isEven ? 0.13 : -0.13)),
              ) *
              radius *
              0.58;
      final outer =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              radius *
              (i.isEven ? 1.08 : 0.88);
      canvas.drawPath(
        Path()
          ..moveTo(inner.dx, inner.dy)
          ..lineTo(elbow.dx, elbow.dy)
          ..lineTo(outer.dx, outer.dy),
        i.isEven ? ink : gold,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PostureBreakPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

enum _SkillVfxPhase { cast, impact }

/// 三系共享同一程序化 painter，但几何语言严格分离：
/// 刚猛 = 方折/震裂，灵巧 = 弧影/掠痕，阴柔 = 回旋/涟漪。
class _SkillVfxPainter extends CustomPainter {
  const _SkillVfxPainter({
    required this.school,
    required this.phase,
    required this.progress,
    required this.isUltimate,
    required this.isAoe,
  });

  final TechniqueSchool school;
  final _SkillVfxPhase phase;
  final double progress;
  final bool isUltimate;
  final bool isAoe;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final reveal = Curves.easeOutCubic.transform(
      Phase0aPresentationTokens.vfxReveal(progress),
    );
    final fade = Phase0aPresentationTokens.vfxFade(progress);
    final radius = size.shortestSide * 0.42;
    final accent = switch (school) {
      TechniqueSchool.gangMeng => WuxiaUi.jiang,
      TechniqueSchool.lingQiao => WuxiaUi.gold,
      TechniqueSchool.yinRou => WuxiaUi.qingOnDark,
    };
    final widthScale = isUltimate ? 1.34 : 1.0;
    final ink = Paint()
      ..color = WuxiaUi.ink.withValues(alpha: 0.78 * fade)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = Phase0aPresentationTokens.vfxStrokeWidth * widthScale;
    final wash = Paint()
      ..color = accent.withValues(alpha: 0.68 * fade)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = Phase0aPresentationTokens.vfxThinStrokeWidth * widthScale;

    if (phase == _SkillVfxPhase.cast) {
      _paintCast(canvas, center, radius, reveal, ink, wash);
    } else {
      _paintImpact(canvas, center, radius, reveal, ink, wash);
    }

    if (isAoe) {
      canvas.drawCircle(
        center,
        radius * (0.62 + 0.34 * reveal),
        Paint()
          ..color = accent.withValues(alpha: 0.28 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = Phase0aPresentationTokens.vfxThinStrokeWidth,
      );
    }
  }

  void _paintCast(
    Canvas canvas,
    Offset center,
    double radius,
    double reveal,
    Paint ink,
    Paint wash,
  ) {
    switch (school) {
      case TechniqueSchool.gangMeng:
        final half = radius * (0.30 + 0.58 * reveal);
        final diamond = Path()
          ..moveTo(center.dx, center.dy - half)
          ..lineTo(center.dx + half, center.dy)
          ..lineTo(center.dx, center.dy + half)
          ..lineTo(center.dx - half, center.dy)
          ..close();
        canvas.drawPath(diamond, ink);
        canvas.drawLine(
          Offset(center.dx - half * 0.72, center.dy),
          Offset(center.dx + half * 0.72, center.dy),
          wash,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - half * 0.72),
          Offset(center.dx, center.dy + half * 0.72),
          wash,
        );
      case TechniqueSchool.lingQiao:
        final rect = Rect.fromCircle(center: center, radius: radius * 0.82);
        canvas.drawArc(
          rect,
          math.pi * 0.82,
          math.pi * 1.18 * reveal,
          false,
          ink,
        );
        canvas.drawArc(
          rect.deflate(radius * 0.18),
          -math.pi * 0.18,
          math.pi * 1.08 * reveal,
          false,
          wash,
        );
        final tip =
            center +
            Offset(
                  math.cos(math.pi * 0.82 + math.pi * 1.18 * reveal),
                  math.sin(math.pi * 0.82 + math.pi * 1.18 * reveal),
                ) *
                radius *
                0.82;
        canvas.drawLine(center, tip, wash);
      case TechniqueSchool.yinRou:
        final spiral = Path();
        const points = 28;
        for (var i = 0; i <= points; i++) {
          final t = i / points * reveal;
          final angle = math.pi * 4.2 * t;
          final distance = radius * (0.10 + 0.78 * t);
          final point =
              center + Offset(math.cos(angle), math.sin(angle)) * distance;
          if (i == 0) {
            spiral.moveTo(point.dx, point.dy);
          } else {
            spiral.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(spiral, ink);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius * 0.56),
          math.pi * 0.2,
          math.pi * 1.35 * reveal,
          false,
          wash,
        );
    }
  }

  void _paintImpact(
    Canvas canvas,
    Offset center,
    double radius,
    double reveal,
    Paint ink,
    Paint wash,
  ) {
    switch (school) {
      case TechniqueSchool.gangMeng:
        const rays = 8;
        for (var i = 0; i < rays; i++) {
          final angle = math.pi * 2 * i / rays;
          final inner =
              center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.14;
          final outer =
              center +
              Offset(math.cos(angle), math.sin(angle)) *
                  radius *
                  (i.isEven ? 0.96 : 0.72) *
                  reveal;
          canvas.drawLine(inner, outer, i.isEven ? ink : wash);
        }
        final strike = Path()
          ..moveTo(center.dx - radius * 0.34, center.dy - radius * 0.70)
          ..lineTo(center.dx + radius * 0.12, center.dy - radius * 0.08)
          ..lineTo(center.dx - radius * 0.02, center.dy + radius * 0.70);
        canvas.drawPath(strike, ink);
      case TechniqueSchool.lingQiao:
        for (var i = 0; i < 3; i++) {
          final inset = radius * (0.12 + i * 0.13);
          final rect = Rect.fromCircle(
            center: center + Offset((i - 1) * radius * 0.12, 0),
            radius: radius - inset,
          );
          canvas.drawArc(
            rect,
            -math.pi * (0.42 + i * 0.08),
            math.pi * (0.86 + i * 0.10) * reveal,
            false,
            i == 1 ? ink : wash,
          );
        }
        canvas.drawLine(
          center - Offset(radius * 0.86 * reveal, radius * 0.18),
          center + Offset(radius * 0.92 * reveal, radius * 0.10),
          ink,
        );
      case TechniqueSchool.yinRou:
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
            center,
            radius * (0.22 + i * 0.27) * reveal,
            i == 1 ? ink : wash,
          );
        }
        final wave = Path()
          ..moveTo(center.dx - radius * reveal, center.dy)
          ..cubicTo(
            center.dx - radius * 0.45,
            center.dy - radius * 0.42 * reveal,
            center.dx + radius * 0.30,
            center.dy + radius * 0.38 * reveal,
            center.dx + radius * reveal,
            center.dy,
          );
        canvas.drawPath(wave, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _SkillVfxPainter oldDelegate) =>
      oldDelegate.school != school ||
      oldDelegate.phase != phase ||
      oldDelegate.progress != progress ||
      oldDelegate.isUltimate != isUltimate ||
      oldDelegate.isAoe != isAoe;
}

enum _InkEffect { melee, palm, gather, clear, defeat }

class _InkEffectPainter extends CustomPainter {
  const _InkEffectPainter(
    this.effect, {
    this.defeatKind,
    this.progress = 1,
    this.isCritical = false,
    this.basicAttackSegmentId,
  });

  final _InkEffect effect;
  final Phase0aDefeatKind? defeatKind;
  final double progress;
  final bool isCritical;
  final String? basicAttackSegmentId;

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
    final reveal = Phase0aPresentationTokens.vfxReveal(progress);
    final fade = Phase0aPresentationTokens.vfxFade(progress);
    final strokeAlpha = Phase0aPresentationTokens.vfxStrokeAlpha(progress);
    ink.color = WuxiaUi.ink.withValues(alpha: 0.72 * strokeAlpha);
    wash.color = WuxiaUi.jiang.withValues(alpha: 0.30 * strokeAlpha);
    final washFill = Paint()
      ..color = WuxiaUi.qing.withValues(
        alpha: Phase0aPresentationTokens.vfxInkWashMaxOpacity * fade,
      );
    final splat = Paint()
      ..color = (isCritical ? WuxiaUi.gold : WuxiaUi.ink).withValues(
        alpha: 0.72 * fade,
      );
    if (_paintSwordSegment(
      canvas: canvas,
      size: size,
      center: center,
      reveal: reveal,
      ink: ink,
      wash: wash,
      washFill: washFill,
    )) {
      return;
    }
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
            ..color = WuxiaUi.qing.withValues(alpha: 0.90 * strokeAlpha)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = Phase0aPresentationTokens.vfxStrokeWidth * 1.35,
        );
        canvas.drawPath(falling, ink);
        for (
          var i = 0;
          i < Phase0aPresentationTokens.vfxResidualStrokeCount;
          i++
        ) {
          final offset = (i + 1) * size.width * 0.035 * (1 - reveal);
          canvas.save();
          canvas.translate(offset, -offset);
          canvas.drawPath(
            rising,
            Paint()
              ..color = WuxiaUi.ink.withValues(
                alpha:
                    Phase0aPresentationTokens.vfxResidualStrokeOpacity * fade,
              )
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = Phase0aPresentationTokens.vfxThinStrokeWidth,
          );
          canvas.restore();
        }
        canvas.drawCircle(center, size.width * 0.20, washFill);
        for (var i = 0; i < Phase0aPresentationTokens.vfxInkSplatCount; i++) {
          final angle =
              i * math.pi * 2 / Phase0aPresentationTokens.vfxInkSplatCount;
          final radius =
              size.width *
              (0.22 +
                  Phase0aPresentationTokens.vfxInkSplatTravelFraction * reveal);
          canvas.drawCircle(
            Offset(
              center.dx + math.cos(angle) * radius,
              center.dy + math.sin(angle) * radius,
            ),
            Phase0aPresentationTokens.vfxInkSplatRadius * (1 + (i % 2) * 0.35),
            splat,
          );
        }
        canvas.drawCircle(
          Offset(size.width * 0.72, size.height * 0.28),
          Phase0aPresentationTokens.gatherPullTargetDotRadius,
          Paint()..color = WuxiaUi.jiang.withValues(alpha: 0.58 * strokeAlpha),
        );
      case _InkEffect.palm:
        final reveal = Curves.easeOut.transform(
          Phase0aPresentationTokens.vfxReveal(progress),
        );
        final body = Path()
          ..moveTo(size.width * 0.07, size.height * 0.57)
          ..cubicTo(
            size.width * 0.33,
            size.height * 0.24,
            size.width * 0.68,
            size.height * 0.25,
            size.width * (0.20 + 0.73 * reveal),
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
            size.width * (0.22 + 0.64 * reveal),
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
            i * 0.8 + reveal * 0.7,
            4.7,
            false,
            i.isEven ? ink : wash,
          );
        }
        canvas.drawCircle(
          center,
          size.width * (0.12 + reveal * 0.08),
          washFill,
        );
      case _InkEffect.clear:
        final clearReveal = Curves.easeOut.transform(reveal);
        for (var i = 0; i < Phase0aPresentationTokens.vfxSpokeCount; i++) {
          final angle =
              i * math.pi * 2 / Phase0aPresentationTokens.vfxSpokeCount;
          final start = Offset(
            center.dx + math.cos(angle) * size.width * 0.10,
            center.dy + math.sin(angle) * size.height * 0.10,
          );
          final end = Offset(
            center.dx +
                math.cos(angle) * size.width * (0.12 + clearReveal * 0.34),
            center.dy +
                math.sin(angle) * size.height * (0.12 + clearReveal * 0.34),
          );
          canvas.drawLine(start, end, i.isEven ? ink : wash);
        }
        canvas.drawCircle(
          center,
          size.width * (0.12 + clearReveal * 0.24),
          washFill,
        );
        canvas.drawCircle(
          center,
          size.width * (0.08 + clearReveal * 0.16),
          Paint()..color = WuxiaUi.ink.withValues(alpha: 0.72 * strokeAlpha),
        );
        for (var i = 0; i < Phase0aPresentationTokens.vfxInkSplatCount; i++) {
          final angle =
              (i + 0.5) *
              math.pi *
              2 /
              Phase0aPresentationTokens.vfxInkSplatCount;
          final radius =
              size.width *
              (0.18 +
                  clearReveal *
                      Phase0aPresentationTokens.vfxInkSplatTravelFraction);
          canvas.drawCircle(
            Offset(
              center.dx + math.cos(angle) * radius,
              center.dy + math.sin(angle) * radius,
            ),
            Phase0aPresentationTokens.vfxInkSplatRadius,
            splat,
          );
        }
      case _InkEffect.defeat:
        final elite = defeatKind == Phase0aDefeatKind.elite;
        final count = elite
            ? Phase0aPresentationTokens.vfxEliteDefeatSplatCount
            : Phase0aPresentationTokens.vfxNormalDefeatSplatCount;
        if (elite) {
          canvas.drawCircle(
            center,
            size.width * (0.14 + reveal * 0.14),
            Paint()
              ..color = WuxiaUi.jiang.withValues(alpha: 0.42 * strokeAlpha)
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
          final travel = (0.22 + reveal * 0.22) * (elite ? 1.0 : 0.82);
          final point = Offset(
            center.dx + math.cos(angle) * size.width * travel,
            center.dy + math.sin(angle) * size.height * travel * 0.78,
          );
          canvas.drawCircle(
            point,
            Phase0aPresentationTokens.vfxInkSplatRadius *
                (i.isEven ? 1.4 : 0.8),
            splat,
          );
        }
        canvas.drawCircle(
          center,
          size.width * (0.16 + reveal * 0.16),
          washFill,
        );
    }
  }

  bool _paintSwordSegment({
    required Canvas canvas,
    required Size size,
    required Offset center,
    required double reveal,
    required Paint ink,
    required Paint wash,
    required Paint washFill,
  }) {
    switch (basicAttackSegmentId) {
      case 'sword_thrust' when effect == _InkEffect.palm:
        final start = Offset(size.width * 0.08, size.height * 0.58);
        final tip = Offset(
          size.width * (0.18 + 0.76 * reveal),
          size.height * 0.42,
        );
        canvas.drawLine(start, tip, ink);
        canvas.drawLine(
          start + Offset(0, size.height * 0.16),
          tip + Offset(-size.width * 0.08, size.height * 0.06),
          wash,
        );
        final point = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - size.height * 0.24, tip.dy - size.height * 0.13)
          ..lineTo(tip.dx - size.height * 0.18, tip.dy + size.height * 0.18)
          ..close();
        canvas.drawPath(point, Paint()..color = wash.color);
        return true;
      case 'sword_sweep' when effect == _InkEffect.melee:
        final outer = Rect.fromCircle(
          center: center,
          radius: size.shortestSide * 0.43,
        );
        canvas.drawArc(
          outer,
          math.pi * 0.78,
          math.pi * 1.34 * reveal,
          false,
          ink,
        );
        canvas.drawArc(
          outer.deflate(size.shortestSide * 0.10),
          math.pi * 0.88,
          math.pi * 1.18 * reveal,
          false,
          wash,
        );
        canvas.drawCircle(center, size.shortestSide * 0.14, washFill);
        return true;
      case 'sword_advancing_slash' when effect == _InkEffect.melee:
        final travel = size.shortestSide * (0.28 + 0.46 * reveal);
        final upper = Path()
          ..moveTo(center.dx - travel * 0.72, center.dy + travel * 0.52)
          ..lineTo(center.dx + travel, center.dy - travel * 0.58);
        final lower = Path()
          ..moveTo(center.dx - travel * 0.46, center.dy + travel * 0.80)
          ..lineTo(center.dx + travel * 0.78, center.dy - travel * 0.20);
        canvas.drawPath(upper, ink);
        canvas.drawPath(lower, wash);
        canvas.drawCircle(
          Offset(center.dx + travel * 0.72, center.dy - travel * 0.32),
          size.shortestSide * 0.10,
          washFill,
        );
        return true;
      default:
        return false;
    }
  }

  @override
  bool shouldRepaint(covariant _InkEffectPainter oldDelegate) =>
      oldDelegate.effect != effect ||
      oldDelegate.defeatKind != defeatKind ||
      oldDelegate.progress != progress ||
      oldDelegate.isCritical != isCritical ||
      oldDelegate.basicAttackSegmentId != basicAttackSegmentId;
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

class _GuardianMechanicPainter extends CustomPainter {
  const _GuardianMechanicPainter({
    required this.source,
    required this.target,
    required this.accent,
    required this.progress,
  });

  final Offset source;
  final Offset target;
  final Color accent;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.78 * (1 - progress * 0.35))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = Phase0aPresentationTokens.vfxThinStrokeWidth;
    final midpoint = Offset(
      (source.dx + target.dx) / 2,
      (source.dy + target.dy) / 2,
    );
    final path = Path()
      ..moveTo(source.dx, source.dy)
      ..quadraticBezierTo(midpoint.dx, midpoint.dy - 24, target.dx, target.dy);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      target,
      10 + 8 * (1 - progress),
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _GuardianMechanicPainter oldDelegate) =>
      oldDelegate.source != source ||
      oldDelegate.target != target ||
      oldDelegate.accent != accent ||
      oldDelegate.progress != progress;
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
