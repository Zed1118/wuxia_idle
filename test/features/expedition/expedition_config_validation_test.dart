import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/expedition_config.dart';
import 'package:wuxia_idle/data/defs/boss_gauntlet_config.dart';

Map<String, dynamic> _validExpeditionYaml() => {
  'normal_node_minutes': 90,
  'elite_node_minutes': 180,
  'hp_recover_pct_per_node': 0.10,
  'qi_recover_pct_per_node': 0.25,
  'zhangshi_pct_per_layer': 0.05,
  'combat': {
    'depth_curve': {
      'first_node': 1,
      'base_multiplier': 1.0,
      'hp_growth_per_node': 0.05,
      'attack_growth_per_node': 0.02,
      'hp_multiplier_cap': 3.0,
      'attack_multiplier_cap': 2.0,
      'hp_value_cap': 60000,
      'attack_value_cap': 2000,
    },
    'normal_enemy_teams': [
      {
        'id': 'normal_a',
        'enemies': [
          {
            'id': 'enemy_a',
            'name': '敌甲',
            'realmTier': 'sanLiu',
            'realmLayer': 'shuLian',
            'school': 'gangMeng',
            'baseHp': 3000,
            'baseAttack': 300,
            'baseSpeed': 100,
            'skillIds': ['skill_gangmeng_jichu_basic'],
            'iconPath': '',
          },
        ],
      },
    ],
    'elite_enemy_teams': [
      {
        'id': 'elite_a',
        'enemies': [
          {
            'id': 'enemy_elite_a',
            'name': '敌乙',
            'realmTier': 'sanLiu',
            'realmLayer': 'jingTong',
            'school': 'lingQiao',
            'baseHp': 5000,
            'baseAttack': 450,
            'baseSpeed': 120,
            'skillIds': ['skill_lingqiao_jichu_basic'],
            'iconPath': '',
          },
        ],
      },
    ],
  },
};

void main() {
  group('ExpeditionConfig.fromYaml', () {
    test('合法配置解析节点时长与恢复比例', () {
      final c = ExpeditionConfig.fromYaml(_validExpeditionYaml());
      expect(c.normalNodeMinutes, 90);
      expect(c.qiRecoverPctPerNode, 0.25);
      expect(c.normalEnemyTeams, hasLength(1));
      expect(c.eliteEnemyTeams, hasLength(1));
    });
    test('节点时长非正 → StateError', () {
      expect(
        () => ExpeditionConfig.fromYaml(
          _validExpeditionYaml()..['normal_node_minutes'] = 0,
        ),
        throwsStateError,
      );
    });
    test('恢复比例越界 → StateError', () {
      expect(
        () => ExpeditionConfig.fromYaml(
          _validExpeditionYaml()..['hp_recover_pct_per_node'] = 1.5,
        ),
        throwsStateError,
      );
    });
    test('解析 base_exp_per_battle（缺省默认 170·batch3 探针拍板中档）', () {
      final c = ExpeditionConfig.fromYaml(
        _validExpeditionYaml()..['base_exp_per_battle'] = 250,
      );
      expect(c.baseExpPerBattle, 250);
      final d = ExpeditionConfig.fromYaml(_validExpeditionYaml());
      expect(d.baseExpPerBattle, 170);
    });
    test('base_exp_per_battle 非正 → StateError', () {
      expect(
        () => ExpeditionConfig.fromYaml(
          _validExpeditionYaml()..['base_exp_per_battle'] = 0,
        ),
        throwsStateError,
      );
    });

    test('敌池缺失或深度曲线非法 → StateError', () {
      final missingPool = _validExpeditionYaml();
      (missingPool['combat'] as Map)['normal_enemy_teams'] = const <Object>[];
      expect(() => ExpeditionConfig.fromYaml(missingPool), throwsStateError);

      final badCurve = _validExpeditionYaml();
      ((badCurve['combat'] as Map)['depth_curve'] as Map)['hp_multiplier_cap'] =
          0.5;
      expect(() => ExpeditionConfig.fromYaml(badCurve), throwsStateError);
    });

    test('同 seed 选队确定且深度增长受 YAML cap 约束', () {
      final c = ExpeditionConfig.fromYaml(_validExpeditionYaml());
      final shallow = c.enemiesForNode(nodeIndex: 1, nodeSeed: 7, elite: false);
      final repeat = c.enemiesForNode(nodeIndex: 1, nodeSeed: 7, elite: false);
      final deep = c.enemiesForNode(nodeIndex: 1000, nodeSeed: 7, elite: false);

      expect(repeat.single.id, shallow.single.id);
      expect(repeat.single.baseHp, shallow.single.baseHp);
      expect(deep.single.baseHp, 9000, reason: '3000 × hp cap 3.0');
      expect(deep.single.baseAttack, 600, reason: '300 × attack cap 2.0');
    });
  });

  group('BossGauntletConfig.fromYaml', () {
    Map<String, dynamic> base() => {
      'supply_cap': 3,
      'stages': [
        {'role': 'elite', 'enemy_team_id': 'gauntlet_su_wujiu'},
        {'role': 'elite', 'enemy_team_id': 'gauntlet_shi_zhenyue'},
        {'role': 'boss', 'enemy_team_id': 'gauntlet_wen_jiuzhen'},
      ],
      'first_clear_reward_skill_id': 'skill_suo_mai_zhen',
      'reward_candidate_equipment_ids': ['eq1', 'eq2', 'eq3'],
    };
    test('恰好两精英+一 Boss 且补给上限 3 合法', () {
      final c = BossGauntletConfig.fromYaml(base());
      expect(c.stages.length, 3);
      expect(c.supplyCap, 3);
    });
    test('关次角色非 2精英+1Boss → StateError', () {
      final bad = base()
        ..['stages'] = [
          {'role': 'elite', 'enemy_team_id': 'a'},
          {'role': 'boss', 'enemy_team_id': 'b'},
        ];
      expect(() => BossGauntletConfig.fromYaml(bad), throwsStateError);
    });
    test('补给上限 ≠ 3 → StateError', () {
      final bad = base()..['supply_cap'] = 5;
      expect(() => BossGauntletConfig.fromYaml(bad), throwsStateError);
    });
  });
}
