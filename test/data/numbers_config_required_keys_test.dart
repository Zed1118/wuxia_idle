import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';
import 'package:yaml/yaml.dart';

Map<String, dynamic> _productionNumbers() =>
    deepConvertYaml(loadYaml(File('data/numbers.yaml').readAsStringSync()))
        as Map<String, dynamic>;

// 数组路径逐项验证，防止只覆盖首项而遗漏局部缺键。
const _requiredNonRedLinePaths = <String>[
  'realms.level_diff_modifier.diff_3_or_more.attacker',
  'character.adventure_attribute_bonus.lifetime_cap_per_character',
  'character.attributes.point_per_attribute_min',
  'character.attributes.point_per_attribute_max',
  'character.attributes.total_points_min',
  'character.attributes.total_points_max',
  'skill_loadout.ultimate_power_threshold',
  'equipment.resonance.stages[].unlocks_joint_skill',
  'equipment.resonance.stages[].has_sword_song_effect',
  'inheritance.founder_ancestor_buff.enabled_when_alive',
  'inheritance.founder_ancestor_buff.sect_wide_buff.internal_force_max_pct',
  'inheritance.founder_ancestor_buff.sect_wide_buff.max_hp_pct',
  'inheritance.founder_ancestor_buff.sect_wide_buff.crit_rate_bonus',
  'inheritance.founder_ancestor_buff.sect_wide_buff.cultivation_progress_pct',
  'inheritance.founder_ancestor_buff.sect_wide_buff.apply_to_disciples_only',
  'inheritance.heritage_items.pieces_per_generation_min',
  'inheritance.heritage_items.pieces_per_generation_max',
  'inheritance.heritage_items.stack_across_generations',
  'inheritance.unlock_rules.can_take_disciple_at',
  'equipment.enhancement.never_degrade',
  'equipment.forging.slots[].fucai_cost',
  'combat.qi.base_max',
  'combat.qi.opening_qi',
  'combat.qi.enemy_opening_qi',
  'combat.qi.boss_opening_bonus',
  'combat.qi.tower_boss_opening_bonus',
  'combat.qi.opening_cap',
  'combat.qi.min_max',
  'combat.qi.max_cap',
  'combat.qi.school_bonus',
  'combat.qi.chain_recovery_pct',
  'combat.qi.gain_multiplier_cap',
  'combat.qi.cost_reduction_cap',
  'combat.qi.delta_abs_cap',
  'conditions.inner_breath_disorder.max_hours',
  'conditions.inner_breath_disorder.max_inner_force_penalty_pct',
  'conditions.inner_breath_disorder.max_opening_qi_penalty',
  'conditions.inner_breath_disorder.battle_recovery_hours',
  'conditions.inner_breath_disorder.dispel_hours',
  'conditions.inner_breath_disorder.boss_defeat_hours',
  'conditions.inner_breath_disorder.inner_demon_hours',
  'combat.readable_first_clear.enemy_hp_multiplier',
  'combat.readable_first_clear.enemy_attack_multiplier',
  'combat.readable_first_clear.opening_auto_skill_cooldown_turns',
  'combat.readable_first_clear.auto_skill_power_multiplier',
  'combat.boss_charge.default_charge_ticks',
  'combat.boss_charge.default_stagger_ticks',
  'combat.boss_charge.stagger_defense_down',
  'combat.boss_charge.interrupt_power_cap',
  'combat.defense_break.window_ticks',
  'combat.weakness.min_mult',
  'combat.weakness.max_mult',
  'animation.hit_tier.caption_peak_size',
  'animation.hit_tier.caption_glow_blur',
  'animation.hit_tier.closeup_scale',
  'animation.hit_tier.closeup_pulse_ms',
  'combat.max_hp_formula.realm_level_factor',
  'animation.readable_action_interval_ms',
  'animation.readable_victory_min_ms',
  'animation.victory_handoff_delay_ms',
  'animation.projectile_ms',
  'animation.battle_effect_ms',
  'animation.hit_flash_ms',
  'animation.key_moment_hold_ms',
  'animation.first_clear_opening_hold_ms',
  'animation.first_clear_first_skill_hold_ms',
  'animation.first_clear_boss_charge_hold_ms',
  'animation.sweep_inter_battle_gap_ms',
  'jianghu.enmity_combat_modifier.threshold',
  'jianghu.enmity_combat_modifier.player_attack_power_mult',
  'jianghu.enmity_combat_modifier.enemy_attack_power_mult',
  'jianghu.enmity_combat_modifier.severe_threshold',
  'jianghu.enmity_combat_modifier.severe_mult',
  'jianghu.enmity_combat_modifier.clamp_max',
  'jianghu.triggers.stage_boss_kill_delta',
  'jianghu.triggers.stage_boss_kill_rival_delta',
  'jianghu.triggers.encounter_npc_delta_min',
  'jianghu.triggers.encounter_npc_delta_max',
  'sect_event.active_events_max',
  'sect_event.tournament.trigger_probability',
  'sect_event.tournament.cooldown_days',
  'sect_event.tournament.expire_days',
  'sect_event.reputation.initial',
  'sect_event.reputation.win_delta',
  'sect_event.reputation.loss_delta',
  'sect_event.reputation.decay_per_month_idle',
  'sect_event.reputation.max',
  'sect_event.reputation.min',
  'sect_event.sect_level.max',
  'sect_event.sect_level.initial',
  'sect_event.sect_level.promote_wins_threshold',
  'sect_management.rank_promote_threshold.inner_min_contribution',
  'sect_management.rank_promote_threshold.elder_min_contribution',
  'sect_management.recruit.encounter_base_prob',
  'sect_management.recruit.stage_boss_recruit_prob',
  'sect_management.recruit.stage_boss_fail_recover_prob',
  'sect_management.recruit.mission_recruit_prob',
  'sect_management.territory.demo_initial_count',
  'skill_unlock.fragment_threshold',
  'skill_unlock.tower_fragment_drop_prob',
];

List<Map<String, dynamic>> _containingMaps(
  Map<String, dynamic> root,
  String path,
) {
  var maps = <Map<String, dynamic>>[root];
  for (final segment in path.split('.')..removeLast()) {
    if (segment.endsWith('[]')) {
      final key = segment.substring(0, segment.length - 2);
      maps = [
        for (final map in maps)
          for (final entry in map[key] as List) entry as Map<String, dynamic>,
      ];
    } else {
      maps = [for (final map in maps) map[segment] as Map<String, dynamic>];
    }
  }
  return maps;
}

List<Map<String, dynamic>> _productionStages() =>
    ((deepConvertYaml(loadYaml(File('data/stages.yaml').readAsStringSync()))
                as Map<String, dynamic>)['stages']
            as List)
        .cast<Map<String, dynamic>>();

void main() {
  final production = _productionNumbers();
  final redLines = (production['combat'] as Map)['red_lines'] as Map;

  test('生产数值配置无需任何红线兜底即可完整加载', () {
    expect(() => NumbersConfig.fromYaml(_productionNumbers()), returnsNormally);
  });

  test(
    'realms.level_diff_modifier.diff_3_or_more.attacker 为 null 时拒绝加载并报告路径',
    () {
      const path = 'realms.level_diff_modifier.diff_3_or_more.attacker';
      final copy = _productionNumbers();
      _containingMaps(copy, path).single['attacker'] = null;
      expect(
        () => NumbersConfig.fromYaml(copy),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            '空值路径',
            contains(path),
          ),
        ),
      );
    },
  );

  for (final key in redLines.keys.cast<String>()) {
    test('缺少 combat.red_lines.$key 时拒绝加载并报告路径', () {
      final copy = _productionNumbers();
      ((copy['combat'] as Map)['red_lines'] as Map).remove(key);
      expect(
        () => NumbersConfig.fromYaml(copy),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            '缺项路径',
            contains('combat.red_lines.$key'),
          ),
        ),
      );
    });
  }
  for (final path in _requiredNonRedLinePaths) {
    final count = _containingMaps(production, path).length;
    for (var index = 0; index < count; index++) {
      test('缺少 $path 第 ${index + 1} 项时拒绝加载并报告路径', () {
        final copy = _productionNumbers();
        _containingMaps(copy, path)[index].remove(path.split('.').last);
        expect(
          () => NumbersConfig.fromYaml(copy),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.toString(),
              '缺项路径',
              contains(path),
            ),
          ),
        );
      });
    }
  }

  test('生产关卡显式配置关卡首领开关后可完整加载', () {
    for (final stage in _productionStages()) {
      expect(() => StageDef.fromYaml(stage), returnsNormally);
    }
  });

  for (final stageId in ['stage_01_01', 'stage_01_05']) {
    test('关卡 $stageId 缺少 isBossStage 时拒绝加载并报告路径', () {
      final copy = _productionStages().singleWhere(
        (stage) => stage['id'] == stageId,
      )..remove('isBossStage');
      expect(
        () => StageDef.fromYaml(copy),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            '缺项路径',
            contains('stages.$stageId.isBossStage'),
          ),
        ),
      );
    });
  }
}
