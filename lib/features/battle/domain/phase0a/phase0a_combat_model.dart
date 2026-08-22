import 'arena_vector.dart';
import '../../../../data/defs/boss_phase_def.dart';
import '../../../../data/defs/skill_def.dart';

const _initialBossPhaseIndex = 0;
const _noChargeTicks = 0;
const _noStaggerTicks = 0;

/// Phase 0A 竞技场阵营:单角色玩家对多敌。
enum Phase0aSide { player, enemy }

/// 普攻动作语义档(对齐反馈契约 move_kind,非数值)。
enum Phase0aMoveKind { light, heavy }

/// 被击败单位语义档(对齐反馈契约 defeat_kind)。
enum Phase0aDefeatKind { normal, elite }

/// 技能印可用态五态枚举(对齐反馈契约 availability)。
enum Phase0aSkillAvailability { ready, cooldown, qi, casting, down }

/// 技能逐目标结算状态(对齐反馈契约 outcomes.status_applied)。
enum Phase0aSkillStatus { none, pulled, staggered }

/// 招牌蓄力招的预解析施放参数(application 层注入,reducer 不回查仓库)。
///
/// 承载「倒计时完成后走既有 enemy skill 路径」所需的全部静态参数:
/// 伤害仍由 [SkillDef] 经唯一 DamageCalculator 结算,本对象不复制任何公式。
final class Phase0aChargeCast {
  Phase0aChargeCast({
    required this.skill,
    required this.chargeTicks,
    required this.attackRange,
    required this.halfArcRadians,
    required this.effectRadius,
    required this.cooldownSeconds,
    required this.actionCooldownSeconds,
  }) {
    if (skill.id.isEmpty) {
      throw ArgumentError.value(skill.id, 'skill.id', 'charge cast 需真实技能 id');
    }
    if (chargeTicks <= 0) {
      throw ArgumentError.value(chargeTicks, 'chargeTicks', 'must be positive');
    }
    for (final entry in {
      'attackRange': attackRange,
      'halfArcRadians': halfArcRadians,
      'effectRadius': effectRadius,
      'cooldownSeconds': cooldownSeconds,
      'actionCooldownSeconds': actionCooldownSeconds,
    }.entries) {
      final value = entry.value;
      if (!(value.isFinite && value >= 0)) {
        throw ArgumentError.value(
          value,
          entry.key,
          'must be finite and non-negative',
        );
      }
    }
  }

  /// 招牌技定义(伤害/真气/CD 字段沿用生产 SkillDef)。
  final SkillDef skill;

  /// 蓄力倒计时拍数(预解析自 numbers.combat.bossCharge.defaultChargeTicks)。
  final int chargeTicks;

  /// 释放时单体选目标参数(沿敌方技能绑定口径)。
  final double attackRange;
  final double halfArcRadians;
  final double effectRadius;

  /// 释放/被破招后写入 enemySkillCooldowns 的技能冷却(秒)。
  final double cooldownSeconds;

  /// 释放命中后的行动锁(秒,对齐敌方技能 intent 分支口径)。
  final double actionCooldownSeconds;

  @override
  bool operator ==(Object other) =>
      other is Phase0aChargeCast &&
      other.skill == skill &&
      other.chargeTicks == chargeTicks &&
      other.attackRange == attackRange &&
      other.halfArcRadians == halfArcRadians &&
      other.effectRadius == effectRadius &&
      other.cooldownSeconds == cooldownSeconds &&
      other.actionCooldownSeconds == actionCooldownSeconds;

  @override
  int get hashCode => Object.hash(
    skill,
    chargeTicks,
    attackRange,
    halfArcRadians,
    Object.hash(effectRadius, cooldownSeconds, actionCooldownSeconds),
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int _listHash<T>(List<T> list) => Object.hashAll(list);

/// 单个战斗单位(玩家或敌人)的不可变运行态。
///
/// 位置/朝向用脚底锚点语义坐标(y 轴向下为正,见 [ArenaVector]);
/// 生命、真气、移速、普攻冷却均为运行时快照,全部由构造方显式提供。
final class Phase0aActor {
  const Phase0aActor({
    required this.id,
    required this.side,
    required this.position,
    required this.facing,
    required this.maxHealth,
    required this.currentHealth,
    required this.moveSpeed,
    required this.qiCurrent,
    required this.qiMax,
    required this.attackCooldownRemaining,
    required this.defeatKind,
    this.autoUltimate = false,
    this.bossPhases,
    this.bossPhaseIndex = _initialBossPhaseIndex,
    this.unlockedEnemySkillIds = const [],
    this.enemySkillCooldowns = const {},
    this.chargeCast,
    this.phaseChargeCasts = const [],
    this.staggerTicksTotal = _noStaggerTicks,
    this.guardianDefIds = const [],
    this.guardianWardMult,
    this.guardInterceptsInterrupt = false,
    this.vulnerabilityMult,
    this.chargingCast,
    this.chargeTicksRemaining = _noChargeTicks,
    this.staggerTicksRemaining = _noStaggerTicks,
  });

  /// 语义 id,事件 actor/target 字段与稳定排序决胜键。
  final String id;
  final Phase0aSide side;
  final ArenaVector position;
  final ArenaVector facing;
  final int maxHealth;
  final int currentHealth;
  final double moveSpeed;
  final int qiCurrent;
  final int qiMax;

  /// 普攻剩余冷却(秒);>0 时普攻请求被拒绝。
  final double attackCooldownRemaining;

  /// 该单位被击败时的语义档(事件 payload)。
  final Phase0aDefeatKind defeatKind;

  /// Enemy-only pre-resolved Boss phase runtime. Player/non-phase actors keep
  /// the neutral defaults; the reducer never queries repositories.
  final bool autoUltimate;
  final List<BossPhaseDef>? bossPhases;
  final int bossPhaseIndex;
  final List<String> unlockedEnemySkillIds;
  final Map<String, double> enemySkillCooldowns;

  /// 顶层蓄力入口(EnemyDef.chargeSkillId 预解析):该敌人的招牌蓄力招施放
  /// 参数。null = 无顶层蓄力。AI 选中此招时 reducer 改为起手蓄力。
  final Phase0aChargeCast? chargeCast;

  /// 阶段蓄力入口(BossPhaseMechanic.chargeCounter 预解析):下标对齐
  /// [bossPhases],第 i 项非 null = 进入第 i 阶段即推入该招牌技蓄力。
  /// 无阶段 = 空表。
  final List<Phase0aChargeCast?> phaseChargeCasts;

  /// 被破招后踉跄窗口拍数(预解析自 numbers.combat.bossCharge)。
  final int staggerTicksTotal;

  /// Boss guardian ids whose alive state dynamically protects this actor.
  final List<String> guardianDefIds;

  /// Damage taken multiplier while any configured guardian remains alive.
  final double? guardianWardMult;

  /// Typed opt-in: a break action hitting a guarded charging boss is eaten by
  /// the lowest-health live guardian instead of interrupting the boss.
  final bool guardInterceptsInterrupt;

  /// 脆弱窗口外承伤乘子:**内容预解析/可观测事实**(源 `EnemyDef.vulnerability`,
  /// 恒 cycle-1 基础值;null = 无机制),与 [chargeCast]/[staggerTicksTotal]
  /// 同为装配期内容事实,供内容保真断言与观测。
  ///
  /// **权威结算乘子在伤害快照** `Phase0aDamageSnapshot.vulnerabilityOutMult`
  /// (快照工厂自同一 `CombatantSnapshot` 源透传);**reducer 从不读取本字段
  /// 数值**,只向 resolver 传蓄招/踉跄运行态事实——结算数值单源快照,
  /// 防 actor/快照双源漂移。窗口开合语义 = [chargingCast] != null(蓄招中)
  /// 或 [staggerTicksRemaining] > 0(破招踉跄),与旧引擎
  /// `DefaultGroundStrategy.vulnerabilityMultOf` 同语义。
  final double? vulnerabilityMult;

  /// 运行态:正在蓄力的施放(null = 未蓄力)。不可变可回放。
  final Phase0aChargeCast? chargingCast;

  /// 运行态:蓄力倒计时剩余拍数(>0 = 蓄力中,reducer 每拍递减,归零释放)。
  final int chargeTicksRemaining;

  /// 运行态:踉跄剩余拍数(>0 = 跳过行动且承伤减防,reducer 每拍递减)。
  final int staggerTicksRemaining;

  bool get isAlive => currentHealth > 0;

  Phase0aActor copyWith({
    ArenaVector? position,
    ArenaVector? facing,
    int? currentHealth,
    int? qiCurrent,
    double? attackCooldownRemaining,
    int? bossPhaseIndex,
    List<String>? unlockedEnemySkillIds,
    Map<String, double>? enemySkillCooldowns,
    Phase0aChargeCast? chargingCast,
    bool clearChargingCast = false,
    int? chargeTicksRemaining,
    int? staggerTicksRemaining,
  }) {
    return Phase0aActor(
      id: id,
      side: side,
      position: position ?? this.position,
      facing: facing ?? this.facing,
      maxHealth: maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      moveSpeed: moveSpeed,
      qiCurrent: qiCurrent ?? this.qiCurrent,
      qiMax: qiMax,
      attackCooldownRemaining:
          attackCooldownRemaining ?? this.attackCooldownRemaining,
      defeatKind: defeatKind,
      autoUltimate: autoUltimate,
      bossPhases: bossPhases,
      bossPhaseIndex: bossPhaseIndex ?? this.bossPhaseIndex,
      unlockedEnemySkillIds:
          unlockedEnemySkillIds ?? this.unlockedEnemySkillIds,
      enemySkillCooldowns: enemySkillCooldowns ?? this.enemySkillCooldowns,
      chargeCast: chargeCast,
      phaseChargeCasts: phaseChargeCasts,
      staggerTicksTotal: staggerTicksTotal,
      guardianDefIds: guardianDefIds,
      guardianWardMult: guardianWardMult,
      guardInterceptsInterrupt: guardInterceptsInterrupt,
      vulnerabilityMult: vulnerabilityMult,
      chargingCast: clearChargingCast
          ? null
          : (chargingCast ?? this.chargingCast),
      chargeTicksRemaining: chargeTicksRemaining ?? this.chargeTicksRemaining,
      staggerTicksRemaining:
          staggerTicksRemaining ?? this.staggerTicksRemaining,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Phase0aActor &&
      other.id == id &&
      other.side == side &&
      other.position == position &&
      other.facing == facing &&
      other.maxHealth == maxHealth &&
      other.currentHealth == currentHealth &&
      other.moveSpeed == moveSpeed &&
      other.qiCurrent == qiCurrent &&
      other.qiMax == qiMax &&
      other.attackCooldownRemaining == attackCooldownRemaining &&
      other.defeatKind == defeatKind &&
      other.autoUltimate == autoUltimate &&
      _bossPhasesEqual(other.bossPhases, bossPhases) &&
      other.bossPhaseIndex == bossPhaseIndex &&
      _listEquals(other.unlockedEnemySkillIds, unlockedEnemySkillIds) &&
      _mapEquals(other.enemySkillCooldowns, enemySkillCooldowns) &&
      other.chargeCast == chargeCast &&
      _listEquals(other.phaseChargeCasts, phaseChargeCasts) &&
      other.staggerTicksTotal == staggerTicksTotal &&
      _listEquals(other.guardianDefIds, guardianDefIds) &&
      other.guardianWardMult == guardianWardMult &&
      other.guardInterceptsInterrupt == guardInterceptsInterrupt &&
      other.vulnerabilityMult == vulnerabilityMult &&
      other.chargingCast == chargingCast &&
      other.chargeTicksRemaining == chargeTicksRemaining &&
      other.staggerTicksRemaining == staggerTicksRemaining;

  @override
  int get hashCode => Object.hash(
    id,
    side,
    position,
    facing,
    maxHealth,
    currentHealth,
    moveSpeed,
    qiCurrent,
    qiMax,
    attackCooldownRemaining,
    defeatKind,
    autoUltimate,
    _bossPhasesHash(bossPhases),
    bossPhaseIndex,
    _listHash(unlockedEnemySkillIds),
    _mapHash(enemySkillCooldowns),
    Object.hash(
      chargeCast,
      _listHash(phaseChargeCasts),
      staggerTicksTotal,
      _listHash(guardianDefIds),
      guardianWardMult,
      guardInterceptsInterrupt,
      vulnerabilityMult,
      chargingCast,
      chargeTicksRemaining,
      staggerTicksRemaining,
    ),
  );
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}

int _mapHash<K, V>(Map<K, V> map) => Object.hashAll(
  (map.entries.toList()..sort((a, b) => '${a.key}'.compareTo('${b.key}'))).map(
    (entry) => Object.hash(entry.key, entry.value),
  ),
);

bool _bossPhasesEqual(List<BossPhaseDef>? a, List<BossPhaseDef>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final left = a[i];
    final right = b[i];
    if (left.hpThresholdPct != right.hpThresholdPct ||
        !_listEquals(left.unlockSkillIds, right.unlockSkillIds) ||
        left.aiMode != right.aiMode ||
        left.onEnterMechanic != right.onEnterMechanic ||
        left.titleKey != right.titleKey) {
      return false;
    }
  }
  return true;
}

int _bossPhasesHash(List<BossPhaseDef>? phases) => phases == null
    ? 0
    : Object.hashAll(
        phases.map(
          (phase) => Object.hash(
            phase.hpThresholdPct,
            Object.hashAll(phase.unlockSkillIds),
            phase.aiMode,
            phase.onEnterMechanic,
            phase.titleKey,
          ),
        ),
      );

/// 玩家技能印运行态快照(slot 语义位 + 冷却剩余 + 真气门槛 + 可用态)。
final class Phase0aSkillSlot {
  const Phase0aSkillSlot({
    required this.slot,
    required this.cooldownRemaining,
    required this.qiCost,
    required this.availability,
  });

  /// 技能印语义位(如 gather / clear),事件 slot 字段。
  final String slot;

  /// 剩余冷却(秒),reducer 每拍扣减并 clamp 到零。
  final double cooldownRemaining;

  /// 最近一次结算使用的真气消耗快照(供冷却转好时判定 qi 态)。
  final int qiCost;

  final Phase0aSkillAvailability availability;

  Phase0aSkillSlot copyWith({
    double? cooldownRemaining,
    int? qiCost,
    Phase0aSkillAvailability? availability,
  }) {
    return Phase0aSkillSlot(
      slot: slot,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      qiCost: qiCost ?? this.qiCost,
      availability: availability ?? this.availability,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Phase0aSkillSlot &&
      other.slot == slot &&
      other.cooldownRemaining == cooldownRemaining &&
      other.qiCost == qiCost &&
      other.availability == availability;

  @override
  int get hashCode =>
      Object.hash(slot, cooldownRemaining, qiCost, availability);
}

/// 一拍竞技场全量状态(不可变):玩家 + 存活敌人 + 技能印 + 拍号/事件序号。
///
/// [enemies] 只保存存活单位;被击败者移除,保证其后不再出现
/// 以其为 actor/target 的事件。
final class Phase0aArenaState {
  const Phase0aArenaState({
    required this.tick,
    required this.nextSeq,
    required this.player,
    required this.enemies,
    required this.skillSlots,
  });

  /// 模拟核逻辑拍,reducer 每次结算 +1。
  final int tick;

  /// 下一个待分配的事件 seq(单调递增,发射方 = reducer)。
  final int nextSeq;

  final Phase0aActor player;
  final List<Phase0aActor> enemies;
  final List<Phase0aSkillSlot> skillSlots;

  @override
  bool operator ==(Object other) =>
      other is Phase0aArenaState &&
      other.tick == tick &&
      other.nextSeq == nextSeq &&
      other.player == player &&
      _listEquals(other.enemies, enemies) &&
      _listEquals(other.skillSlots, skillSlots);

  @override
  int get hashCode => Object.hash(
    tick,
    nextSeq,
    player,
    _listHash(enemies),
    _listHash(skillSlots),
  );
}
