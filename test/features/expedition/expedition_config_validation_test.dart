import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_config.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_config.dart';

void main() {
  group('ExpeditionConfig.fromYaml', () {
    test('合法配置解析节点时长与恢复比例', () {
      final c = ExpeditionConfig.fromYaml(const {
        'normal_node_minutes': 90,
        'elite_node_minutes': 180,
        'hp_recover_pct_per_node': 0.10,
        'qi_recover_pct_per_node': 0.25,
        'zhangshi_pct_per_layer': 0.05,
      });
      expect(c.normalNodeMinutes, 90);
      expect(c.qiRecoverPctPerNode, 0.25);
    });
    test('节点时长非正 → StateError', () {
      expect(
        () => ExpeditionConfig.fromYaml(const {'normal_node_minutes': 0}),
        throwsStateError,
      );
    });
    test('恢复比例越界 → StateError', () {
      expect(
        () => ExpeditionConfig.fromYaml(const {
          'normal_node_minutes': 90,
          'elite_node_minutes': 180,
          'hp_recover_pct_per_node': 1.5,
        }),
        throwsStateError,
      );
    });
    test('解析 base_exp_per_battle（缺省默认 170·batch3 探针拍板中档）', () {
      final c = ExpeditionConfig.fromYaml(const {
        'normal_node_minutes': 90,
        'elite_node_minutes': 180,
        'base_exp_per_battle': 250,
      });
      expect(c.baseExpPerBattle, 250);
      final d = ExpeditionConfig.fromYaml(const {
        'normal_node_minutes': 90,
        'elite_node_minutes': 180,
      });
      expect(d.baseExpPerBattle, 170);
    });
    test('base_exp_per_battle 非正 → StateError', () {
      expect(
        () => ExpeditionConfig.fromYaml(const {
          'normal_node_minutes': 90,
          'elite_node_minutes': 180,
          'base_exp_per_battle': 0,
        }),
        throwsStateError,
      );
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
