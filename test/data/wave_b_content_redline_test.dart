import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../support/test_data.dart';

/// 波B 24 招内容批红线(写约束语义,不锚瞬时数字 ·
/// memory feedback_red_line_test_semantics)。
///
/// 设计 spec:docs/superpowers/specs/2026-06-11-wave-b-24-skills-content-design.md
/// - 真解=Boss 蓄力技双用 canon(「破他的招、学他的招」,沿青锋绝)。
/// - 当前发布上限内的真解/残页必须挂载;高阶招式定义保留给未来内容。
/// - 流派配平:mainlineDrop / fragment / 破招 各流派等量(玩家侧 build 池 6/6/6)。
void main() {
  setUpAll(loadTestGameRepository);

  test('章末 Boss 关:真解全配 + 蓄力技 = 掉落真解(双用 canon)', () {
    final repo = GameRepository.instance;
    final chapterEnds = repo.stageDefs.values.where(
      (s) =>
          s.stageType == StageType.mainline &&
          s.isBossStage &&
          s.dropSkillManualId != null,
    );
    // 每个有真解的章末关:Boss chargeSkillId == 掉落真解(双用)。
    expect(chapterEnds, isNotEmpty);
    final chapters = <int>{};
    for (final st in chapterEnds) {
      final boss = st.enemyTeam.firstWhere((e) => e.isBoss);
      expect(
        boss.chargeSkillId,
        st.dropSkillManualId,
        reason: '${st.id} 蓄力技应与掉落真解同招(波B 双用 canon)',
      );
      expect(chapters.add(st.chapterIndex!), isTrue, reason: '每章至多 1 本真解');
    }
    final releaseTier = _releaseCapTier(repo);
    // mountDeferred 招豁免挂载完备性(发布阶内但正式挂载点留 batch3/Phase C)。
    final releaseManualSkills = repo.skillDefs.values
        .where(
          (s) =>
              s.source == SkillSource.mainlineDrop &&
              !s.mountDeferred &&
              s.canEquipAtRealm(releaseTier),
        )
        .map((s) => s.id)
        .toSet();
    expect(
      chapterEnds.map((s) => s.dropSkillManualId).toSet(),
      releaseManualSkills,
      reason: '当前发布上限内的真解应全部挂载，高阶真解留给未来内容',
    );
  });

  test('塔残页只投放当前发布上限内招式;普通层不配', () {
    final repo = GameRepository.instance;
    final releaseTier = _releaseCapTier(repo);
    final mountedFragments = <String>{};
    for (final f in repo.towerFloors) {
      final fragmentId = f.dropSkillFragmentId;
      if (fragmentId != null) {
        expect(f.bossKind, isNotNull, reason: '残页只能挂在 Boss 层');
        expect(
          repo.skillDefs[fragmentId]!.canEquipAtRealm(releaseTier),
          isTrue,
          reason: 'floor ${f.floorIndex} 不应提前投放高阶残页',
        );
        expect(mountedFragments.add(fragmentId), isTrue, reason: '残页不可重复挂载');
      } else if (f.bossKind == null) {
        expect(fragmentId, isNull, reason: 'floor ${f.floorIndex} 普通层不应配残页');
      }
    }
    final releaseFragments = repo.skillDefs.values
        .where(
          (s) =>
              s.source == SkillSource.fragment &&
              !s.mountDeferred &&
              s.canEquipAtRealm(releaseTier),
        )
        .map((s) => s.id)
        .toSet();
    expect(
      mountedFragments,
      releaseFragments,
      reason: '当前发布上限内的塔残页应全部挂载，高阶残页留给未来内容',
    );
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
      expect(
        m.keys.toSet(),
        TechniqueSchool.values.toSet(),
        reason: '$kind 应覆盖全部三流派',
      );
      expect(m.values.toSet().length, 1, reason: '$kind 各流派数量应相等(配平),实际 $m');
    }

    // 断魂庄等副本奖励招（锁脉针法）属独立奖励流，不并入 wave_b 主线章末 build 配平池
    // （design §6.2 首通仅一枚阴柔奖励招，非配平三件套）。以 gauntlet 敌队 skillIds 界定
    // 排除，排除后主线 6 真解仍守 2/2/2 配平不变式。
    final gauntletConfig = repo.bossGauntletConfig;
    final gauntletSkillIds = <String>{
      if (gauntletConfig != null)
        for (final team in gauntletConfig.enemyTeams.values)
          for (final e in team) ...e.skillIds,
    };

    assertBalanced(
      '真解',
      countBy(
        (s) =>
            s.source == SkillSource.mainlineDrop &&
            !gauntletSkillIds.contains(s.id),
      ),
    );
    assertBalanced('残页', countBy((s) => s.source == SkillSource.fragment));
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
        expect(
          skill.internalForceCost,
          lessThanOrEqualTo(budget),
          reason:
              '${st.id} ${e.name} 蓄力技 ${skill.id} cost '
              '${skill.internalForceCost} > 内力预算 $budget,机制死配置',
        );
      }
    }
  });
}

RealmTier _releaseCapTier(GameRepository repo) {
  final absoluteLevel =
      repo.numbers.progressionReleaseCap.maxAbsoluteRealmLevel;
  return RealmTier.values[(absoluteLevel - 1) ~/ RealmLayer.values.length];
}
