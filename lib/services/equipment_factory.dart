import '../data/defs/equipment_def.dart';
import '../data/models/equipment.dart';
import '../utils/rng.dart';

/// 装备实例工厂（phase2_tasks T19）。
///
/// 把 [EquipmentDef]（yaml 加载，不可变）roll 出一件具体的 [Equipment]
/// 实例，写入 Isar 由调用方负责。
///
/// 设计原则：
///   - **纯 def-driven**：数值范围全部从 [EquipmentDef] 取，不读 NumbersConfig
///   - **依赖注入 [Rng]**：测试可塞固定种子或 mock，业务代码用 [DefaultRng]
///   - **fail-fast**：def 范围非法（min > max）立即抛错，不静默返回 0
///
/// 共鸣度阶段、强化加成不在 factory 范围，由各自 service / extension 处理。
class EquipmentFactory {
  EquipmentFactory._();

  /// 按 [def] 的 `[min, max]` 区间 roll 出 baseAttack / baseHealth / baseSpeed
  /// 三项，组合成一件 [Equipment] 实例。
  ///
  /// `forgingSlots` 由 [Equipment.create] 自动填齐 3 个空槽。
  ///
  /// [obtainedAt] / [obtainedFrom] 由调用方传（典型来源："掉落" / "商店" /
  /// "奇遇" / "师承"），方便后续 GameEvent 摘要。
  static Equipment fromDef(
    EquipmentDef def, {
    required Rng rng,
    required DateTime obtainedAt,
    required String obtainedFrom,
    int? ownerCharacterId,
    bool isLineageHeritage = false,
  }) {
    _validateRange(def);

    final baseAttack = _rollInclusive(rng, def.baseAttackMin, def.baseAttackMax);
    final baseHealth = _rollInclusive(rng, def.baseHealthMin, def.baseHealthMax);
    final baseSpeed = _rollInclusive(rng, def.baseSpeedMin, def.baseSpeedMax);

    return Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      school: def.schoolBias,
      baseAttack: baseAttack,
      baseHealth: baseHealth,
      baseSpeed: baseSpeed,
      obtainedAt: obtainedAt,
      obtainedFrom: obtainedFrom,
      ownerCharacterId: ownerCharacterId,
      isLineageHeritage: isLineageHeritage,
    );
  }

  /// `[min, max]` 闭区间随机整数。`min == max` 时直接返回该值。
  static int _rollInclusive(Rng rng, int min, int max) {
    if (min == max) return min;
    return min + rng.nextInt(max - min + 1);
  }

  static void _validateRange(EquipmentDef def) {
    if (def.baseAttackMin > def.baseAttackMax) {
      throw StateError(
        'EquipmentDef ${def.id} baseAttack 范围非法：'
        'min=${def.baseAttackMin} > max=${def.baseAttackMax}',
      );
    }
    if (def.baseHealthMin > def.baseHealthMax) {
      throw StateError(
        'EquipmentDef ${def.id} baseHealth 范围非法：'
        'min=${def.baseHealthMin} > max=${def.baseHealthMax}',
      );
    }
    if (def.baseSpeedMin > def.baseSpeedMax) {
      throw StateError(
        'EquipmentDef ${def.id} baseSpeed 范围非法：'
        'min=${def.baseSpeedMin} > max=${def.baseSpeedMax}',
      );
    }
  }
}
