import 'dart:math' as math;

import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/defs/drop_entry.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/utils/rng.dart';
import '../../equipment/application/equipment_factory.dart';
import '../domain/retreat_session.dart';
import '../domain/seclusion_map_def.dart';

typedef RetreatTimeSplit = ({double retreatHours, double passiveHours});

abstract final class RetreatSettlementCalculator {
  static RetreatTimeSplit splitHours({
    required double elapsedHours,
    required double fullRateHours,
  }) {
    final safeElapsed = math.max(0.0, elapsedHours);
    final safeFullRate = math.max(0.0, fullRateHours);
    final retreatHours = math.min(safeElapsed, safeFullRate);
    return (
      retreatHours: retreatHours,
      passiveHours: safeElapsed - retreatHours,
    );
  }

  static int equipmentRollCount({
    required double retreatHours,
    required int intervalHours,
    required int maxCount,
  }) {
    if (retreatHours <= 0 || intervalHours <= 0 || maxCount <= 0) return 0;
    return math.min((retreatHours / intervalHours).floor(), maxCount);
  }

  /// 使用 32-bit FNV-1a 生成跨进程稳定种子，避免重启刷装备。
  static int stableRetreatSeed(Iterable<int> values) {
    var hash = 0x811c9dc5;
    for (final value in values) {
      for (var shift = 0; shift < 64; shift += 8) {
        hash ^= (value >> shift) & 0xff;
        hash = (hash * 0x01000193) & 0x7fffffff;
      }
    }
    return hash;
  }

  static EquipmentTier selectEquipmentTier({
    required EquipmentTier anchorTier,
    required RetreatEquipmentTierWeights weights,
    required double roll,
  }) {
    final safeRoll = roll.clamp(0.0, 1.0 - double.minPositive);
    var cumulative = 0.0;
    for (var offset = 0; offset < weights.values.length; offset++) {
      cumulative += weights.values[offset];
      if (safeRoll < cumulative || offset == weights.values.length - 1) {
        final index = math.min(
          anchorTier.index + offset,
          EquipmentTier.values.length - 1,
        );
        return EquipmentTier.values[index];
      }
    }
    return EquipmentTier.shenWu;
  }

  /// 计算某个 12 小时节点的装备结果。null 表示本次未命中。
  static Equipment? rollEquipmentAtNode({
    required RetreatSession session,
    required int nodeIndex,
    required SeclusionMapDef map,
    required RetreatConfig config,
    required List<EquipmentDef> equipmentDefs,
    required DateTime obtainedAt,
    required String obtainedFrom,
  }) {
    if (nodeIndex < 1 || nodeIndex > config.equipmentRollMaxCount) return null;
    final realm = session.realmTierAtStart;
    if (realm == null) return null;

    final rng = DefaultRng(
      seed: stableRetreatSeed([
        session.saveDataId,
        session.id,
        session.startedAt.microsecondsSinceEpoch,
        nodeIndex,
      ]),
    );
    final probability = map.equipmentDropRate * config.baseEquipDropProbability;
    if (rng.nextDouble() >= probability.clamp(0.0, 1.0)) return null;

    final byId = {for (final def in equipmentDefs) def.id: def};
    final mapEntries = map.dropTable
        .whereType<EquipmentDrop>()
        .where((entry) => byId.containsKey(entry.equipmentDefId))
        .toList(growable: false);
    if (mapEntries.isEmpty) return null;

    final totalSlotWeight = mapEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.dropChance,
    );
    if (totalSlotWeight <= 0) return null;
    var slotRoll = rng.nextDouble() * totalSlotWeight;
    var chosenEntry = mapEntries.last;
    for (final entry in mapEntries) {
      slotRoll -= entry.dropChance;
      if (slotRoll < 0) {
        chosenEntry = entry;
        break;
      }
    }
    final slot = byId[chosenEntry.equipmentDefId]!.slot;
    final mapBaseIndex = mapEntries
        .map((entry) => byId[entry.equipmentDefId]!.tier.index)
        .reduce(math.min);
    final realmMinusOne = math.max(
      EquipmentTier.xunChang.index,
      realm.index - 1,
    );
    final anchor = EquipmentTier.values[math.max(mapBaseIndex, realmMinusOne)];
    final target = selectEquipmentTier(
      anchorTier: anchor,
      weights: config.equipmentTierWeights[nodeIndex - 1],
      roll: rng.nextDouble(),
    );

    List<EquipmentDef> pool = const [];
    for (var tierIndex = target.index; tierIndex >= 0; tierIndex--) {
      pool =
          equipmentDefs
              .where(
                (def) =>
                    def.slot == slot &&
                    def.tier == EquipmentTier.values[tierIndex] &&
                    !def.isLineageHeritage,
              )
              .toList(growable: false)
            ..sort((a, b) => a.id.compareTo(b.id));
      if (pool.isNotEmpty) break;
    }
    if (pool.isEmpty) return null;

    return EquipmentFactory.fromDef(
      rng.pick(pool),
      rng: rng,
      obtainedAt: obtainedAt,
      obtainedFrom: obtainedFrom,
    );
  }
}
