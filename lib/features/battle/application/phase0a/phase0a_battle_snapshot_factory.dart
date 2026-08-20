import '../../../../data/defs/skill_def.dart';
import '../../../../data/numbers_config.dart';
import '../../../../shared/battle_shared/combatant_snapshot.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';
import '../../../cultivation/domain/skill_proficiency.dart';
import 'phase0a_damage_calculator_adapter.dart';

/// Phase 0A 快照工厂的不可变输入:显式 Phase0a actor id + 中立角色快照。
///
/// actorId 必须由调用方显式给出(与 arena actor id 一致),不得从旧
/// characterId 自行猜测字符串 id(第五批协调计划冻结边界)。
final class Phase0aCombatantInput {
  Phase0aCombatantInput({required this.actorId, required this.snapshot}) {
    if (actorId.isEmpty) {
      throw ArgumentError.value(actorId, 'actorId', 'Phase0a actor id 不得为空');
    }
  }

  /// 显式 Phase0a actor id(与 arena/reducer 侧 id 一致)。
  final String actorId;

  /// 引擎无关的开战前领域快照。
  final CombatantSnapshot snapshot;
}

/// 工厂输出 bundle:`Phase0aDamageCalculatorAdapter` 的显式入参载体。
///
/// 两个 map 均为防御性不可修改副本:外部构造后 mutation 不得污染 bundle,
/// 否则同 seed 回放会被静默污染(沿第三批快照拍板体例)。
final class Phase0aBattleSnapshotBundle {
  Phase0aBattleSnapshotBundle({
    required Map<String, Phase0aDamageSnapshot> combatants,
    required Map<Phase0aDamageKind, SkillDef?> moveBindings,
  }) : combatants = Map.unmodifiable(combatants),
       moveBindings = Map.unmodifiable(moveBindings);

  /// actorId → 伤害快照(供 adapter `combatants` 入参)。
  final Map<String, Phase0aDamageSnapshot> combatants;

  /// 招式绑定(value null = control-only),供 adapter `moveBindings` 入参。
  final Map<Phase0aDamageKind, SkillDef?> moveBindings;
}

/// Phase 0A 生产伤害快照工厂(第五批派单)。
///
/// 只做「`CombatantSnapshot` 稳定字段解析 + 既有 `SkillProficiency` 调用」,
/// 不复制伤害/熟练度公式,不创建第二套伤害计算器——消费方仍必须实例化
/// 既有 `Phase0aDamageCalculatorAdapter` 并传入本工厂产出的 bundle。
///
/// 字段口径与旧战斗内 adapter 的稳定路径逐项同值(永久内力、装备攻击、
/// 修炼层、流派、境界层阶、防御/闪避/暴击、攻击烘焙乘子、输出乘子、
/// 弱点/抗性表、破甲)。
///
/// 构造期 fail-fast(禁止把战中动态机制冻结成错误常量,留给后续
/// state-aware resolver 切片):
/// - 非零吸血(reducer 无回血输出,沿第三批口径提前到构造期);
/// - 护法结界配置(承伤随护法存活变化);
/// - 脆弱窗口配置(承伤随蓄力/踉跄变化);
/// - 活跃踉跄(减防 override 是战中运行时状态)。
final class Phase0aBattleSnapshotFactory {
  Phase0aBattleSnapshotFactory({required NumbersConfig numbers})
    : _numbers = numbers;

  final NumbersConfig _numbers;

  /// 把显式 actor id + [CombatantSnapshot] 集合映射为不可变 bundle。
  ///
  /// [moveBindings] 显式注入并做防御性副本;null 仍表示 control-only,
  /// 缺 kind 仍由既有 adapter fail-fast,本工厂不猜技能。
  Phase0aBattleSnapshotBundle create({
    required List<Phase0aCombatantInput> combatants,
    required Map<Phase0aDamageKind, SkillDef?> moveBindings,
  }) {
    if (combatants.isEmpty) {
      throw ArgumentError.value(combatants, 'combatants', '参战列表不得为空');
    }
    // 按显式 binding 收集非空技能(按 skill.id 去重;null = control-only 跳过)。
    final boundSkills = <String, SkillDef>{};
    moveBindings.forEach((kind, skill) {
      if (skill != null) boundSkills[skill.id] = skill;
    });

    final snapshots = <String, Phase0aDamageSnapshot>{};
    for (final combatant in combatants) {
      if (snapshots.containsKey(combatant.actorId)) {
        throw ArgumentError.value(
          combatant.actorId,
          'combatants',
          'Phase0a actor id 重复',
        );
      }
      snapshots[combatant.actorId] = _snapshotFor(combatant, boundSkills);
    }
    return Phase0aBattleSnapshotBundle(
      combatants: snapshots,
      moveBindings: moveBindings,
    );
  }

  Phase0aDamageSnapshot _snapshotFor(
    Phase0aCombatantInput combatant,
    Map<String, SkillDef> boundSkills,
  ) {
    final c = combatant.snapshot;
    final id = combatant.actorId;
    // —— 动态机制构造期 fail-fast(不静默填中性值冒充支持)——
    if (c.forgingLifestealPct != 0) {
      throw StateError(
        'Phase0a 快照工厂 $id: 吸血率非零(${c.forgingLifestealPct}),'
        'reducer 无回血输出,禁止静默丢失',
      );
    }
    if (c.guardianWardMult != null || c.guardianDefIds.isNotEmpty) {
      throw StateError(
        'Phase0a 快照工厂 $id: 护法结界配置随护法存活变化,'
        '静态快照无法正确承载,需 state-aware resolver',
      );
    }
    if (c.vulnerabilityMult != null) {
      throw StateError(
        'Phase0a 快照工厂 $id: 脆弱窗口配置随蓄力/踉跄变化,'
        '静态快照无法正确承载,需 state-aware resolver',
      );
    }
    // 熟练度:只调 SkillProficiency.stageFor / combinedMult 与
    // SkillDef.proficiency.damagePctAt(与旧战斗内 adapter 同调用序),
    // 不复制推导公式;无使用记录 = uses 0 → 阶段表首阶语义。
    final proficiencyDamageMults = <String, double>{};
    boundSkills.forEach((skillId, skill) {
      final uses = c.skillUses[skillId] ?? 0;
      final perSkillPct =
          skill.proficiency?.damagePctAt(
            SkillProficiency.stageFor(uses, _numbers.skillProficiency).id,
          ) ??
          0.0;
      proficiencyDamageMults[skillId] = SkillProficiency.combinedMult(
        uses,
        perSkillPct,
        _numbers.skillProficiency,
      );
    });

    return Phase0aDamageSnapshot(
      internalForce: c.internalForce,
      equipmentAttack: c.totalEquipmentAttack,
      cultivationLayer: c.mainCultivationLayer,
      school: c.school,
      realmTier: c.realmTier,
      realmLayer: c.realmLayer,
      defenseRate: c.defenseRate,
      evasionRate: c.evasionRate,
      criticalRate: c.criticalRate,
      attackPowerMultiplier: c.attackPowerMultiplier,
      proficiencyDamageMults: proficiencyDamageMults,
      outputMultiplier: c.outputMultiplier,
      // 弱点/抗性表防御副本(快照构造器再做不可修改副本)。
      schoolDamageTakenMults: Map.of(c.schoolDamageTakenMult),
      // 护法/脆弱配置已 fail-fast,中性乘子语义安全。
      wardMult: 1.0,
      piercePct: c.forgingPiercePct,
      // 非零已在上方 fail-fast,恒 0(与 adapter 校验口径一致)。
      lifestealPct: 0.0,
      // 凝甲词条:只按既有 numbers 映射,无词条用中性乘子。
      critDamageTakenMult: c.activeBuffs.contains('cycle_ningjia')
          ? _numbers.cycleEvolution.traits.ningjia.critDamageTakenMult
          : 1.0,
    );
  }
}
