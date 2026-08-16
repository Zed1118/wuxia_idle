import 'phase0a_combat_model.dart';

/// Phase 0A 语义事件基类(对齐冻结反馈契约公共 payload)。
///
/// [seq] 由 reducer 单调递增分配,表现层按 seq 排序消费、重复即丢弃;
/// [tick] 为模拟核逻辑拍。事件携带运行时结算数值,表现层禁止重算。
sealed class Phase0aEvent {
  const Phase0aEvent({required this.seq, required this.tick});

  final int seq;
  final int tick;
}

/// 普攻出手(对齐契约 attack_started)。
final class Phase0aAttackStarted extends Phase0aEvent {
  const Phase0aAttackStarted({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.moveKind,
  });

  final String actor;
  final Phase0aMoveKind moveKind;

  @override
  bool operator ==(Object other) =>
      other is Phase0aAttackStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.moveKind == moveKind;

  @override
  int get hashCode => Object.hash(seq, tick, actor, moveKind);
}

/// 普攻命中且结算完成(对齐契约 hit_landed)。
///
/// 合法未命中不发射本事件;[resolvedDamage] 与飘字一一对应,
/// [remainingHealth] 为目标结算后剩余生命。
final class Phase0aHitLanded extends Phase0aEvent {
  const Phase0aHitLanded({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.target,
    required this.moveKind,
    required this.isCritical,
    required this.isUltimate,
    required this.resolvedDamage,
    required this.remainingHealth,
  });

  final String actor;
  final String target;
  final Phase0aMoveKind moveKind;
  final bool isCritical;
  final bool isUltimate;
  final int resolvedDamage;
  final int remainingHealth;

  @override
  bool operator ==(Object other) =>
      other is Phase0aHitLanded &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.target == target &&
      other.moveKind == moveKind &&
      other.isCritical == isCritical &&
      other.isUltimate == isUltimate &&
      other.resolvedDamage == resolvedDamage &&
      other.remainingHealth == remainingHealth;

  @override
  int get hashCode => Object.hash(
    seq,
    tick,
    actor,
    target,
    moveKind,
    isCritical,
    isUltimate,
    resolvedDamage,
    remainingHealth,
  );
}

/// 敌方单位生命归零进入移除(对齐契约 enemy_defeated,全场至多一条)。
final class Phase0aEnemyDefeated extends Phase0aEvent {
  const Phase0aEnemyDefeated({
    required super.seq,
    required super.tick,
    required this.target,
    required this.defeatKind,
  });

  final String target;
  final Phase0aDefeatKind defeatKind;

  @override
  bool operator ==(Object other) =>
      other is Phase0aEnemyDefeated &&
      other.seq == seq &&
      other.tick == tick &&
      other.target == target &&
      other.defeatKind == defeatKind;

  @override
  int get hashCode => Object.hash(seq, tick, target, defeatKind);
}

/// 技能逐目标结算结果(对齐契约 outcomes 项)。
final class Phase0aSkillOutcome {
  const Phase0aSkillOutcome({
    required this.target,
    required this.resolvedDamage,
    required this.defeated,
    required this.statusApplied,
  });

  final String target;

  /// 模拟核结算伤害;无伤害结算时为 0。
  final int resolvedDamage;

  final bool defeated;
  final Phase0aSkillStatus statusApplied;

  @override
  bool operator ==(Object other) =>
      other is Phase0aSkillOutcome &&
      other.target == target &&
      other.resolvedDamage == resolvedDamage &&
      other.defeated == defeated &&
      other.statusApplied == statusApplied;

  @override
  int get hashCode =>
      Object.hash(target, resolvedDamage, defeated, statusApplied);
}

bool _outcomesEqual(List<Phase0aSkillOutcome> a, List<Phase0aSkillOutcome> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Q 聚怪力场出现(对齐契约 gather_started)。
final class Phase0aGatherStarted extends Phase0aEvent {
  const Phase0aGatherStarted({
    required super.seq,
    required super.tick,
    required this.actor,
  });

  final String actor;

  @override
  bool operator ==(Object other) =>
      other is Phase0aGatherStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor;

  @override
  int get hashCode => Object.hash(seq, tick, actor);
}

/// Q 聚怪结算生效,携带逐目标有序 outcomes(对齐契约 gather_applied)。
final class Phase0aGatherApplied extends Phase0aEvent {
  const Phase0aGatherApplied({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.outcomes,
  });

  final String actor;
  final List<Phase0aSkillOutcome> outcomes;

  @override
  bool operator ==(Object other) =>
      other is Phase0aGatherApplied &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      _outcomesEqual(other.outcomes, outcomes);

  @override
  int get hashCode => Object.hash(seq, tick, actor, Object.hashAll(outcomes));
}

/// R 清场释放(对齐契约 clear_started)。
final class Phase0aClearStarted extends Phase0aEvent {
  const Phase0aClearStarted({
    required super.seq,
    required super.tick,
    required this.actor,
  });

  final String actor;

  @override
  bool operator ==(Object other) =>
      other is Phase0aClearStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor;

  @override
  int get hashCode => Object.hash(seq, tick, actor);
}

/// R 清场群体结算生效,携带逐目标有序 outcomes(对齐契约 clear_applied)。
final class Phase0aClearApplied extends Phase0aEvent {
  const Phase0aClearApplied({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.outcomes,
  });

  final String actor;
  final List<Phase0aSkillOutcome> outcomes;

  @override
  bool operator ==(Object other) =>
      other is Phase0aClearApplied &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      _outcomesEqual(other.outcomes, outcomes);

  @override
  int get hashCode => Object.hash(seq, tick, actor, Object.hashAll(outcomes));
}

/// 技能印可用态迁移(对齐契约 skill_availability_changed)。
///
/// cooldown 态必带 [cooldownRemaining];ready / qi 态携带
/// [qiCurrent] / [qiRequired] 运行态快照。同一 slot 状态未变不重发。
final class Phase0aSkillAvailabilityChanged extends Phase0aEvent {
  const Phase0aSkillAvailabilityChanged({
    required super.seq,
    required super.tick,
    required this.slot,
    required this.availability,
    this.cooldownRemaining,
    this.qiCurrent,
    this.qiRequired,
  });

  final String slot;
  final Phase0aSkillAvailability availability;
  final double? cooldownRemaining;
  final int? qiCurrent;
  final int? qiRequired;

  @override
  bool operator ==(Object other) =>
      other is Phase0aSkillAvailabilityChanged &&
      other.seq == seq &&
      other.tick == tick &&
      other.slot == slot &&
      other.availability == availability &&
      other.cooldownRemaining == cooldownRemaining &&
      other.qiCurrent == qiCurrent &&
      other.qiRequired == qiRequired;

  @override
  int get hashCode => Object.hash(
    seq,
    tick,
    slot,
    availability,
    cooldownRemaining,
    qiCurrent,
    qiRequired,
  );
}
