import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_config.dart';

/// C2.4a：断魂庄奖励配置解析（首通秘籍 + Boss 胜利三选一命名装备候选·§6.2）。
void main() {
  Map<String, dynamic> baseYaml() => {
    'supply_cap': 3,
    'stages': [
      {'role': 'elite', 'enemy_team_id': 't1'},
      {'role': 'elite', 'enemy_team_id': 't2'},
      {'role': 'boss', 'enemy_team_id': 't3'},
    ],
    'first_clear_reward_skill_id': 'skill_suo_mai_zhen',
    'reward_candidate_equipment_ids': ['eq1', 'eq2', 'eq3'],
  };

  test('解析首通秘籍 id + 三件奖励候选', () {
    final c = BossGauntletConfig.fromYaml(baseYaml());
    expect(c.firstClearRewardSkillId, 'skill_suo_mai_zhen');
    expect(c.rewardCandidateEquipmentIds, ['eq1', 'eq2', 'eq3']);
  });

  test('奖励候选非 3 件 → 抛错（三选一）', () {
    final y = baseYaml()..['reward_candidate_equipment_ids'] = ['eq1', 'eq2'];
    expect(() => BossGauntletConfig.fromYaml(y), throwsStateError);
  });

  test('首通秘籍 id 为空 → 抛错', () {
    final y = baseYaml()..['first_clear_reward_skill_id'] = '';
    expect(() => BossGauntletConfig.fromYaml(y), throwsStateError);
  });

  test('奖励候选含空 id → 抛错', () {
    final y = baseYaml()
      ..['reward_candidate_equipment_ids'] = ['eq1', '', 'eq3'];
    expect(() => BossGauntletConfig.fromYaml(y), throwsStateError);
  });

  test('解析每精英经验（elite_reward_exp·§6.3 失败结算据此发已击败精英经验）', () {
    final c = BossGauntletConfig.fromYaml(
      baseYaml()..['elite_reward_exp'] = 50,
    );
    expect(c.eliteRewardExp, 50);
  });

  test('elite_reward_exp 缺省为 0（可加性占位·mirror first_clear_reward_exp）', () {
    final c = BossGauntletConfig.fromYaml(baseYaml());
    expect(c.eliteRewardExp, 0);
  });
}
