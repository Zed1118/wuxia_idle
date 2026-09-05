import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../application/phase0a/phase0a_battle_flow.dart';
import '../../application/phase0a/phase0a_checkpoint_objective_observation.dart';
import '../../application/phase0a/phase0a_defend_objective_observation.dart';
import '../../application/phase0a/phase0a_player_input_adapter.dart';
import '../../application/phase0a/phase0a_pursue_objective_observation.dart';
import '../../application/phase0a/phase0a_survive_objective_observation.dart';
import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/combat_event_order.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import 'phase0a_event_sequencer.dart';
import 'phase0a_vfx_controller.dart';
import 'phase0a_visual_roster.dart';

final class Phase0aSurviveObjectiveProgress {
  const Phase0aSurviveObjectiveProgress({
    required this.requiredTicks,
    required this.elapsedTicks,
  });

  final int requiredTicks;
  final int elapsedTicks;

  int get remainingTicks => requiredTicks - elapsedTicks;
  bool get completed => elapsedTicks >= requiredTicks;
}

final class Phase0aPursueObjectiveProgress {
  const Phase0aPursueObjectiveProgress({
    required this.targetId,
    required this.targetActorId,
    required this.distance,
    required this.completed,
  });

  final String targetId;
  final String targetActorId;
  final double? distance;
  final bool completed;

  int? get remainingDistance => distance?.ceil();
}

final class Phase0aDefendObjectiveProgress {
  const Phase0aDefendObjectiveProgress({
    required this.entityId,
    required this.position,
    required this.maxDurability,
    required this.currentDurability,
    required this.requiredTicks,
    required this.elapsedTicks,
    required this.completed,
  });

  final String entityId;
  final ArenaVector position;
  final int maxDurability;
  final int currentDurability;
  final int requiredTicks;
  final int elapsedTicks;
  final bool completed;

  int get remainingTicks =>
      (requiredTicks - elapsedTicks).clamp(0, requiredTicks);
  bool get destroyed => currentDurability <= 0;
}

final class Phase0aBattleController extends ChangeNotifier {
  Phase0aBattleController({
    required Phase0aBattleFlow flow,
    required this.roster,
    required this.fixedDeltaSeconds,
  }) : _flow = flow {
    if (!(fixedDeltaSeconds.isFinite && fixedDeltaSeconds > 0)) {
      throw ArgumentError.value(
        fixedDeltaSeconds,
        'fixedDeltaSeconds',
        'must be finite and positive',
      );
    }
    _vfx.syncActors(_flow.state);
  }

  /// 当前 flow。`restart` 换入新实例,故非 final。
  Phase0aBattleFlow _flow;
  final Phase0aVisualRoster roster;
  final double fixedDeltaSeconds;

  /// 排序器/VFX 均带跨拍内部状态(已接受 seq 集合 / 终局封签 `_sealed`),
  /// restart 必须一并重建,故非 final。
  Phase0aEventSequencer _sequencer = Phase0aEventSequencer();
  Phase0aVfxController _vfx = Phase0aVfxController();

  Phase0aPlayerCommand _pending = const Phase0aPlayerCommand();
  List<Phase0aEvent> _lastEvents = const <Phase0aEvent>[];
  final List<Phase0aEvent> _eventBuffer = <Phase0aEvent>[];
  late final List<Phase0aEvent> _events = UnmodifiableListView(_eventBuffer);
  List<Phase0aVfxEntry> _feedback = const <Phase0aVfxEntry>[];

  Phase0aArenaState get state => _flow.state;
  Phase0aBattleOutcome get outcome => _flow.outcome;
  List<Phase0aEvent> get lastEvents => _lastEvents;
  List<CombatEventRecord> get lastEventRecords => _flow.lastOrderedEventRecords;
  List<Phase0aEvent> get events => _events;
  List<Phase0aVfxEntry> get feedback => _feedback;

  Phase0aCheckpointObjectiveObservation? get checkpointObjectiveProgress {
    final flow = _flow;
    if (flow is! Phase0aCheckpointObjectiveObservationSource) return null;
    return (flow as Phase0aCheckpointObjectiveObservationSource)
        .checkpointObjectiveObservation;
  }

  Phase0aSurviveObjectiveProgress? get surviveObjectiveProgress {
    final flow = _flow;
    if (flow is! Phase0aSurviveObjectiveObservationSource) return null;
    final observation = (flow as Phase0aSurviveObjectiveObservationSource)
        .surviveObjectiveObservation;
    if (observation == null) return null;

    final tickMicroseconds =
        (fixedDeltaSeconds * Duration.microsecondsPerSecond).round();
    final requiredTicks =
        (observation.requiredDuration.inMicroseconds / tickMicroseconds).ceil();
    final elapsedTicks = (observation.elapsed.inMicroseconds / tickMicroseconds)
        .floor()
        .clamp(0, requiredTicks);
    return Phase0aSurviveObjectiveProgress(
      requiredTicks: requiredTicks,
      elapsedTicks: elapsedTicks,
    );
  }

  Phase0aDefendObjectiveProgress? get defendObjectiveProgress {
    final flow = _flow;
    if (flow is! Phase0aDefendObjectiveObservationSource) return null;
    final observation = (flow as Phase0aDefendObjectiveObservationSource)
        .defendObjectiveObservation;
    if (observation == null) return null;
    final tickMicroseconds =
        (fixedDeltaSeconds * Duration.microsecondsPerSecond).round();
    final requiredTicks =
        (observation.requiredDuration.inMicroseconds / tickMicroseconds).ceil();
    final elapsedTicks = (observation.elapsed.inMicroseconds / tickMicroseconds)
        .floor()
        .clamp(0, requiredTicks);
    return Phase0aDefendObjectiveProgress(
      entityId: observation.entityId,
      position: observation.position,
      maxDurability: observation.maxDurability,
      currentDurability: observation.currentDurability,
      requiredTicks: requiredTicks,
      elapsedTicks: elapsedTicks,
      completed: observation.completed,
    );
  }

  Phase0aPursueObjectiveProgress? get pursueObjectiveProgress {
    final flow = _flow;
    if (flow is! Phase0aPursueObjectiveObservationSource) return null;
    final observation = (flow as Phase0aPursueObjectiveObservationSource)
        .pursueObjectiveObservation;
    if (observation == null) return null;
    return Phase0aPursueObjectiveProgress(
      targetId: observation.targetId,
      targetActorId: observation.targetActorId,
      distance: observation.distance,
      completed: observation.completed,
    );
  }

  /// 终局重开(9B):换入调用方装配的全新 flow,重建排序器与 VFX 控制器,
  /// 清空 pending/事件/反馈缓存。只换实例,不触碰 domain 任何规则;
  /// 新 flow 的装配责任在调用方(debug 路由 = 重载 fixture 同 seed 新会话)。
  void restart(Phase0aBattleFlow newFlow) {
    _flow = newFlow;
    _sequencer = Phase0aEventSequencer();
    _vfx = Phase0aVfxController();
    _pending = const Phase0aPlayerCommand();
    _lastEvents = const <Phase0aEvent>[];
    _eventBuffer.clear();
    _feedback = const <Phase0aVfxEntry>[];
    _vfx.syncActors(_flow.state);
    notifyListeners();
  }

  void enqueue(Phase0aPlayerCommand command) {
    if (outcome != Phase0aBattleOutcome.ongoing) return;
    _pending = _merge(_pending, command);
  }

  List<Phase0aEvent> step([Phase0aPlayerCommand? command]) {
    if (outcome != Phase0aBattleOutcome.ongoing) {
      return const <Phase0aEvent>[];
    }
    if (command != null) enqueue(command);
    final snapshot = _pending;
    _pending = const Phase0aPlayerCommand();

    _vfx.syncActors(_flow.state);
    final emitted = _flow.advance(
      deltaSeconds: fixedDeltaSeconds,
      command: snapshot,
    );
    final accepted = _sequencer.ingest(emitted);
    _lastEvents = List.unmodifiable(accepted);
    _eventBuffer.addAll(accepted);
    _feedback = List.unmodifiable(_vfx.consume(accepted));
    notifyListeners();
    return _lastEvents;
  }

  static Phase0aPlayerCommand _merge(
    Phase0aPlayerCommand left,
    Phase0aPlayerCommand right,
  ) => Phase0aPlayerCommand(
    left: left.left || right.left,
    right: left.right || right.right,
    up: left.up || right.up,
    down: left.down || right.down,
    moveDirection: right.left || right.right || right.up || right.down
        ? null
        : right.moveDirection ?? left.moveDirection,
    attack: left.attack || right.attack,
    attackAimDirection: right.attack
        ? right.attackAimDirection
        : left.attackAimDirection,
    attackTargetId: right.attack ? right.attackTargetId : left.attackTargetId,
    skillHotkey: right.skillHotkey ?? left.skillHotkey,
    skillAimDirection: right.skillHotkey != null
        ? right.skillAimDirection
        : left.skillAimDirection,
    gather: left.gather || right.gather,
    gatherTargetPoint: right.gather
        ? right.gatherTargetPoint
        : left.gatherTargetPoint,
    clear: left.clear || right.clear,
    defenseAction: right.defenseAction ?? left.defenseAction,
    defenseDirection: right.defenseAction != null
        ? right.defenseDirection
        : left.defenseDirection,
  );
}
