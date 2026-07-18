import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/defs/boss_gauntlet_config.dart';

import '../../support/test_data.dart';

/// C1.3.2 断魂庄三敌队 `EnemyDef` + 苏无咎「锁脉针」招（qi_drain 首个实例）。
///
/// 源规格：design §5.2-5.4（三关机制）/ §6.2（锁脉针法=三流阶阴柔）/ §8.2
/// （敌队进 `boss_gauntlets.yaml`、引用现有招式表）。数值占位 `TODO(batch3-probe)`，
/// 本批只验机制字段接线正确 + 引用校验，不验战斗胜负（属 C1.3.3 runner）。
void main() {
  setUpAll(() async {
    await loadTestGameRepository();
  });

  group('锁脉针招 skill_suo_mai_zhen（§5.2 苏无咎 charge / §6.2 首通奖励）', () {
    test('存在且携 qiDrainPct 0.30、阴柔 tier2、gauntlet 且已正式挂载', () {
      final skill = GameRepository.instance.skillDefs['skill_suo_mai_zhen'];
      expect(skill, isNotNull, reason: '锁脉针招须在 skills.yaml 定义');
      expect(skill!.qiDrainPct, 0.30, reason: '§5.2 未破招夺 30% 最大真气');
      expect(skill.style, TechniqueSchool.yinRou, reason: '§6.2 锁脉针法=阴柔招');
      expect(skill.tier, 2, reason: '§6.2 三流阶（tier2）');
      expect(
        skill.source,
        SkillSource.gauntlet,
        reason: '2026-07-19 来源语义转正:断魂庄首通奖励=gauntlet',
      );
      expect(skill.mountDeferred, isFalse, reason: 'C2.4 首通奖励挂载已落地,豁免标记已删=发布');
      expect(skill.type, SkillType.powerSkill);
      expect(
        skill.powerMultiplier,
        lessThanOrEqualTo(8000),
        reason: '§5.4 全局倍率红线',
      );
      expect(skill.spendsQi, isTrue, reason: 'powerSkill 须耗气（真气红线）');
    });
  });

  group('断魂庄三敌队解析（§5.2-5.4 机制走 EnemyDef 既有字段）', () {
    late BossGauntletConfig config;
    setUp(() {
      config = GameRepository.instance.bossGauntletConfig!;
    });

    test('每关 enemy_team_id 都能解析出敌队（引用不悬空 §8.2）', () {
      for (final stage in config.stages) {
        final team = config.enemiesForTeam(stage.enemyTeamId);
        expect(team, isNotEmpty, reason: '关次 ${stage.enemyTeamId} 敌队须非空');
      }
    });

    test('第一关 苏无咎：灵巧 + 锁脉针 charge + 破招脆弱窗外 0.65（§5.2）', () {
      final team = config.enemiesForTeam('gauntlet_su_wujiu');
      expect(team, hasLength(3), reason: '苏无咎 + 两名青衣护院');
      final leader = team.first;
      expect(leader.school, TechniqueSchool.lingQiao, reason: '苏无咎 灵巧暗器');
      expect(leader.isBoss, isTrue);
      expect(leader.chargeSkillId, 'skill_suo_mai_zhen', reason: '招牌蓄力技锁脉针');
      expect(
        leader.skillIds,
        contains('skill_suo_mai_zhen'),
        reason: 'chargeSkillId 须在 skillIds 内（破招红线①）',
      );
      expect(leader.vulnerability, isNotNull);
      expect(
        leader.vulnerability!.outOfWindowDamageMult,
        0.65,
        reason: '§5.2 破招后两拍窗口，窗外承伤 0.65',
      );
    });

    test('第二关 石镇岳：刚猛 + 铁衣护阵 0.25 + 双庄客护法（§5.3）', () {
      final team = config.enemiesForTeam('gauntlet_shi_zhenyue');
      expect(team, hasLength(3), reason: '石镇岳 + 两名执杖庄客');
      final leader = team.first;
      expect(leader.school, TechniqueSchool.gangMeng, reason: '石镇岳 刚猛护甲');
      expect(leader.isBoss, isTrue);
      expect(leader.guardianWard, isNotNull);
      expect(
        leader.guardianWard!.damageTakenMult,
        0.25,
        reason: '§5.3 庄客存活时护阵承伤 0.25',
      );
      final teamIds = team.map((e) => e.id).toSet();
      for (final gid in leader.guardianWard!.guardianIds) {
        expect(
          teamIds,
          contains(gid),
          reason: 'guardianId $gid 须为本队执杖庄客（护法墙 taunt）',
        );
      }
      expect(leader.guardianWard!.guardianIds, hasLength(2));
    });

    test('最终关 闻九针：阴柔单人 + 三阶段血线 + 逆行封脉脆弱 0.35（§5.4）', () {
      final team = config.enemiesForTeam('gauntlet_wen_jiuzhen');
      expect(team, hasLength(1), reason: '闻九针单人迎战');
      final boss = team.first;
      expect(boss.school, TechniqueSchool.yinRou, reason: '闻九针 阴柔');
      expect(boss.isBoss, isTrue);
      expect(boss.bossPhases, isNotNull);
      expect(
        boss.bossPhases!.map((p) => p.hpThresholdPct).toList(),
        [1.0, 0.70, 0.35],
        reason: '§5.4 集中 100-70 / 逆行封脉 70-35 / 断魂九针 <35',
      );
      expect(boss.vulnerability, isNotNull);
      expect(
        boss.vulnerability!.outOfWindowDamageMult,
        0.35,
        reason: '§5.4 逆行封脉窗外承伤 0.35',
      );
      // 逆行封脉/断魂九针 相位靠 chargeCounter 开脆弱窗口（同 floor30 体例）。
      expect(
        boss.bossPhases!.where(
          (p) => p.onEnterMechanic == BossPhaseMechanic.chargeCounter,
        ),
        isNotEmpty,
        reason: '脆弱窗口须有 chargeCounter 相位开窗途径（EnemyDef fromYaml 硬校）',
      );
    });
  });
}
