import 'arena_vector.dart';
import 'basic_attack_chain.dart';
import 'defense_resolution.dart';
import 'phase0a_combat_intent.dart';
import 'phase0a_combat_model.dart';
import 'posture.dart';
import 'status_effects.dart';

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
    this.basicAttackSegment,
  });

  final String actor;
  final Phase0aMoveKind moveKind;
  final BasicAttackSegment? basicAttackSegment;

  @override
  bool operator ==(Object other) =>
      other is Phase0aAttackStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.moveKind == moveKind &&
      other.basicAttackSegment == basicAttackSegment;

  @override
  int get hashCode =>
      Object.hash(seq, tick, actor, moveKind, basicAttackSegment);
}

/// 普攻命中且结算完成(对齐契约 hit_landed)。
///
/// 合法未命中不发射本事件;[resolvedDamage] 与飘字一一对应,
/// [remainingHealth] 为目标结算后剩余生命。
///
/// [actorPosition]/[targetPosition] 为动作结算时(本拍移动后)的出手点/
/// 命中点世界坐标快照。生产 reducer 必填;手工构造缺省为 null 时,
/// 表现层回退自身同步的竞技场状态(兼容旧构造)。
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
    this.actorPosition,
    this.targetPosition,
    this.basicAttackSegment,
  });

  final String actor;
  final String target;
  final Phase0aMoveKind moveKind;
  final bool isCritical;
  final bool isUltimate;
  final int resolvedDamage;
  final int remainingHealth;

  /// 出手者结算时世界坐标(本拍移动后)。
  final ArenaVector? actorPosition;

  /// 被命中目标结算时世界坐标。
  final ArenaVector? targetPosition;
  final BasicAttackSegment? basicAttackSegment;

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
      other.remainingHealth == remainingHealth &&
      other.actorPosition == actorPosition &&
      other.targetPosition == targetPosition &&
      other.basicAttackSegment == basicAttackSegment;

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
    actorPosition,
    targetPosition,
    basicAttackSegment,
  );
}

/// A designated enemy basic attack has damaged the runtime-only defended
/// entity. Durability damage is authored by the encounter contract and is not
/// recalculated by presentation or persistence consumers.
final class Phase0aDefendedEntityHit extends Phase0aEvent {
  const Phase0aDefendedEntityHit({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.target,
    required this.resolvedDamage,
    required this.remainingDurability,
    required this.actorPosition,
    required this.targetPosition,
  });

  final String actor;
  final String target;
  final int resolvedDamage;
  final int remainingDurability;
  final ArenaVector actorPosition;
  final ArenaVector targetPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aDefendedEntityHit &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.target == target &&
      other.resolvedDamage == resolvedDamage &&
      other.remainingDurability == remainingDurability &&
      other.actorPosition == actorPosition &&
      other.targetPosition == targetPosition;

  @override
  int get hashCode => Object.hash(
    seq,
    tick,
    actor,
    target,
    resolvedDamage,
    remainingDurability,
    actorPosition,
    targetPosition,
  );
}

/// Emitted exactly once when a defended entity reaches zero durability.
final class Phase0aDefendedEntityDestroyed extends Phase0aEvent {
  const Phase0aDefendedEntityDestroyed({
    required super.seq,
    required super.tick,
    required this.target,
    required this.targetPosition,
  });

  final String target;
  final ArenaVector targetPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aDefendedEntityDestroyed &&
      other.seq == seq &&
      other.tick == tick &&
      other.target == target &&
      other.targetPosition == targetPosition;

  @override
  int get hashCode => Object.hash(seq, tick, target, targetPosition);
}

/// Fixed-tick poison/internal-injury damage already settled by the reducer.
///
/// Damage pierces defense because it is emitted after direct HP settlement;
/// presentation and settlement consumers use this payload without recomputing.
final class Phase0aStatusDamageApplied extends Phase0aEvent {
  const Phase0aStatusDamageApplied({
    required super.seq,
    required super.tick,
    required this.source,
    required this.target,
    required this.statusType,
    required this.resolvedDamage,
    required this.remainingHealth,
    required this.targetPosition,
  });

  final String source;
  final String target;
  final TimedStatusType statusType;
  final int resolvedDamage;
  final int remainingHealth;
  final ArenaVector targetPosition;

  /// Stable exact key for short-window presentation aggregation.
  String get aggregationKey => '${statusType.name}|$source|$target';

  @override
  bool operator ==(Object other) =>
      other is Phase0aStatusDamageApplied &&
      other.seq == seq &&
      other.tick == tick &&
      other.source == source &&
      other.target == target &&
      other.statusType == statusType &&
      other.resolvedDamage == resolvedDamage &&
      other.remainingHealth == remainingHealth &&
      other.targetPosition == targetPosition;

  @override
  int get hashCode => Object.hash(
    seq,
    tick,
    source,
    target,
    statusType,
    resolvedDamage,
    remainingHealth,
    targetPosition,
  );
}

/// 敌方单位生命归零进入移除(对齐契约 enemy_defeated,全场至多一条)。
///
/// [targetPosition] 为死亡移除前的最终世界坐标快照(含本拍被位移的
/// 落点)。生产 reducer 必填;手工构造缺省为 null 时,表现层回退自身
/// 同步的竞技场状态(兼容旧构造)。
final class Phase0aEnemyDefeated extends Phase0aEvent {
  const Phase0aEnemyDefeated({
    required super.seq,
    required super.tick,
    required this.target,
    required this.defeatKind,
    this.targetPosition,
  });

  final String target;
  final Phase0aDefeatKind defeatKind;

  /// 被击败单位移除前的最终世界坐标。
  final ArenaVector? targetPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aEnemyDefeated &&
      other.seq == seq &&
      other.tick == tick &&
      other.target == target &&
      other.defeatKind == defeatKind &&
      other.targetPosition == targetPosition;

  @override
  int get hashCode =>
      Object.hash(seq, tick, target, defeatKind, targetPosition);
}

/// Boss crossed one HP threshold. [phaseIndex] is zero-based and
/// [unlockedSkillIds] contains only skills introduced by the entered phase.
final class Phase0aBossPhaseChanged extends Phase0aEvent {
  const Phase0aBossPhaseChanged({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.phaseIndex,
    required this.unlockedSkillIds,
  });

  final String actor;
  final int phaseIndex;
  final List<String> unlockedSkillIds;

  @override
  bool operator ==(Object other) =>
      other is Phase0aBossPhaseChanged &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.phaseIndex == phaseIndex &&
      _stringListsEqual(other.unlockedSkillIds, unlockedSkillIds);

  @override
  int get hashCode => Object.hash(
    seq,
    tick,
    actor,
    phaseIndex,
    Object.hashAll(unlockedSkillIds),
  );
}

/// Boss 起手蓄力(顶层 chargeSkillId 或阶段 chargeCounter 入口)。
///
/// [chargeTicks] 为本次蓄力倒计时总拍数(payload 直驱表现层读条);
/// 倒计时归零后招牌技经既有 enemy skill 路径结算并发
/// [Phase0aEnemySkillStarted],蓄力本身不产生独立伤害事件。
final class Phase0aBossChargeStarted extends Phase0aEvent {
  const Phase0aBossChargeStarted({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.skillId,
    required this.chargeTicks,
  });

  final String actor;
  final String skillId;
  final int chargeTicks;

  @override
  bool operator ==(Object other) =>
      other is Phase0aBossChargeStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.skillId == skillId &&
      other.chargeTicks == chargeTicks;

  @override
  int get hashCode => Object.hash(seq, tick, actor, skillId, chargeTicks);
}

/// 两名护法在 Boss 蓄力掩护相位内完成的一次合击。
///
/// 两次普攻 resolver 已按主护法、partner 顺序消费；[totalDamage] 是对
/// 玩家一次扣血后的总量，表现层不得按两条普通命中再次结算。
final class Phase0aGuardianCoopStrike extends Phase0aEvent {
  const Phase0aGuardianCoopStrike({
    required super.seq,
    required super.tick,
    required this.mainGuardian,
    required this.partner,
    required this.boss,
    required this.target,
    required this.mainGuardianDamage,
    required this.mainGuardianCritical,
    required this.totalDamage,
    required this.mainGuardianPosition,
    required this.partnerPosition,
    required this.bossPosition,
    required this.targetPosition,
  });

  final String mainGuardian;
  final String partner;
  final String boss;
  final String target;

  /// 旧 runner 的战后统计只消费主发起护法的 attackResult；保留该兼容事实。
  final int mainGuardianDamage;
  final bool mainGuardianCritical;

  /// 双护法对玩家的实际合计扣血，供战斗表现展示，不替代兼容统计字段。
  final int totalDamage;
  final ArenaVector mainGuardianPosition;
  final ArenaVector partnerPosition;
  final ArenaVector bossPosition;
  final ArenaVector targetPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aGuardianCoopStrike &&
      other.seq == seq &&
      other.tick == tick &&
      other.mainGuardian == mainGuardian &&
      other.partner == partner &&
      other.boss == boss &&
      other.target == target &&
      other.mainGuardianDamage == mainGuardianDamage &&
      other.mainGuardianCritical == mainGuardianCritical &&
      other.totalDamage == totalDamage &&
      other.mainGuardianPosition == mainGuardianPosition &&
      other.partnerPosition == partnerPosition &&
      other.bossPosition == bossPosition &&
      other.targetPosition == targetPosition;

  @override
  int get hashCode => Object.hash(
    seq,
    tick,
    mainGuardian,
    partner,
    boss,
    target,
    mainGuardianDamage,
    mainGuardianCritical,
    totalDamage,
    mainGuardianPosition,
    partnerPosition,
    bossPosition,
    targetPosition,
  );
}

/// 玩家破招被护法截走：Boss 仍保持蓄力，伤害与踉跄落在护法身上。
///
/// 该事件只表达一次重定向事实；结算伤害仍由同拍的既有命中/技能结果
/// 携带，表现层不得据此再次扣血或生成第二个伤害飘字。
final class Phase0aGuardIntercepted extends Phase0aEvent {
  const Phase0aGuardIntercepted({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.boss,
    required this.guardian,
    required this.skillId,
    required this.resolvedDamage,
    required this.bossPosition,
    required this.guardianPosition,
  });

  final String actor;
  final String boss;
  final String guardian;
  final String skillId;
  final int resolvedDamage;
  final ArenaVector bossPosition;
  final ArenaVector guardianPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aGuardIntercepted &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.boss == boss &&
      other.guardian == guardian &&
      other.skillId == skillId &&
      other.resolvedDamage == resolvedDamage &&
      other.bossPosition == bossPosition &&
      other.guardianPosition == guardianPosition;

  @override
  int get hashCode => Object.hash(
    seq,
    tick,
    actor,
    boss,
    guardian,
    skillId,
    resolvedDamage,
    bossPosition,
    guardianPosition,
  );
}

/// Projection of a transition from the single authoritative posture state.
/// UI and VFX consume this payload but never maintain a second posture value.
final class Phase0aPostureChanged extends Phase0aEvent {
  const Phase0aPostureChanged({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.target,
    required this.eventType,
    required this.amount,
    required this.accumulated,
    required this.capacity,
    required this.vulnerabilityTicksRemaining,
    this.hitKind,
    this.targetPosition,
  });

  final String actor;
  final String target;
  final PostureEventType eventType;
  final double amount;
  final double accumulated;
  final double capacity;
  final int vulnerabilityTicksRemaining;
  final PostureHitKind? hitKind;
  final ArenaVector? targetPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aPostureChanged &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.target == target &&
      other.eventType == eventType &&
      other.amount == amount &&
      other.accumulated == accumulated &&
      other.capacity == capacity &&
      other.vulnerabilityTicksRemaining == vulnerabilityTicksRemaining &&
      other.hitKind == hitKind &&
      other.targetPosition == targetPosition;

  @override
  int get hashCode => Object.hash(
    seq,
    tick,
    actor,
    target,
    eventType,
    amount,
    accumulated,
    capacity,
    vulnerabilityTicksRemaining,
    hitKind,
    targetPosition,
  );
}

/// Enemy successfully started a phase-unlocked skill. Damage continues through
/// [Phase0aHitLanded], so existing feedback and settlement consume the resolved
/// hit without a parallel damage event contract.
final class Phase0aEnemySkillStarted extends Phase0aEvent {
  const Phase0aEnemySkillStarted({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.skillId,
  });

  final String actor;
  final String skillId;

  @override
  bool operator ==(Object other) =>
      other is Phase0aEnemySkillStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.skillId == skillId;

  @override
  int get hashCode => Object.hash(seq, tick, actor, skillId);
}

/// 技能逐目标结算结果(对齐契约 outcomes 项)。
///
/// [sourcePosition]/[targetPosition] 为结算时世界坐标快照:
/// Q 聚怪 = 拉前位置 → 真实环点([gatherRingDestination] 落点,
/// 不是玩家中心);R/数字技能 = 施放点 → 目标结算时位置。
/// 生产 reducer 必填;手工构造缺省为 null 时,表现层回退自身同步的
/// 竞技场状态(兼容旧构造)。
final class Phase0aSkillOutcome {
  const Phase0aSkillOutcome({
    required this.target,
    required this.resolvedDamage,
    required this.isCritical,
    required this.defeated,
    required this.statusApplied,
    this.sourcePosition,
    this.targetPosition,
  });

  final String target;

  /// 模拟核结算伤害;无伤害结算时为 0。
  final int resolvedDamage;
  final bool isCritical;

  final bool defeated;
  final Phase0aSkillStatus statusApplied;

  /// Q = 目标被拉前位置;R/数字技能 = 施放者结算时位置。
  final ArenaVector? sourcePosition;

  /// Q = 真实环点落点;R/数字技能 = 目标结算时位置。
  final ArenaVector? targetPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aSkillOutcome &&
      other.target == target &&
      other.resolvedDamage == resolvedDamage &&
      other.isCritical == isCritical &&
      other.defeated == defeated &&
      other.statusApplied == statusApplied &&
      other.sourcePosition == sourcePosition &&
      other.targetPosition == targetPosition;

  @override
  int get hashCode => Object.hash(
    target,
    resolvedDamage,
    isCritical,
    defeated,
    statusApplied,
    sourcePosition,
    targetPosition,
  );
}

bool _outcomesEqual(List<Phase0aSkillOutcome> a, List<Phase0aSkillOutcome> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _stringListsEqual(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Q 聚怪力场出现(对齐契约 gather_started)。
///
/// [actorPosition] 为施放者坐标，[centerPosition] 为真实聚拢中心。
/// 生产 reducer 必填；旧手工构造缺省时表现层回退施放者坐标。
final class Phase0aGatherStarted extends Phase0aEvent {
  const Phase0aGatherStarted({
    required super.seq,
    required super.tick,
    required this.actor,
    this.skillId = '',
    this.actorPosition,
    this.centerPosition,
  });

  final String actor;
  final String skillId;

  /// 施放者施放时世界坐标。
  final ArenaVector? actorPosition;

  /// 聚拢力场的真实世界坐标中心。
  final ArenaVector? centerPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aGatherStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.skillId == skillId &&
      other.actorPosition == actorPosition &&
      other.centerPosition == centerPosition;

  @override
  int get hashCode =>
      Object.hash(seq, tick, actor, skillId, actorPosition, centerPosition);
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
///
/// [actorPosition] 为施放时世界坐标快照。生产 reducer 必填;
/// 手工构造缺省为 null 时,表现层回退自身同步的竞技场状态。
final class Phase0aClearStarted extends Phase0aEvent {
  const Phase0aClearStarted({
    required super.seq,
    required super.tick,
    required this.actor,
    this.skillId = '',
    this.actorPosition,
  });

  final String actor;
  final String skillId;

  /// 施放者施放时世界坐标。
  final ArenaVector? actorPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aClearStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.skillId == skillId &&
      other.actorPosition == actorPosition;

  @override
  int get hashCode => Object.hash(seq, tick, actor, skillId, actorPosition);
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

/// 数字 1–6 真实技能成功释放。skillId 来自装备槽，直接供结算/熟练度使用。
final class Phase0aSkillStarted extends Phase0aEvent {
  const Phase0aSkillStarted({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.hotkey,
    required this.skillId,
  });

  final String actor;
  final int hotkey;
  final String skillId;

  @override
  bool operator ==(Object other) =>
      other is Phase0aSkillStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.hotkey == hotkey &&
      other.skillId == skillId;

  @override
  int get hashCode => Object.hash(seq, tick, actor, hotkey, skillId);
}

/// 数字技能逐目标结算完成；单体技能 outcomes 至多一项，群体按 actor id 稳定序。
final class Phase0aSkillApplied extends Phase0aEvent {
  const Phase0aSkillApplied({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.hotkey,
    required this.skillId,
    required this.outcomes,
  });

  final String actor;
  final int hotkey;
  final String skillId;
  final List<Phase0aSkillOutcome> outcomes;

  @override
  bool operator ==(Object other) =>
      other is Phase0aSkillApplied &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.hotkey == hotkey &&
      other.skillId == skillId &&
      _outcomesEqual(other.outcomes, outcomes);

  @override
  int get hashCode =>
      Object.hash(seq, tick, actor, hotkey, skillId, Object.hashAll(outcomes));
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

/// 新一波敌人入场(对齐契约 wave_started,每场 wave_index 严格递增)。
///
/// [waveIndex] 对外 1-based(首波 = 1,直对「第 N 波」,2026-08-16 拍板);
/// [waveTotal] 为本场总波数。首波事件全场一次、排在首个战斗事件前。
final class Phase0aWaveStarted extends Phase0aEvent {
  const Phase0aWaveStarted({
    required super.seq,
    required super.tick,
    required this.waveIndex,
    required this.waveTotal,
  });

  final int waveIndex;
  final int waveTotal;

  @override
  bool operator ==(Object other) =>
      other is Phase0aWaveStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.waveIndex == waveIndex &&
      other.waveTotal == waveTotal;

  @override
  int get hashCode => Object.hash(seq, tick, waveIndex, waveTotal);
}

/// 一波全部敌方单位移除完成(对齐契约 wave_cleared,与 wave_started 一一对应)。
final class Phase0aWaveCleared extends Phase0aEvent {
  const Phase0aWaveCleared({
    required super.seq,
    required super.tick,
    required this.waveIndex,
  });

  /// 对外 1-based,与 [Phase0aWaveStarted.waveIndex] 同口径。
  final int waveIndex;

  @override
  bool operator ==(Object other) =>
      other is Phase0aWaveCleared &&
      other.seq == seq &&
      other.tick == tick &&
      other.waveIndex == waveIndex;

  @override
  int get hashCode => Object.hash(seq, tick, waveIndex);
}

/// 入口预警开始(SpawnDirector warningStarted 投影)。
///
/// [entryPosition] 为该 entry 绑定 actor 的显式入场点世界坐标快照
/// (来自冻结遭遇名单,不是运行时插值)。
final class Phase0aSpawnWarningStarted extends Phase0aEvent {
  const Phase0aSpawnWarningStarted({
    required super.seq,
    required super.tick,
    required this.entryId,
    required this.enemyId,
    required this.entryPosition,
  });

  final String entryId;
  final String enemyId;
  final ArenaVector entryPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aSpawnWarningStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.entryId == entryId &&
      other.enemyId == enemyId &&
      other.entryPosition == entryPosition;

  @override
  int get hashCode => Object.hash(seq, tick, entryId, enemyId, entryPosition);
}

/// 敌人入场完成,本拍可加入竞技场移动但受攻击宽限约束
/// (SpawnDirector entered 投影)。
final class Phase0aEnemyEntered extends Phase0aEvent {
  const Phase0aEnemyEntered({
    required super.seq,
    required super.tick,
    required this.entryId,
    required this.enemyId,
    required this.entryPosition,
  });

  final String entryId;
  final String enemyId;
  final ArenaVector entryPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aEnemyEntered &&
      other.seq == seq &&
      other.tick == tick &&
      other.entryId == entryId &&
      other.enemyId == enemyId &&
      other.entryPosition == entryPosition;

  @override
  int get hashCode => Object.hash(seq, tick, entryId, enemyId, entryPosition);
}

/// 入场敌人攻击宽限到期,恢复进攻资格
/// (SpawnDirector graceExpired 投影)。
final class Phase0aSpawnGraceExpired extends Phase0aEvent {
  const Phase0aSpawnGraceExpired({
    required super.seq,
    required super.tick,
    required this.entryId,
    required this.enemyId,
    required this.entryPosition,
  });

  final String entryId;
  final String enemyId;
  final ArenaVector entryPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aSpawnGraceExpired &&
      other.seq == seq &&
      other.tick == tick &&
      other.entryId == entryId &&
      other.enemyId == enemyId &&
      other.entryPosition == entryPosition;

  @override
  int get hashCode => Object.hash(seq, tick, entryId, enemyId, entryPosition);
}

/// 战斗胜利终局(对齐契约 battle_victory,全场至多一条;
/// 其后一切战斗事件被忽略)。
final class Phase0aBattleVictory extends Phase0aEvent {
  const Phase0aBattleVictory({required super.seq, required super.tick});

  @override
  bool operator ==(Object other) =>
      other is Phase0aBattleVictory && other.seq == seq && other.tick == tick;

  @override
  int get hashCode => Object.hash(seq, tick);
}

/// 战斗战败终局(对齐契约 battle_defeat,全场至多一条;
/// 玩家死亡优先,病态双方同时为空也按 defeat,禁止双终局)。
final class Phase0aBattleDefeat extends Phase0aEvent {
  const Phase0aBattleDefeat({required super.seq, required super.tick});

  @override
  bool operator ==(Object other) =>
      other is Phase0aBattleDefeat && other.seq == seq && other.tick == tick;

  @override
  int get hashCode => Object.hash(seq, tick);
}

/// 玩家主动防御状态进入运行态；方向和位移均来自领域 state transition。
final class Phase0aDefenseStarted extends Phase0aEvent {
  const Phase0aDefenseStarted({
    required super.seq,
    required super.tick,
    required this.actor,
    required this.action,
    required this.fromPosition,
    required this.toPosition,
    required this.windowTicks,
    required this.shieldAbsorption,
  });

  final String actor;
  final Phase0aDefenseAction action;
  final ArenaVector fromPosition;
  final ArenaVector toPosition;
  final int windowTicks;
  final double shieldAbsorption;

  @override
  bool operator ==(Object other) =>
      other is Phase0aDefenseStarted &&
      other.seq == seq &&
      other.tick == tick &&
      other.actor == actor &&
      other.action == action &&
      other.fromPosition == fromPosition &&
      other.toPosition == toPosition &&
      other.windowTicks == windowTicks &&
      other.shieldAbsorption == shieldAbsorption;

  @override
  int get hashCode => Object.hash(
    seq,
    tick,
    actor,
    action,
    fromPosition,
    toPosition,
    windowTicks,
    shieldAbsorption,
  );
}

/// 一次入站攻击的唯一防御结算结果。counterDamage 是标准化反击值，
/// nonRecursive 明示该反击不会再次进入 defense resolver。
final class Phase0aDefenseResolved extends Phase0aEvent {
  const Phase0aDefenseResolved({
    required super.seq,
    required super.tick,
    required this.attackId,
    required this.attacker,
    required this.target,
    required this.branch,
    required this.incomingDamage,
    required this.counterDamage,
    required this.shieldRemaining,
    required this.nonRecursive,
    required this.targetPosition,
  });

  final String attackId;
  final String attacker;
  final String target;
  final DefenseBranch branch;
  final int incomingDamage;
  final int counterDamage;
  final int shieldRemaining;
  final bool nonRecursive;
  final ArenaVector targetPosition;

  @override
  bool operator ==(Object other) =>
      other is Phase0aDefenseResolved &&
      other.seq == seq &&
      other.tick == tick &&
      other.attackId == attackId &&
      other.attacker == attacker &&
      other.target == target &&
      other.branch == branch &&
      other.incomingDamage == incomingDamage &&
      other.counterDamage == counterDamage &&
      other.shieldRemaining == shieldRemaining &&
      other.nonRecursive == nonRecursive &&
      other.targetPosition == targetPosition;

  @override
  int get hashCode => Object.hash(
    seq,
    tick,
    attackId,
    attacker,
    target,
    branch,
    incomingDamage,
    counterDamage,
    shieldRemaining,
    nonRecursive,
    targetPosition,
  );
}
