import '../../core/domain/enums.dart';
import '../defs/equipment_def.dart';
import '../defs/skill_def.dart';
import '../defs/technique_def.dart';
import '../numbers_config.dart';

/// 心法/装备域加载期红线(2026-07-18 审查批C 自 GameRepository 抽出)。
///
/// 体例:顶层自由函数 + 显式参数,参数名与 GameRepository 字段名一致,
/// 方法体自抽出起逐字未改;越界抛 [StateError] 启动失败(fail-fast)。

/// 心法 + 招式红线（Phase 3 Week 8 T64）：
/// - 覆盖度：7 阶 × 3 流派 = 21 个 (tier,school) 组合每个 ≥ 1 本
/// - 每本：skillIds.length == 3
/// - 每本对应的 3 招 type 必须精确为 {normalAttack, powerSkill, ultimate}
/// - 每招 parentTechniqueDefId 必须指向自身所属 technique
///
/// 允许测试 fixture 不带 techniqueDefs(为空时整体跳过)。
void enforceTechniqueRedLines({
  required Map<String, TechniqueDef> techniqueDefs,
  required Map<String, SkillDef> skillDefs,
}) {
  if (techniqueDefs.isEmpty) return;
  for (final tier in TechniqueTier.values) {
    for (final school in TechniqueSchool.values) {
      final hit = techniqueDefs.values.any(
        (t) => t.tier == tier && t.school == school,
      );
      if (!hit) {
        throw StateError('心法覆盖度不足：缺 ${tier.name}/${school.name} 组合');
      }
    }
  }
  for (final t in techniqueDefs.values) {
    if (t.skillIds.length != 3) {
      throw StateError(
        '心法 ${t.id} skillIds.length=${t.skillIds.length},应 == 3',
      );
    }
    final types = <SkillType>{};
    for (final sid in t.skillIds) {
      final s = skillDefs[sid];
      if (s == null) {
        throw StateError('心法 ${t.id} 引用不存在的 skill: $sid');
      }
      if (s.parentTechniqueDefId != t.id) {
        throw StateError(
          '心法 ${t.id} 招式 $sid parentTechniqueDefId='
          '${s.parentTechniqueDefId},应指向自身',
        );
      }
      types.add(s.type);
    }
    const required = {
      SkillType.normalAttack,
      SkillType.powerSkill,
      SkillType.ultimate,
    };
    if (types.length != required.length || !types.containsAll(required)) {
      throw StateError(
        '心法 ${t.id} 招式 type 分布 $types,'
        '应精确为 {normalAttack, powerSkill, ultimate}',
      );
    }
  }
}

/// 装备红线（Phase 3 Week 7 T63）：
/// - 单件：baseAttackMax ≤ 2000（GDD §5.4 红线）/ baseAttackMin 区间合法
/// - 覆盖度：每阶（7 阶）≥ 5 件 / 每阶 weapon 三流派各 ≥ 1 / armor + accessory 各 ≥ 1
///
/// 允许测试 fixture 缺装备段(equipmentDefs 为空时跳过覆盖度,仅放过 master/stage 等独立测试)。
void enforceEquipmentRedLines({
  required Map<String, EquipmentDef> equipmentDefs,
  required NumbersConfig numbers,
}) {
  for (final e in equipmentDefs.values) {
    if (e.baseAttackMax > 2000) {
      throw StateError(
        '红线越界：装备 ${e.id} baseAttackMax=${e.baseAttackMax} > 2000',
      );
    }
    if (e.baseAttackMin < 0 || e.baseAttackMin > e.baseAttackMax) {
      throw StateError(
        '装备 ${e.id} baseAttackMin/Max 不合法：'
        '${e.baseAttackMin}/${e.baseAttackMax}',
      );
    }
    // 2026-06-12 爆品展示内容化：tier≥重器(treasureDrop.minTier)走印章展示，
    // 必有 tagline 典故金句。红线守非空，防漏导致爆品展示缺典故句。
    if (e.tier.index >= numbers.treasureDrop.minTier.index &&
        (e.tagline == null || e.tagline!.trim().isEmpty)) {
      throw StateError(
        '装备 ${e.id} tier=${e.tier.name} ≥ 爆品门槛'
        '(${numbers.treasureDrop.minTier.name}) 但 tagline 缺失，'
        '爆品展示需典故金句',
      );
    }
  }
  if (equipmentDefs.isEmpty) return;
  for (final tier in EquipmentTier.values) {
    final tierItems = equipmentDefs.values.where((e) => e.tier == tier);
    if (tierItems.length < 5) {
      throw StateError('装备覆盖度不足：${tier.name} 阶共 ${tierItems.length} 件,应 ≥ 5');
    }
    final weapons = tierItems.where((e) => e.slot == EquipmentSlot.weapon);
    final armors = tierItems.where((e) => e.slot == EquipmentSlot.armor);
    final accessories = tierItems.where(
      (e) => e.slot == EquipmentSlot.accessory,
    );
    if (armors.isEmpty) {
      throw StateError('装备覆盖度不足：${tier.name} 阶缺 armor');
    }
    if (accessories.isEmpty) {
      throw StateError('装备覆盖度不足：${tier.name} 阶缺 accessory');
    }
    for (final school in TechniqueSchool.values) {
      final hit = weapons.any((w) => w.schoolBias == school);
      if (!hit) {
        throw StateError('装备覆盖度不足：${tier.name} 阶缺 ${school.name} 流派武器');
      }
    }
  }
}
