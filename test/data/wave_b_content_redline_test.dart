import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// 波B 24 招内容批红线(写约束语义,不锚瞬时数字 ·
/// memory feedback_red_line_test_semantics)。
///
/// 设计 spec:docs/superpowers/specs/2026-06-11-wave-b-24-skills-content-design.md
/// - 真解=Boss 蓄力技双用 canon(「破他的招、学他的招」,沿青锋绝)。
/// - 每章末 Boss 关恰 1 本真解;塔 Boss 层全配残页。
/// - 流派配平:mainlineDrop / fragment / 破招 各流派等量(玩家侧 build 池 6/6/6)。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (p) => File(p).readAsString(),
      );
    }
  });

  test('章末 Boss 关:真解全配 + 蓄力技 = 掉落真解(双用 canon)', () {
    final repo = GameRepository.instance;
    final chapterEnds = repo.stageDefs.values.where((s) =>
        s.stageType == StageType.mainline &&
        s.isBossStage &&
        s.dropSkillManualId != null);
    // 每个有真解的章末关:Boss chargeSkillId == 掉落真解(双用)。
    expect(chapterEnds, isNotEmpty);
    final chapters = <int>{};
    for (final st in chapterEnds) {
      final boss = st.enemyTeam.firstWhere((e) => e.isBoss);
      expect(boss.chargeSkillId, st.dropSkillManualId,
          reason: '${st.id} 蓄力技应与掉落真解同招(波B 双用 canon)');
      expect(chapters.add(st.chapterIndex!), isTrue,
          reason: '每章至多 1 本真解');
    }
    // 全部主线章(按 chapterIndex 集合)都有真解(内容覆盖完备)。
    final allChapters = repo.stageDefs.values
        .where((s) => s.stageType == StageType.mainline)
        .map((s) => s.chapterIndex)
        .whereType<int>()
        .toSet();
    expect(chapters, allChapters,
        reason: '每个主线章都应有章末真解(波B 内容覆盖)');
  });

  test('塔 Boss 层(bossKind 非空)残页全配;普通层不配', () {
    final repo = GameRepository.instance;
    for (final f in repo.towerFloors) {
      if (f.bossKind != null) {
        expect(f.dropSkillFragmentId, isNotNull,
            reason: 'floor ${f.floorIndex} 是 Boss 层应配残页(波B 内容覆盖)');
      } else {
        expect(f.dropSkillFragmentId, isNull,
            reason: 'floor ${f.floorIndex} 普通层不应配残页');
      }
    }
  });

  test('流派配平:mainlineDrop / fragment / 破招 各流派等量', () {
    final repo = GameRepository.instance;
    Map<TechniqueSchool, int> countBy(bool Function(SkillDef) pred) {
      final m = <TechniqueSchool, int>{};
      for (final s in repo.skillDefs.values.where(pred)) {
        expect(s.style, isNotNull, reason: '${s.id} 应有 style');
        m[s.style!] = (m[s.style!] ?? 0) + 1;
      }
      return m;
    }

    void assertBalanced(String kind, Map<TechniqueSchool, int> m) {
      expect(m.keys.toSet(), TechniqueSchool.values.toSet(),
          reason: '$kind 应覆盖全部三流派');
      expect(m.values.toSet().length, 1,
          reason: '$kind 各流派数量应相等(配平),实际 $m');
    }

    assertBalanced(
        '真解', countBy((s) => s.source == SkillSource.mainlineDrop));
    assertBalanced(
        '残页', countBy((s) => s.source == SkillSource.fragment));
    assertBalanced('破招', countBy((s) => s.canInterrupt));
  });

  test('真解 cost ≤ 对应 Boss 内力预算(蓄力技至少放得出 1 次)', () {
    final repo = GameRepository.instance;
    final scale = repo.numbers.combat.enemyDefaults.internalForceScale;
    for (final st in repo.stageDefs.values) {
      for (final e in st.enemyTeam) {
        final cs = e.chargeSkillId;
        if (cs == null) continue;
        final skill = repo.skillDefs[cs]!;
        final realm = repo.getRealm(e.realmTier, e.realmLayer);
        final budget = realm.internalForceMax * scale;
        expect(skill.internalForceCost, lessThanOrEqualTo(budget),
            reason: '${st.id} ${e.name} 蓄力技 ${skill.id} cost '
                '${skill.internalForceCost} > 内力预算 $budget,机制死配置');
      }
    }
  });
}
