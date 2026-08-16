import 'dart:math';

import '../../../../core/domain/enums.dart';
import '../../../../data/defs/skill_def.dart';
import '../../../../data/numbers_config.dart';
import '../../domain/damage_calculator.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';

/// Phase 0A 伤害快照:不可变、显式注入的 `calculateResolved` 入参载体。
///
/// 全部字段为调用方已解析的 primitive/enum(沿 `calculate` /
/// `_calculateInBattle` 两 adapter 体例):本类不推导任何公式,只承载值。
/// 倍率类字段全部 required(源码契约:application/phase0a 禁止数值默认值,
/// 调用方显式传 1.0/0.0 表无修饰),语义与 `calculateResolved` 默认对齐。
final class Phase0aDamageSnapshot {
  Phase0aDamageSnapshot({
    required this.internalForce,
    required this.equipmentAttack,
    required this.cultivationLayer,
    required this.school,
    required this.realmTier,
    required this.realmLayer,
    required this.defenseRate,
    required this.evasionRate,
    required this.criticalRate,
    required this.attackPowerMultiplier,
    required Map<String, double> proficiencyDamageMults,
    required this.outputMultiplier,
    required Map<TechniqueSchool, double> schoolDamageTakenMults,
    required this.wardMult,
    required this.piercePct,
    required this.lifestealPct,
    required this.critDamageTakenMult,
  }) : // 防御性不可修改副本:外部 map 构造后 mutation 不得改变快照,
       // 否则同 seed 回放会被静默污染(2026-08-16 复核拍板)。
       proficiencyDamageMults = Map.unmodifiable(proficiencyDamageMults),
       schoolDamageTakenMults = Map.unmodifiable(schoolDamageTakenMults);

  /// 永久内力(不随真气消耗变化,沿战斗快照口径)。
  final int internalForce;

  /// 装备攻击合计(调用方已解析强化×共鸣×开锋)。
  final int equipmentAttack;

  /// 主修心法修炼度层。
  final CultivationLayer cultivationLayer;

  /// 流派(攻方取自其主修心法,守方同理)。
  final TechniqueSchool school;

  final RealmTier realmTier;
  final RealmLayer realmLayer;

  /// 守方防御率(调用方已含相生 defensePct 等注入)。
  final double defenseRate;

  final double evasionRate;
  final double criticalRate;

  /// 烘焙攻击乘子(轻功/群战/恩怨等,无修饰传 1.0)。
  final double attackPowerMultiplier;

  /// 调用方预解析的 per-skill 熟练度综合倍率表(skillId → mult)。
  /// adapter 按当前 binding 的 `SkillDef.id` 纯查表(缺条目回落 1.0),
  /// 不复制 `SkillProficiency` 推导公式(2026-08-16 拍板)。
  final Map<String, double> proficiencyDamageMults;

  /// 临时状态输出乘数(无修饰传 1.0)。
  final double outputMultiplier;

  /// 弱点/抗性受伤乘子表(攻方流派 → mult,沿 `weaknessMultOf` 体例
  /// 纯查表,缺条目 1.0)。>1.0 弱点 / <1.0 抗性。
  final Map<TechniqueSchool, double> schoolDamageTakenMults;

  /// 护法结界×脆弱窗口的合并承伤乘子(调用方已解析,无修饰传 1.0)。
  final double wardMult;

  /// 开锋破甲:绝对减防御率(无破甲传 0.0)。
  final double piercePct;

  /// 开锋吸血率。**当前必须为 0**:Phase 0A reducer 无回血输出,
  /// 非零值由 adapter 在计算前 fail-fast,禁止静默丢效果。
  final double lifestealPct;

  /// 凝甲词条:暴击增量衰减系数(无凝甲传 1.0)。
  final double critDamageTakenMult;
}

/// `Phase0aDamageResolver` 的生产实现:只做「快照字段解析 → 调
/// `DamageCalculator.calculateResolved`」,禁止第二套公式。
///
/// 契约(第三批派单 + 2026-08-16 拍板):
/// - 输出映射固定:`isHit = !AttackResult.isDodged`、`isCritical` 原样、
///   `damage = finalDamage`(不用 `mainDamage`,不重算、不 clamp)。
/// - 招式按 [Phase0aDamageKind] 显式绑定;`containsKey` 区分缺绑定
///   (StateError)与 null control-only 绑定(零伤短路)。
/// - control-only 绑定:不调 calculator、不消费 RNG,返回
///   hit=true/critical=false/damage=0;但 attacker/target 快照合法性
///   仍先全量校验(非法配置不得被控制技静默掩盖)。
/// - 缺 actor/缺绑定、负值/NaN/Infinity 快照、非零吸血一律计算前
///   fail-fast;`AttackResult.appliedEffects` 无 Phase0A 消费方,
///   本片登记残留风险、不扩状态系统。
final class Phase0aDamageCalculatorAdapter implements Phase0aDamageResolver {
  Phase0aDamageCalculatorAdapter({
    required Map<String, Phase0aDamageSnapshot> combatants,
    required Map<Phase0aDamageKind, SkillDef?> moveBindings,
    required NumbersConfig numbers,
    required Random rng,
  }) : _combatants = Map.unmodifiable(combatants),
       _moveBindings = Map.unmodifiable(moveBindings),
       _numbers = numbers,
       _rng = rng;

  final Map<String, Phase0aDamageSnapshot> _combatants;
  final Map<Phase0aDamageKind, SkillDef?> _moveBindings;
  final NumbersConfig _numbers;
  final Random _rng;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
  }) {
    final attacker = _combatants[attackerId];
    if (attacker == null) {
      throw StateError('Phase0a 伤害快照缺 attacker: $attackerId');
    }
    final target = _combatants[targetId];
    if (target == null) {
      throw StateError('Phase0a 伤害快照缺 target: $targetId');
    }
    if (!_moveBindings.containsKey(kind)) {
      throw StateError('Phase0a 招式缺 kind 绑定: ${kind.name}');
    }
    // control-only 同样先验:非法快照不得被零伤绑定静默掩盖(拍板Ⓐ)。
    _validateSnapshot(attacker, attackerId);
    _validateSnapshot(target, targetId);

    final skill = _moveBindings[kind];
    if (skill == null) {
      // control-only 显式绑定:不调 calculator、不消费 RNG。
      return const Phase0aResolvedHit(
        isHit: true,
        isCritical: false,
        damage: 0,
      );
    }

    final result = DamageCalculator.calculateResolved(
      attackerInternalForce: attacker.internalForce,
      attackerEquipmentAttack: attacker.equipmentAttack,
      attackerCultivationLayer: attacker.cultivationLayer,
      attackerSchool: attacker.school,
      defenderSchool: target.school,
      attackerRealmTier: attacker.realmTier,
      attackerRealmLayer: attacker.realmLayer,
      defenderRealmTier: target.realmTier,
      defenderRealmLayer: target.realmLayer,
      defenderDefenseRate: target.defenseRate,
      defenderEvasionRate: target.evasionRate,
      attackerCriticalRate: attacker.criticalRate,
      attackPowerMultiplier: attacker.attackPowerMultiplier,
      skill: skill,
      n: _numbers,
      rng: _rng,
      // 熟练度按 binding 的 skill.id 查调用方预解析表(拍板Ⓑ)。
      proficiencyDamageMult: attacker.proficiencyDamageMults[skill.id] ?? 1.0,
      defenderCritDamageTakenMult: target.critDamageTakenMult,
      outputMultiplier: attacker.outputMultiplier,
      defenderSchoolDamageMult:
          target.schoolDamageTakenMults[attacker.school] ?? 1.0,
      defenderWardMult: target.wardMult,
      attackerPiercePct: attacker.piercePct,
      attackerLifestealPct: attacker.lifestealPct, // 已 fail-fast,恒 0
    );
    // 冻结映射:不重算、不 clamp、不用 mainDamage。
    return Phase0aResolvedHit(
      isHit: !result.isDodged,
      isCritical: result.isCritical,
      damage: result.finalDamage,
    );
  }

  /// 快照合法性:全部数值有限且非负;非零吸血在此 fail-fast
  /// (当前 reducer 无回血输出,禁止静默丢失)。
  static void _validateSnapshot(Phase0aDamageSnapshot snapshot, String id) {
    if (snapshot.lifestealPct != 0) {
      throw StateError(
        'Phase0a 快照 $id 吸血率非零(${snapshot.lifestealPct}):'
        'reducer 无回血输出,禁止静默丢失',
      );
    }
    _requireNonNegativeInt(snapshot.internalForce, '$id.internalForce');
    _requireNonNegativeInt(snapshot.equipmentAttack, '$id.equipmentAttack');
    _requireUsable(snapshot.defenseRate, '$id.defenseRate');
    _requireUsable(snapshot.evasionRate, '$id.evasionRate');
    _requireUsable(snapshot.criticalRate, '$id.criticalRate');
    _requireUsable(
      snapshot.attackPowerMultiplier,
      '$id.attackPowerMultiplier',
    );
    _requireUsable(snapshot.outputMultiplier, '$id.outputMultiplier');
    _requireUsable(snapshot.wardMult, '$id.wardMult');
    _requireUsable(snapshot.piercePct, '$id.piercePct');
    _requireUsable(snapshot.critDamageTakenMult, '$id.critDamageTakenMult');
    snapshot.proficiencyDamageMults.forEach((skillId, mult) {
      _requireUsable(mult, '$id.proficiencyDamageMults[$skillId]');
    });
    snapshot.schoolDamageTakenMults.forEach((school, mult) {
      _requireUsable(mult, '$id.schoolDamageTakenMults[${school.name}]');
    });
  }

  static void _requireNonNegativeInt(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'must be non-negative');
    }
  }

  /// 与 reducer `_isUsableNumber` 同口径:必须有限且非负。
  /// NaN 比较恒 false 会绕过一切边界检查,Infinity/负值会被公式静默合法化。
  static void _requireUsable(double value, String name) {
    if (!(value.isFinite && value >= 0)) {
      throw ArgumentError.value(value, name, 'must be finite and non-negative');
    }
  }
}
