import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

/// 跨系统数值红线 audit · 2026-05-25 (nightshift T20)
///
/// 目标:盘点 P2.2 心魔 mirror_caps / P3.1 LightFoot terrain damage_multiplier /
///       P3.2 MassBattle formation damage_multiplier / P1.2 江湖恩怨 enmity
///       attackPowerMultiplier 接入点叠加 worst-case 是否破 §5.4 红线
///       (普攻 ≤ 8000 / 暴击 ≤ 100000 / 玩家血 ≤ 20000 / 内力 ≤ 15000)。
///
/// 实测路径:
/// - DamageCalculator.calculate(damage_calculator.dart:126)**不含** APM
///   (旧路径,test 直接走),`raw = base * cult * school * crit * def * realm`
/// - _DefaultGroundStrategy._calculateInBattle(strategy/default_ground_strategy.dart:421)
///   **含** APM 末端乘项 `raw = base * cult * school * crit * def * realm * APM`
/// - LightFootStrategy._bake / MassBattleStrategy._bake **SET** 不乘,
///   stage_light_foot_xx 与 stage_mass_battle_xx 命名隔离,**不可能同 stage 双烘焙**
///
/// 测族策略:① 用 DamageCalculator 取 `r.mainDamage`(无 APM 基线)
///         ② 手算 APM 末端乘后值(模拟 strategy 实际路径)
///         ③ 对 APM 后值 expect lessThanOrEqualTo(red_line)
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  setUp(() async {
    await GameRepository.loadAllDefs(loader: fileLoader);
  });

  tearDown(GameRepository.resetForTest);

  group('R5 跨系统普伤红线 §5.4 ≤ 8000 压测', () {
    test('R5.1 baseline · APM=1.0 无 multiplier · 普攻 ≤ 8000', () {
      // Demo 实际可达值:一流境界 8000 内力 + 1500 装备 + 普攻 500 + 防御 0.20
      // 基础公式 (8000*0.4 + 1500 + 500) * 1.0 * 1.0 * 1.0 * 0.80 * 1.0 = 3760
      final r = _calcBoundary(
        attackerTier: RealmTier.yiLiu,
        defenderTier: RealmTier.yiLiu,
        internalForce: 8000,
        equipmentAttack: 1500,
        skillPower: 500,
      );
      // strategy path 末端乘 APM=1.0 default
      expect(_withApm(r.mainDamage, 1.0), lessThanOrEqualTo(8000),
          reason: 'R5.1 baseline 无 APM 修饰,Demo 一流境界普攻应远低于红线');
    });

    test('R5.2 P3.1 terrain rooftop APM=1.15 单维度 · 普攻 ≤ 8000', () {
      // LightFootStrategy._bake 烘焙 terrain.rooftop.damage_multiplier=1.15
      // 双方对等,attacker.attackPowerMultiplier=1.15 → 末端乘 1.15
      final r = _calcBoundary(
        attackerTier: RealmTier.yiLiu,
        defenderTier: RealmTier.yiLiu,
        internalForce: 8000,
        equipmentAttack: 1500,
        skillPower: 500,
      );
      expect(_withApm(r.mainDamage, 1.15), lessThanOrEqualTo(8000),
          reason: 'P3.1 rooftop APM=1.15 single dim 不破 §5.4');
    });

    test('R5.3 P3.2 formation fengShi APM=1.10 单维度 · 普攻 ≤ 8000', () {
      // MassBattleStrategy._bake 烘焙 formation.fengShi.damage_multiplier=1.10
      // 仅 leftTeam(玩家)烘焙,敌方不沾 — 但 mainDamage 计算视角仍是 attacker
      final r = _calcBoundary(
        attackerTier: RealmTier.yiLiu,
        defenderTier: RealmTier.yiLiu,
        internalForce: 8000,
        equipmentAttack: 1500,
        skillPower: 500,
      );
      expect(_withApm(r.mainDamage, 1.10), lessThanOrEqualTo(8000),
          reason: 'P3.2 fengShi APM=1.10 single dim 不破 §5.4');
    });

    test('R5.4 P1.2 enmity APM=1.25 单维度(spec 假定值) · 普攻 ≤ 8000', () {
      // P1.2 江湖恩怨 spec(commit 4cc649a)假定 enmity_combat_modifier.clamp_max=1.25
      // 当前 T17 未实装到 lib/,审计基于 spec 上限 1.25 验红线
      final r = _calcBoundary(
        attackerTier: RealmTier.yiLiu,
        defenderTier: RealmTier.yiLiu,
        internalForce: 8000,
        equipmentAttack: 1500,
        skillPower: 500,
      );
      expect(_withApm(r.mainDamage, 1.25), lessThanOrEqualTo(8000),
          reason: 'P1.2 enmity APM=1.25 spec clamp_max 不破 §5.4');
    });

    test('R5.5 跨系统 P3.1 + P1.2 烘焙覆盖语义实测 · 普攻 ≤ 8000', () {
      // 关键 audit 发现:LightFootStrategy._bake 是 SET 而非乘(light_foot_strategy.dart:120),
      // 若 P1.2 enmity 后注入,会覆盖 terrain 值;反之亦然。
      // 实际产线:_bake 在 runToEnd 入口,enmity 注入位置待 T17 ship 决定。
      // 若选「乘」语义:1.15 * 1.25 = 1.4375;若选「覆盖」(SET):取后注入值
      // 保守审计:用乘语义压最 worst-case 验
      final r = _calcBoundary(
        attackerTier: RealmTier.yiLiu,
        defenderTier: RealmTier.yiLiu,
        internalForce: 8000,
        equipmentAttack: 1500,
        skillPower: 500,
      );
      final apmStacked = 1.15 * 1.25; // worst-case 乘语义
      expect(_withApm(r.mainDamage, apmStacked), lessThanOrEqualTo(8000),
          reason: 'P3.1×P1.2 乘语义 APM≈1.44 (worst-case) 不破 §5.4');
    });

    test('R5.6 跨系统 P3.2 + P1.2 乘语义 APM=1.10×1.25 · 普攻 ≤ 8000', () {
      final r = _calcBoundary(
        attackerTier: RealmTier.yiLiu,
        defenderTier: RealmTier.yiLiu,
        internalForce: 8000,
        equipmentAttack: 1500,
        skillPower: 500,
      );
      final apmStacked = 1.10 * 1.25; // 1.375
      expect(_withApm(r.mainDamage, apmStacked), lessThanOrEqualTo(8000),
          reason: 'P3.2×P1.2 乘语义 APM≈1.38 不破 §5.4');
    });

    test('R5.7 worst-case 暴击 + 三 APM 链 ≤ 100000 (§5.4 不入十万)', () {
      // 暴击是独立路径(§5.4 「大招暴击 几万,不许进十万」)
      // worst-case:刚猛打阴柔 1.25 + 心法 jiJing 3.0 + 暴击 1.5
      //           + 三 APM 累乘 1.15*1.10*1.25 ≈ 1.58
      // 注意:实际 stages 隔离(light_foot vs mass_battle stage 不重),
      // 但 audit 应压最坏理论值看是否破 §5.4 大招红线 100000
      final r = _calcBoundary(
        attackerTier: RealmTier.wuSheng,
        defenderTier: RealmTier.wuSheng,
        internalForce: 15000,
        equipmentAttack: 2000,
        skillPower: 500,
        attackerSchool: TechniqueSchool.gangMeng,
        defenderSchool: TechniqueSchool.yinRou,
        cultivationLayer: CultivationLayer.jiJing,
        forceCritical: true,
      );
      // r.mainDamage = base * 3.0 * 1.25 * 1.5 * 0.65 * 1.0
      // APM 三链乘 1.15 * 1.10 * 1.25 ≈ 1.581
      final stacked = _withApm(r.mainDamage, 1.15 * 1.10 * 1.25);
      expect(stacked, lessThanOrEqualTo(100000),
          reason: 'GDD §5.4 大招暴击 不许进十万 worst-case 验');
    });

    test('R5.8 P1.2 enmity clamp_max 真值从 NumbersConfig 加载(契约不放宽)', () {
      // P1.2 spec(p1_2_jianghu_enmity_spec_2026-05-24.md)规定
      // enmity threshold -50 → 1.15 / -80 → 1.25,attackPowerMultiplier 上限 1.25。
      // NpcRelationService.attackPowerMultFor 必须 clamp ≤ numbers.yaml `clamp_max`。
      // 从 NumbersConfig 加载真值断言,防恒等断言失语(memory feedback_red_line_test_semantics)。
      final clampMax =
          GameRepository.instance.numbers.jianghu.enmityCombatModifier.clampMax;
      // §5.4 普伤 8000 红线 / APM ≤ 1.25 → 末端乘 ≤ 10000 留余量
      expect(clampMax, lessThanOrEqualTo(1.25),
          reason: 'P1.2 spec 契约:enmity APM 上限 ≤ 1.25 不可放宽(防 §5.4 越界)');
      expect(clampMax, greaterThan(1.0),
          reason: 'clamp_max 应 > 1.0(否则恩怨 buff 失效)');
    });

    test('R5.9 LightFoot 单 strategy APM 上限真值从 NumbersConfig 加载', () {
      // 关键发现:LightFootStrategy._bake(line 120)与 MassBattleStrategy._bake(line 182)
      // 都用 `attackPowerMultiplier: m.damageMultiplier` SET 不乘,
      // **若同 BattleCharacter 经 2 strategy 烘焙,后者覆盖前者**(实测过)
      // 但 stages.yaml: stage_light_foot_xx ∩ stage_mass_battle_xx = ∅
      // (StageType.lightFoot vs StageType.massBattle 命名隔离),
      // 实际产线无法触发同 BattleState 双烘焙路径。
      // 契约假设:不会同时烘焙 → 单 strategy APM ≤ 全 terrain damageMultiplier max。
      // 从 NumbersConfig 加载真值(memory feedback_red_line_test_semantics)。
      final terrainMults = GameRepository
          .instance.numbers.lightFoot.terrainModifiers.values
          .map((m) => m.damageMultiplier);
      final singleStrategyMaxApm = terrainMults.reduce(max);
      expect(singleStrategyMaxApm, lessThanOrEqualTo(1.15),
          reason: '单 strategy APM 上限契约(rooftop 1.15)不可放宽');
    });

    test('R5.10 §5.4 数值红线 cap mirror_caps 不破', () {
      final caps = GameRepository.instance.numbers.innerDemon.mirrorCaps;
      // §5.4 玩家血 ≤ 20000
      expect(caps.hpMax, lessThanOrEqualTo(20000),
          reason: 'mirror_caps.hp_max 受 §5.4 玩家血上限约束');
      // §5.4 内力 ≤ 15000
      expect(caps.internalForceMax, lessThanOrEqualTo(15000),
          reason: 'mirror_caps.internal_force_max 受 §5.4 内力上限约束');
      // §5.4 装备攻击:mirror_caps 总和 6000 = 3 件 × 单件 2000(§5.4 单件维度)
      // memory feedback_mirror_buff_cap_dimension:单件 vs 总 cap 不同维
      expect(caps.attackPowerMax, lessThanOrEqualTo(6000),
          reason: '3 件求和 cap = 6000(§5.4 单件 2000 × 3 件)');
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 工具:模拟 _DefaultGroundStrategy 末端 APM 乘项(damage_calculator 不消费 APM,
// 但 strategy 产线路径 line 422 `raw = ... * atkPowerMult`,审计 strategy 路径
// 用 r.mainDamage(已乘 cult/school/crit/def/realm) × APM 重现)
// ─────────────────────────────────────────────────────────────────────────────

int _withApm(int mainDamageNoApm, double apm) {
  return (mainDamageNoApm * apm).toInt();
}

AttackResult _calcBoundary({
  RealmTier attackerTier = RealmTier.xueTu,
  RealmLayer attackerLayer = RealmLayer.qiMeng,
  RealmTier defenderTier = RealmTier.xueTu,
  RealmLayer defenderLayer = RealmLayer.qiMeng,
  int internalForce = 1000,
  int equipmentAttack = 100,
  int skillPower = 500,
  TechniqueSchool attackerSchool = TechniqueSchool.gangMeng,
  TechniqueSchool defenderSchool = TechniqueSchool.gangMeng,
  CultivationLayer cultivationLayer = CultivationLayer.chuKui,
  bool forceCritical = false,
}) {
  final attacker = _mkChar(
    tier: attackerTier,
    layer: attackerLayer,
    internalForce: internalForce,
    agility: 0,
    school: attackerSchool,
  );
  final defender = _mkChar(
    tier: defenderTier,
    layer: defenderLayer,
    internalForce: 1000,
    agility: 0,
    school: defenderSchool,
  );
  final ctx = AttackContext(
    attacker: attacker,
    attackerEquipped: [_mkEquip(baseAttack: equipmentAttack)],
    attackerMainTech: _mkTech(
      tier: TechniqueTier.ruMenGong,
      school: attackerSchool,
      layer: cultivationLayer,
    ),
    skill: _mkSkill(power: skillPower, type: SkillType.normalAttack),
    defender: defender,
    defenderEquipped: const [],
    defenderMainTech: _mkTech(
      tier: TechniqueTier.ruMenGong,
      school: defenderSchool,
    ),
    forceCritical: forceCritical,
    rng: Random(99),
  );
  return DamageCalculator.calculate(ctx, GameRepository.instance.numbers);
}

Character _mkChar({
  required RealmTier tier,
  required RealmLayer layer,
  required int internalForce,
  int constitution = 5,
  int enlightenment = 5,
  int agility = 5,
  int fortune = 5,
  TechniqueSchool? school,
}) {
  final attrs = Attributes()
    ..constitution = constitution
    ..enlightenment = enlightenment
    ..agility = agility
    ..fortune = fortune;
  return Character.create(
    name: '测试',
    realmTier: tier,
    realmLayer: layer,
    attributes: attrs,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: internalForce,
    school: school,
  );
}

Equipment _mkEquip({
  int baseAttack = 0,
  int baseHealth = 0,
  int baseSpeed = 0,
}) {
  return Equipment.create(
    defId: 'test',
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    obtainedAt: DateTime(2026, 1, 1),
    obtainedFrom: 'test',
    baseAttack: baseAttack,
    baseHealth: baseHealth,
    baseSpeed: baseSpeed,
  );
}

Technique _mkTech({
  required TechniqueTier tier,
  required TechniqueSchool school,
  CultivationLayer layer = CultivationLayer.chuKui,
}) {
  return Technique.create(
    defId: 'test_tech',
    ownerCharacterId: 1,
    tier: tier,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 1, 1),
    cultivationLayer: layer,
  );
}

SkillDef _mkSkill({required int power, required SkillType type}) {
  return SkillDef(
    id: 'test_skill',
    name: '测试招式',
    description: 'test',
    type: type,
    powerMultiplier: power,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'none',
  );
}
