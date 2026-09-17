import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/shared/battle_shared/enum_localizations.dart';

import '../support/test_data.dart';

/// B2 复核 4A(2026-09-17):把「保留(有合同)」的 numbers.yaml 区段合同变成守卫。
///
/// - `equipment.tiers[*].{weapon,armor,accessory}.*_min/_max`:`data/equipment.yaml:7`
///   明文「数值范围严格对齐 numbers.yaml equipment.tiers 段」,此前零消费。
/// - `equipment.tiers[*].tier_name` / `techniques.tiers[*].tier_name`:
///   七阶显示名与 `EnumL10n` 集中层同源(CLAUDE.md §5.2)。
///
/// 守约束语义不守瞬时数字:区间与 def 都从生产 yaml 读,改任一侧失配即红。
void main() {
  late GameRepository repo;
  late Map<String, Map<String, dynamic>> equipmentTiers;
  late List<Map<String, dynamic>> techniqueTiers;

  setUpAll(() async {
    repo = await loadTestGameRepository();
    equipmentTiers = {
      for (final raw in loadTestNumbersSection(['equipment'])['tiers'] as List)
        (raw as Map)['tier'] as String: Map<String, dynamic>.from(raw),
    };
    techniqueTiers = [
      for (final raw in loadTestNumbersSection(['techniques'])['tiers'] as List)
        Map<String, dynamic>.from(raw as Map),
    ];
  });

  group('equipment.tiers 区间合同', () {
    /// 断魂庄三选一命名奖励(commit 10297311d,2026-07-19):有意越过 haoJiaHuo
    /// 上界作为「命名奖励溢价」(武器 attack 360–490 跨在 450 与利器下界 480
    /// 之间,不落在任一单阶区间内)。是否收回/抬阶属 🔴 待拍板(见
    /// docs/audit/numbers_unused_keys_pending_decision_2026-09-17.md);守卫在此
    /// 只钉包络「下界 ≥ 本阶 min、上界 ≤ 下一阶 max」,防溢价无声膨胀。
    const namedRewardAllowlist = <String>{
      'weapon_haojiahuo_suo_mai_nang',
      'armor_haojiahuo_zhen_yue_tie_yi',
      'accessory_haojiahuo_she_hun_ling',
    };

    Map<String, dynamic> rangeOf(EquipmentTier tier, EquipmentSlot slot) =>
        Map<String, dynamic>.from(equipmentTiers[tier.name]![slot.name] as Map);

    /// [floor] 提供下界、[ceiling] 提供上界;同一区间时即「落在本阶区间内」。
    List<String> violations(
      EquipmentDef def,
      Map<String, dynamic> floor, {
      Map<String, dynamic>? ceiling,
    }) {
      final out = <String>[];
      void check(String label, int min, int max, String lo, String hi) {
        final rLo = floor[lo] as int;
        final rHi = (ceiling ?? floor)[hi] as int;
        if (!(rLo <= min && min <= max && max <= rHi)) {
          out.add('$label [$min,$max] ∉ [$rLo,$rHi]');
        }
      }

      check(
        'attack',
        def.baseAttackMin,
        def.baseAttackMax,
        'attack_min',
        'attack_max',
      );
      check('hp', def.baseHealthMin, def.baseHealthMax, 'hp_min', 'hp_max');
      check(
        'speed',
        def.baseSpeedMin,
        def.baseSpeedMax,
        'speed_min',
        'speed_max',
      );
      return out;
    }

    test('七阶 × 三槽位区间齐全且 min ≤ max', () {
      expect(equipmentTiers.keys, EquipmentTier.values.map((t) => t.name));
      for (final tier in EquipmentTier.values) {
        for (final slot in EquipmentSlot.values) {
          final r = rangeOf(tier, slot);
          for (final k in ['attack', 'hp', 'speed']) {
            expect(
              r['${k}_min'] as int,
              lessThanOrEqualTo(r['${k}_max'] as int),
              reason: '${tier.name}.${slot.name}.$k',
            );
          }
        }
      }
    });

    test('白名单外的每件装备基础数值落在本阶同槽位区间内', () {
      final failures = <String>[];
      var checked = 0;
      for (final def in repo.equipmentDefs.values) {
        if (namedRewardAllowlist.contains(def.id)) continue;
        checked++;
        final v = violations(def, rangeOf(def.tier, def.slot));
        if (v.isNotEmpty) failures.add('${def.id}: ${v.join('; ')}');
      }
      expect(checked, repo.equipmentDefs.length - namedRewardAllowlist.length);
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('白名单三件命名奖励确实越本阶上界、但不越下一阶(liQi)上界', () {
      for (final id in namedRewardAllowlist) {
        final def = repo.equipmentDefs[id];
        expect(def, isNotNull, reason: '$id 不在 equipment.yaml,白名单应同步收缩');
        expect(def!.tier, EquipmentTier.haoJiaHuo, reason: id);
        // 若某天它被拉回本阶区间,这条会红,提醒把 id 移出白名单。
        expect(
          violations(def, rangeOf(def.tier, def.slot)),
          isNotEmpty,
          reason: '$id 已回到本阶区间,白名单应收缩',
        );
        final next = EquipmentTier.values[def.tier.index + 1];
        expect(
          violations(
            def,
            rangeOf(def.tier, def.slot),
            ceiling: rangeOf(next, def.slot),
          ),
          isEmpty,
          reason: '$id 越出包络 [本阶 min, 下一阶 ${next.name} max]',
        );
      }
    });
  });

  group('tier_name 与 EnumL10n 七阶显示名同源', () {
    test('equipment.tiers[*].tier_name', () {
      for (final tier in EquipmentTier.values) {
        expect(
          equipmentTiers[tier.name]!['tier_name'],
          EnumL10n.equipmentTier(tier),
          reason: tier.name,
        );
      }
    });

    test('techniques.tiers[*].tier_name', () {
      expect(
        techniqueTiers.map((t) => t['tier'] as String),
        TechniqueTier.values.map((t) => t.name),
      );
      for (final (i, tier) in TechniqueTier.values.indexed) {
        expect(
          techniqueTiers[i]['tier_name'],
          EnumL10n.techniqueTier(tier),
          reason: tier.name,
        );
      }
    });
  });
}
