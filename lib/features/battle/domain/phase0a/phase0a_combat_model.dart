import 'arena_vector.dart';

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

  bool get isAlive => currentHealth > 0;

  Phase0aActor copyWith({
    ArenaVector? position,
    ArenaVector? facing,
    int? currentHealth,
    int? qiCurrent,
    double? attackCooldownRemaining,
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
      other.defeatKind == defeatKind;

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
      );
}

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
  int get hashCode => Object.hash(slot, cooldownRemaining, qiCost, availability);
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
  int get hashCode =>
      Object.hash(tick, nextSeq, player, _listHash(enemies), _listHash(skillSlots));
}
