import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_loadout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 职责软引导 autoFill 倾向测试（第六阶段 Task 6，第七阶段批三收窄）
//
// 集成层 — SkillLoadout.autoFill（真实生产入口，与 applyAutoFill 共用同一核心）
//    验证最终 loadout 按 lineage 倾向变化：
//      大弟子(senior)→破防技进槽，祖师→不强制，徒孙/junior/disciple→不变。
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
  // 集成层：SkillLoadout.autoFill 真实入口 —— lineage 倾向在最终 loadout 生效
  //
  // 候选池设计：
  //   high_A (power=2000, 无破防)  ← 默认 power-sort 会选这个进 m1
  //   high_B (power=1800, 无破防)  ← 默认 power-sort 会选这个进 m2
  //   defense_break (power=500, defenseBreakPct=0.3)  ← 默认 power-sort 不会选
  //   low_D (power=200, 无破防)
  //
  // 大弟子(senior)期望：defense_break 出现在最终 loadout 主修槽之一。
  // 祖师期望：high_A + high_B 进槽（power-sort default），defense_break 不进。
  // 徒孙/junior/disciple 期望：同祖师（power-sort default，回归）。
  // ══════════════════════════════════════════════════════════════════════════
  group('SkillLoadout.autoFill 集成：lineage 倾向对最终 loadout 生效', () {
    // 候选池（power-sort 默认选 highA/highB，不选 defBreak）
    final highA = _skill('high_a', power: 2000);
    final highB = _skill('high_b', power: 1800);
    final defBreak = _skill('def_break', power: 500, defenseBreakPct: 0.3);
    final lowD = _skill('low_d', power: 200);
    final pool = [highA, highB, defBreak, lowD];

    // ─── 大弟子(senior)：autoFill 后 loadout 包含破防技 ─────────────────────
    test('大弟子(senior)：最终 autoFill loadout 包含破防技（即使 power 排名不入前 2）', () {
      final senior =
          _character(isFounder: false, lineageRole: LineageRole.senior);
      final mains = _fillMains(senior, pool);

      // 破防技必须在最终主修槽中
      expect(mains.contains(defBreak.id), isTrue,
          reason: '大弟子(senior)身份 autoFill 后，破防技应出现在主修槽（无论 power 高低）');
    });

    test('大弟子(senior)：最终 loadout 总计 2 个主修槽被填（无空槽）', () {
      final senior =
          _character(isFounder: false, lineageRole: LineageRole.senior);
      final mains = _fillMains(senior, pool);
      expect(mains.length, 2,
          reason: '主修槽应被完整填满（pool 有 4 个候选，2 槽应全填）');
    });

    test('大弟子(senior)：另一个主修槽为高倍率技（不全换成破防）', () {
      final senior =
          _character(isFounder: false, lineageRole: LineageRole.senior);
      final mains = _fillMains(senior, pool);

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

    // ─── 大弟子已有破防技时不重复替换（现有槽保留） ─────────────────────────
    test('大弟子(senior)：若 existing 槽已有高 power 技，autoFill 不覆盖（软引导不覆盖玩家手动设置）', () {
      final senior =
          _character(isFounder: false, lineageRole: LineageRole.senior);
      // 玩家已手动设置 m1 = high_a
      const existingWithM1 = SkillLoadout(mainSkillId1: 'high_a');
      final result = SkillLoadout.autoFill(
        mainTechniqueSkills: pool,
        assistTechniqueSkills: const [],
        jointSkill: null,
        realmTier: senior.realmTier,
        existing: existingWithM1,
        ultimatePowerThreshold: _threshold,
        lineageRole: senior.lineageRole,
        isFounder: senior.isFounder,
      );

      // m1 不被覆盖（玩家保留）
      expect(result.mainSkillId1, highA.id,
          reason: '玩家手动设置的 m1 不应被 autoFill 覆盖');
      // m2 为空槽，大弟子倾向应将破防技注入 m2（部分填充 + 促进入剩余槽）
      expect(result.mainSkillId2, defBreak.id,
          reason: '大弟子(senior) m2 空槽时，autoFill 应将破防技注入 m2');
    });

    // ─── 候选无破防技时大弟子行为与默认一致（无破防技可注入时不崩） ──────────
    test('大弟子(senior)：候选中无破防技时，退化为默认 power-sort（不崩，回归安全）', () {
      final senior =
          _character(isFounder: false, lineageRole: LineageRole.senior);
      final noBreakPool = [highA, highB, lowD];
      final mains = _fillMains(senior, noBreakPool);

      // 无破防技候选 → 退化为 power-sort
      expect(mains.contains(highA.id), isTrue);
      expect(mains.contains(highB.id), isTrue);
    });

    // ─── 通用弟子(disciple)：第七阶段批三起不再获得破防倾向（行为变更锁定）──
    test('通用弟子(disciple)：不再获得破防倾向，行为同 power-sort default', () {
      final disciple =
          _character(isFounder: false, lineageRole: LineageRole.disciple);
      final mains = _fillMains(disciple, pool);

      // disciple 不获得破防倾向：high_a + high_b 进槽，defBreak 不进
      expect(mains.contains(highA.id), isTrue,
          reason: 'disciple 不获得破防倾向，high_a 应进槽');
      expect(mains.contains(highB.id), isTrue,
          reason: 'disciple 不获得破防倾向，high_b 应进槽');
      expect(mains.contains(defBreak.id), isFalse,
          reason: '第七阶段批三：破防倾向已收窄到 senior，disciple 不应再获得');
    });

    // ─── 大弟子只有 1 个破防技且 power 最高（但低于大招阈值）时自然进槽（不重复、不崩）
    // 注：_threshold=5000，topBreak power=3000 < 5000 → 留在主修候选池，而非进大招槽
    test('大弟子(senior)：破防技本身 power 高于其他主修候选但低于大招阈值时自然进槽（幂等、不崩）', () {
      final senior =
          _character(isFounder: false, lineageRole: LineageRole.senior);
      // power=3000 < _threshold(5000)，保留在主修候选中
      final topBreak = _skill('top_break', power: 3000, defenseBreakPct: 0.5);
      final smallPool = [highA, topBreak, lowD]; // highA=2000, topBreak=3000
      final mains = _fillMains(senior, smallPool);

      // topBreak power 最高（3000 > highA 2000），power-sort 自然选到第一位
      expect(mains.contains(topBreak.id), isTrue,
          reason: '破防技 power 在主修候选中最高时应自然进槽');
    });
  });
}
