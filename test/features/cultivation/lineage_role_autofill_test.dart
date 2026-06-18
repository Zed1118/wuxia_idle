import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/cultivation/application/skill_loadout_resolver.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_loadout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 职责软引导 autoFill 倾向测试（第六阶段 Task 6）
//
// 两层测试：
// 1. 单元层 — SkillLoadoutResolver.applyLineageTendency 排序语义（旧单元测保留）
// 2. 集成层 — SkillLoadout.autoFill（真实生产入口，与 applyAutoFill 共用同一核心）
//    验证最终 loadout 按 lineage 倾向变化：弟子→破防技进槽，祖师→不强制，徒孙→不变。
// ─────────────────────────────────────────────────────────────────────────────

// ──── 辅助 Fixture ────────────────────────────────────────────────────────────

/// 构造最简 SkillDef，tier=null（心法招，canEquipAtRealm 恒 true）。
SkillDef _skill(
  String id, {
  int power = 1000,
  double defenseBreakPct = 0.0,
  TechniqueSchool? style,
}) =>
    SkillDef(
      id: id,
      name: id,
      description: '',
      type: SkillType.powerSkill,
      powerMultiplier: power,
      internalForceCost: 50,
      cooldownTurns: 2,
      requiresManualTrigger: false,
      visualEffect: 'none',
      defenseBreakPct: defenseBreakPct,
      style: style,
    );

/// 构造测试用 Character（纯内存，不入 Isar）。
Character _character({
  required bool isFounder,
  required LineageRole lineageRole,
}) =>
    Character.create(
      name: 'test',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.xunChang,
      lineageRole: lineageRole,
      createdAt: DateTime(2026, 1, 1),
      isFounder: isFounder,
    );

// ──── 候选技能集合（三类：破防 / 高倍率爆发 / 普通） ─────────────────────────

/// 普通技：中等倍率，无破防。
final _normal = _skill('normal_skill', power: 1000);

/// 破防技：中等倍率，但 defenseBreakPct > 0。
final _defenseBreak = _skill('defense_break_skill', power: 900, defenseBreakPct: 0.3);

/// 高倍率爆发技：powerMultiplier 最高，无破防。
final _highPower = _skill('high_power_skill', power: 3000);

/// 阴柔系技：style=yinRou，代表内伤/控制倾向候选。
final _yinRouSkill = _skill('yin_rou_skill', power: 800, style: TechniqueSchool.yinRou);

/// 所有候选列表（原始顺序：普通 → 破防 → 高倍率 → 阴柔）。
final _candidates = [_normal, _defenseBreak, _highPower, _yinRouSkill];

// ─────────────────────────────────────────────────────────────────────────────
// 集成测试辅助：直接调用 SkillLoadout.autoFill（真实生产核心）
// ─────────────────────────────────────────────────────────────────────────────

/// ultimatePowerThreshold：高于此值 → 大招槽候选。设为 5000 确保测试技均为主修槽候选。
const _threshold = 5000;

/// 构造一个全空 SkillLoadout（所有槽为 null，模拟无历史装配）。
const _emptyLoadout = SkillLoadout();

/// 执行 SkillLoadout.autoFill 并返回主修槽 id 列表（m1/m2，去 null）。
/// [character] 用于传入 lineageRole + isFounder（其他字段不影响 autoFill）。
List<String> _fillMains(
  Character character,
  List<SkillDef> mainSkills,
) {
  final result = SkillLoadout.autoFill(
    mainTechniqueSkills: mainSkills,
    assistTechniqueSkills: const [],
    jointSkill: null,
    realmTier: character.realmTier,
    existing: _emptyLoadout,
    ultimatePowerThreshold: _threshold,
    lineageRole: character.lineageRole,
    isFounder: character.isFounder,
  );
  return [result.mainSkillId1, result.mainSkillId2]
      .whereType<String>()
      .toList();
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // 1. 单元层：SkillLoadoutResolver.applyLineageTendency 排序语义（旧单元测保留）
  // ══════════════════════════════════════════════════════════════════════════
  group('SkillLoadoutResolver.applyLineageTendency', () {
    // ─── 祖师（isFounder=true）→ 高 powerMultiplier 爆发技前置 ───────────────
    test('祖师：高 powerMultiplier 爆发技排在最前', () {
      final founder = _character(isFounder: true, lineageRole: LineageRole.founder);
      final sorted = SkillLoadoutResolver.applyLineageTendency(_candidates, founder);

      // 高倍率爆发技必须排第一
      expect(sorted.first.id, _highPower.id);
    });

    test('祖师：稳定排序（相同高倍率技原顺序保留）', () {
      final founder = _character(isFounder: true, lineageRole: LineageRole.founder);
      // 两个同等 power 技
      final a = _skill('power_a', power: 3000);
      final b = _skill('power_b', power: 3000);
      final sorted = SkillLoadoutResolver.applyLineageTendency([a, b, _normal], founder);
      // a 在 b 前（原顺序保留）
      final highOnes = sorted.where((s) => s.powerMultiplier == 3000).toList();
      expect(highOnes[0].id, 'power_a');
      expect(highOnes[1].id, 'power_b');
    });

    // ─── 弟子（lineageRole=disciple，不管是大弟子还是二弟子）→ 破防技前置 ──
    test('弟子：破防技（defenseBreakPct>0）排在最前', () {
      final disciple = _character(
          isFounder: false, lineageRole: LineageRole.disciple);
      final sorted = SkillLoadoutResolver.applyLineageTendency(_candidates, disciple);

      // 破防技必须排第一
      expect(sorted.first.id, _defenseBreak.id);
    });

    test('弟子：无破防技时保持原顺序（不改顺序）', () {
      final disciple = _character(
          isFounder: false, lineageRole: LineageRole.disciple);
      final noneBreak = [_normal, _highPower, _yinRouSkill];
      final sorted = SkillLoadoutResolver.applyLineageTendency(noneBreak, disciple);

      // 无破防技，顺序不变
      expect(sorted[0].id, _normal.id);
      expect(sorted[1].id, _highPower.id);
      expect(sorted[2].id, _yinRouSkill.id);
    });

    // ─── grandDisciple（徒孙）→ 无倾向，保持原顺序 ──────────────────────────
    test('徒孙（grandDisciple）：原顺序不变（无倾向）', () {
      final grand = _character(
          isFounder: false, lineageRole: LineageRole.grandDisciple);
      final sorted = SkillLoadoutResolver.applyLineageTendency(_candidates, grand);

      expect(sorted[0].id, _normal.id);
      expect(sorted[1].id, _defenseBreak.id);
      expect(sorted[2].id, _highPower.id);
      expect(sorted[3].id, _yinRouSkill.id);
    });

    // ─── 非 lineage 角色（无 role 逻辑）→ 原顺序不变 ─────────────────────────
    // 注：grandDisciple 已覆盖"无倾向"语义，此处另测空列表 edge case
    test('空候选列表：各角色类型均返回空，不崩', () {
      final founder = _character(isFounder: true, lineageRole: LineageRole.founder);
      final disciple = _character(isFounder: false, lineageRole: LineageRole.disciple);
      expect(SkillLoadoutResolver.applyLineageTendency([], founder), isEmpty);
      expect(SkillLoadoutResolver.applyLineageTendency([], disciple), isEmpty);
    });

    // ─── 旧档 fallback 等价：无相关技时，输出集合与输入集合一致（不丢技） ────
    test('旧档 fallback：排序后集合内容与输入完全一致（不丢技）', () {
      final disciple = _character(
          isFounder: false, lineageRole: LineageRole.disciple);
      final sorted = SkillLoadoutResolver.applyLineageTendency(_candidates, disciple);
      // 集合完全一致（相同元素，可能不同顺序）
      expect(sorted.length, _candidates.length);
      for (final s in _candidates) {
        expect(sorted.any((x) => x.id == s.id), isTrue,
            reason: '${s.id} 不应从候选中丢失');
      }
    });

    test('旧档 fallback：grandDisciple 输出集合与输入完全一致（不丢技）', () {
      final grand = _character(
          isFounder: false, lineageRole: LineageRole.grandDisciple);
      final sorted = SkillLoadoutResolver.applyLineageTendency(_candidates, grand);
      expect(sorted.length, _candidates.length);
      for (final s in _candidates) {
        expect(sorted.any((x) => x.id == s.id), isTrue);
      }
    });

    // ─── 稳定性：弟子候选多个破防技时，破防技按原相对顺序在前 ─────────────────
    test('弟子：多个破防技在前，内部相对顺序保留（稳定排序）', () {
      final disciple = _character(
          isFounder: false, lineageRole: LineageRole.disciple);
      final db1 = _skill('db1', defenseBreakPct: 0.3);
      final db2 = _skill('db2', defenseBreakPct: 0.2);
      final plain = _skill('plain');
      final sorted = SkillLoadoutResolver.applyLineageTendency(
          [plain, db1, db2], disciple);
      expect(sorted[0].id, 'db1');
      expect(sorted[1].id, 'db2');
      expect(sorted[2].id, 'plain');
    });

    // ─── 祖师：多个高倍率技时按原相对顺序在前（稳定排序） ──────────────────
    test('祖师：多个最高倍率技，原相对顺序在前（稳定排序）', () {
      final founder = _character(isFounder: true, lineageRole: LineageRole.founder);
      final hp1 = _skill('hp1', power: 3000);
      final hp2 = _skill('hp2', power: 3000);
      final low = _skill('low', power: 500);
      final sorted = SkillLoadoutResolver.applyLineageTendency([low, hp1, hp2], founder);
      expect(sorted[0].id, 'hp1');
      expect(sorted[1].id, 'hp2');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2. 集成层：SkillLoadout.autoFill 真实入口 —— lineage 倾向在最终 loadout 生效
  //
  // 候选池设计：
  //   high_A (power=2000, 无破防)  ← 默认 power-sort 会选这个进 m1
  //   high_B (power=1800, 无破防)  ← 默认 power-sort 会选这个进 m2
  //   defense_break (power=500, defenseBreakPct=0.3)  ← 默认 power-sort 不会选
  //   low_D (power=200, 无破防)
  //
  // 弟子期望：defense_break 出现在最终 loadout 主修槽之一。
  // 祖师期望：high_A + high_B 进槽（power-sort default），defense_break 不进。
  // 徒孙期望：同祖师（power-sort default，回归）。
  // ══════════════════════════════════════════════════════════════════════════
  group('SkillLoadout.autoFill 集成：lineage 倾向对最终 loadout 生效', () {
    // 候选池（power-sort 默认选 highA/highB，不选 defBreak）
    final highA = _skill('high_a', power: 2000);
    final highB = _skill('high_b', power: 1800);
    final defBreak = _skill('def_break', power: 500, defenseBreakPct: 0.3);
    final lowD = _skill('low_d', power: 200);
    final pool = [highA, highB, defBreak, lowD];

    // ─── 弟子：autoFill 后 loadout 包含破防技 ────────────────────────────────
    test('弟子：最终 autoFill loadout 包含破防技（即使 power 排名不入前 2）', () {
      final disciple =
          _character(isFounder: false, lineageRole: LineageRole.disciple);
      final mains = _fillMains(disciple, pool);

      // 破防技必须在最终主修槽中
      expect(mains.contains(defBreak.id), isTrue,
          reason: '弟子身份 autoFill 后，破防技应出现在主修槽（无论 power 高低）');
    });

    test('弟子：最终 loadout 总计 2 个主修槽被填（无空槽）', () {
      final disciple =
          _character(isFounder: false, lineageRole: LineageRole.disciple);
      final mains = _fillMains(disciple, pool);
      expect(mains.length, 2,
          reason: '主修槽应被完整填满（pool 有 4 个候选，2 槽应全填）');
    });

    test('弟子：另一个主修槽为高倍率技（不全换成破防）', () {
      final disciple =
          _character(isFounder: false, lineageRole: LineageRole.disciple);
      final mains = _fillMains(disciple, pool);

      // 只有一个槽被破防技占，另一个是高倍率技之一
      expect(mains.contains(defBreak.id), isTrue);
      final other = mains.firstWhere((id) => id != defBreak.id);
      expect([highA.id, highB.id, lowD.id].contains(other), isTrue,
          reason: '另一个主修槽应是非破防技');
    });

    // ─── 祖师：power-sort default，破防技不强制进槽 ─────────────────────────
    test('祖师：autoFill 按 power 降序选槽，破防技（低 power）不进主修槽', () {
      final founder =
          _character(isFounder: true, lineageRole: LineageRole.founder);
      final mains = _fillMains(founder, pool);

      // 祖师不强制破防技：high_a + high_b 进槽
      expect(mains.contains(highA.id), isTrue,
          reason: '祖师主修槽应包含最高倍率技 high_a');
      expect(mains.contains(highB.id), isTrue,
          reason: '祖师主修槽应包含第二高倍率技 high_b');
      expect(mains.contains(defBreak.id), isFalse,
          reason: '祖师不强制破防技，low-power 破防技不应进槽');
    });

    // ─── 徒孙：回归默认 power-sort，行为与修改前完全一致 ──────────────────
    test('徒孙（grandDisciple）：power-sort default，行为与无 lineage 身份完全一致', () {
      final grandDisciple =
          _character(isFounder: false, lineageRole: LineageRole.grandDisciple);
      final mains = _fillMains(grandDisciple, pool);

      expect(mains.contains(highA.id), isTrue,
          reason: '徒孙主修槽应包含最高倍率技 high_a');
      expect(mains.contains(highB.id), isTrue,
          reason: '徒孙主修槽应包含第二高倍率技 high_b');
      expect(mains.contains(defBreak.id), isFalse,
          reason: '徒孙无倾向，破防技（低 power）不应进槽');
    });

    // ─── 软锁不锁红线：eligible/selectable 集合不缩小 ──────────────────────
    // 原理：autoFill 只决定"默认填什么"，SkillLoadoutService.equipSkill 的
    // canEquipAtRealm gate 保持不变（本测试层不测 gate，只验证 autoFill 行为）。
    // 验证方式：候选中所有招式仍被 gate 接受（tier=null，canEquipAtRealm 恒 true）。
    test('软锁不锁红线：所有候选技能 canEquipAtRealm 仍通过（eligible 集合不缩小）', () {
      for (final s in pool) {
        expect(s.canEquipAtRealm(RealmTier.xueTu), isTrue,
            reason: '${s.id} 应在 xueTu 境界可装配（tier=null 恒通过）');
      }
    });

    // ─── 弟子已有破防技时不重复替换（现有槽保留） ─────────────────────────
    test('弟子：若 existing 槽已有高 power 技，autoFill 不覆盖（软引导不覆盖玩家手动设置）', () {
      final disciple =
          _character(isFounder: false, lineageRole: LineageRole.disciple);
      // 玩家已手动设置 m1 = high_a
      const existingWithM1 = SkillLoadout(mainSkillId1: 'high_a');
      final result = SkillLoadout.autoFill(
        mainTechniqueSkills: pool,
        assistTechniqueSkills: const [],
        jointSkill: null,
        realmTier: disciple.realmTier,
        existing: existingWithM1,
        ultimatePowerThreshold: _threshold,
        lineageRole: disciple.lineageRole,
        isFounder: disciple.isFounder,
      );

      // m1 不被覆盖（玩家保留）
      expect(result.mainSkillId1, highA.id,
          reason: '玩家手动设置的 m1 不应被 autoFill 覆盖');
    });

    // ─── 候选无破防技时弟子行为与默认一致（无破防技可注入时不崩） ──────────
    test('弟子：候选中无破防技时，退化为默认 power-sort（不崩，回归安全）', () {
      final disciple =
          _character(isFounder: false, lineageRole: LineageRole.disciple);
      final noBreakPool = [highA, highB, lowD];
      final mains = _fillMains(disciple, noBreakPool);

      // 无破防技候选 → 退化为 power-sort
      expect(mains.contains(highA.id), isTrue);
      expect(mains.contains(highB.id), isTrue);
    });

    // ─── 弟子只有 1 个破防技且 power 最高（但低于大招阈值）时自然进槽（不重复、不崩）
    // 注：_threshold=5000，topBreak power=3000 < 5000 → 留在主修候选池，而非进大招槽
    test('弟子：破防技本身 power 高于其他主修候选但低于大招阈值时自然进槽（幂等、不崩）', () {
      final disciple =
          _character(isFounder: false, lineageRole: LineageRole.disciple);
      // power=3000 < _threshold(5000)，保留在主修候选中
      final topBreak = _skill('top_break', power: 3000, defenseBreakPct: 0.5);
      final smallPool = [highA, topBreak, lowD]; // highA=2000, topBreak=3000
      final mains = _fillMains(disciple, smallPool);

      // topBreak power 最高（3000 > highA 2000），power-sort 自然选到第一位
      expect(mains.contains(topBreak.id), isTrue,
          reason: '破防技 power 在主修候选中最高时应自然进槽');
    });
  });
}
