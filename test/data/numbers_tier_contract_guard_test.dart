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
    /// 命名奖励溢价(2026-09-18 B2 复核 5A E-A 拍板为规则):`isNamedReward: true`
    /// 的装备可越本阶上界、不得越下一阶上界(numbers.yaml `equipment.tiers` 段头
    /// 明文)。标记由 equipment.yaml 字段声明、守卫只读字段,不再硬编码 id 集;
    /// 首批三件为断魂庄三选一(commit 10297311d)。
    late final namedRewards = repo.equipmentDefs.values
        .where((d) => d.isNamedReward)
        .toList();

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

    test('未标记 isNamedReward 的每件装备基础数值落在本阶同槽位区间内', () {
      final failures = <String>[];
      var checked = 0;
      for (final def in repo.equipmentDefs.values) {
        if (def.isNamedReward) continue;
        checked++;
        final v = violations(def, rangeOf(def.tier, def.slot));
        if (v.isNotEmpty) failures.add('${def.id}: ${v.join('; ')}');
      }
      expect(checked, repo.equipmentDefs.length - namedRewards.length);
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('isNamedReward 装备确实越本阶上界、但不越下一阶上界', () {
      expect(namedRewards, isNotEmpty, reason: '生产至少有断魂庄三选一三件');
      for (final def in namedRewards) {
        final id = def.id;
        // 若某天它被拉回本阶区间,这条会红,提醒把 isNamedReward 标记摘掉。
        expect(
          violations(def, rangeOf(def.tier, def.slot)),
          isNotEmpty,
          reason: '$id 已回到本阶区间,应摘掉 isNamedReward',
        );
        expect(
          def.tier.index + 1,
          lessThan(EquipmentTier.values.length),
          reason: '$id 已是最高阶,没有「下一阶上界」可作包络,不得标 isNamedReward',
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
