import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/cultivation/application/skill_loadout_resolver.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 职责软引导 autoFill 倾向测试（第六阶段 Task 6）
//
// 测试层：纯函数 SkillLoadoutResolver.applyLineageTendency。
// 不依赖 Isar（不需要真实数据库），仅验证排序语义。
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

void main() {
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
}
