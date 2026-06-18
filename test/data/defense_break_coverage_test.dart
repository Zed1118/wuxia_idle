import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 第六阶段 Task 7:三流派 破防技 覆盖红线。
///
/// 断言:刚猛 / 灵巧 / 阴柔 各至少有 1 个玩家可装配的技能
/// 配置了 defenseBreakPct > 0（开窗手），确保每种 build 都有开窗能力。
///
/// "玩家可装配"定义:
///   source ∈ {technique, encounter, mainlineDrop, fragment}（排除 special 系统招）
///   + 流派归属为对应 school（通过 style 显式字段，或通过 parentTechniqueDefId 所属心法推断）。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (p) => File(p).readAsString(),
      );
    }
  });

  test('三流派各有至少一个玩家可装配的破防技(defenseBreakPct>0)', () {
    final repo = GameRepository.instance;

    // 推断招式所属流派：
    // 1. 若 s.style 非空（drop/encounter/特殊招显式设置），直接用。
    // 2. 若 source==technique + parentTechniqueDefId 非空，从父心法 school 推断。
    TechniqueSchool? schoolOf(SkillDef s) {
      if (s.style != null) return s.style;
      if (s.source == SkillSource.technique && s.parentTechniqueDefId != null) {
        return repo.techniqueDefs[s.parentTechniqueDefId]?.school;
      }
      return null;
    }

    // source==null 仅出现于直接构造的测试 fixture，GameRepository yaml 加载路径
    // 的 skill 均为 fail-fast 强校验非空；此守卫排除测试 fixture 不影响真实数据。
    bool isPlayerEquipable(SkillDef s) =>
        s.source != null && s.source != SkillSource.special;

    for (final school in TechniqueSchool.values) {
      final breakSkills = repo.skillDefs.values.where(
        (s) =>
            isPlayerEquipable(s) &&
            schoolOf(s) == school &&
            s.defenseBreakPct > 0,
      );
      expect(
        breakSkills,
        isNotEmpty,
        reason:
            '流派 ${school.name} 没有玩家可装配的破防技，无法组成开窗手 build（第六阶段红线）',
      );
    }
  });
}
