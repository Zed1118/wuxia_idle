import 'package:isar_community/isar.dart';

import '../core/domain/enums.dart';
import '../core/domain/equipment.dart';
import '../core/domain/inventory_item.dart';
import '../data/numbers_config.dart';
import '../utils/rng.dart';

/// 强化结果（phase2_tasks T20）。
///
/// `tryEnhance` / `useCrystalToGuarantee` 共用此返回类型，按 [outcome]
/// 区分语义：
///   - [EnhanceOutcome.success] / [EnhanceOutcome.failure]：tryEnhance 完成
///   - [EnhanceOutcome.capped] / [EnhanceOutcome.insufficientMojianshi]：tryEnhance 守卫
///   - [EnhanceOutcome.noGuaranteeAvailable] / [EnhanceOutcome.insufficientCrystal]：保底守卫
///
/// 永不破防降级（GDD §6.2 红线）：失败时 [oldLevel] == [newLevel]，仅扣材料 +
/// 心血结晶。
class EnhanceResult {
  final EnhanceOutcome outcome;
  final int oldLevel;
  final int newLevel;
  final int mojianshiSpent;
  final int crystalsGained;
  final int crystalsSpent;

  /// 本次尝试使用的成功率（capped / insufficient 时为 null）。
  final double? successRate;

  /// rng 实际 roll 出来的值（仅 tryEnhance 走判定时填）。
  final double? rolledRate;

  const EnhanceResult({
    required this.outcome,
    required this.oldLevel,
    required this.newLevel,
    this.mojianshiSpent = 0,
    this.crystalsGained = 0,
    this.crystalsSpent = 0,
    this.successRate,
    this.rolledRate,
  });

  bool get didLevelUp => newLevel > oldLevel;
}

enum EnhanceOutcome {
  success,
  failure,
  capped,
  insufficientMojianshi,
  insufficientCrystal,
  noGuaranteeAvailable,
}

/// 强化服务（GDD §6.2 / §6.3，phase2_tasks T20）。
///
/// 设计原则：
///   - **in-place 修改 [Equipment.enhanceLevel]**：与 Phase 1 `inheritFrom` /
///     `disperse` extension 风格一致（Equipment 是 Isar @collection，本就 mutable）
///   - **接收 [EnhancementConfig]** 而非整个 NumbersConfig，最小依赖
///   - **fail-fast** 配置非法（`neverDegrade=false`）
///   - **永不破防降级**：失败时 enhanceLevel 不变，仅扣材料 + 心血结晶 +1
///
/// 强化上限 = `min(49, characterAbsoluteLevel)`（GDD §6.2，与持有者境界
/// 总层数挂钩）。`absoluteLevel` 由 [RealmUtils.absoluteLevelOf] 计算。
///
/// Phase 5 W6-S2 改实例化：构造函数接 [Isar],原 static API 改实例方法。
/// 通过 `ref.read(enhancementServiceProvider)` 注入（nullable,widget test
/// 未 init Isar 时为 null,调用方短路）。
class EnhancementService {
  const EnhancementService({required this.isar});

  final Isar isar;

  /// 单次强化尝试。结果写入 [eq]（成功时 enhanceLevel++）+ 返回详细 [EnhanceResult]
  /// 供 UI 展示与调用方扣材料。
  ///
  /// 调用方根据 [EnhanceResult] 自行扣 [currentMojianshi] / 加 [crystalsGained]
  /// 到玩家库存（本服务**不直接修改**库存数量，保持纯函数 + Isar 写入分离）。
  ///
  /// 保持 static：纯函数无 Isar 依赖,widget test 在未 init Isar 时仍可调
  /// （`_persist` 才走 instance 路径 + nullable 短路）。
  static EnhanceResult tryEnhance({
    required Equipment eq,
    required int characterAbsoluteLevel,
    required Rng rng,
    required int currentMojianshi,
    required EnhancementConfig config,
  }) {
    if (!config.neverDegrade) {
      throw StateError('EnhancementConfig.neverDegrade=false 违反 GDD §6.2 红线');
    }

    final oldLevel = eq.enhanceLevel;
    final cap = _enhanceLevelCap(characterAbsoluteLevel);
    if (oldLevel >= cap) {
      return EnhanceResult(
        outcome: EnhanceOutcome.capped,
        oldLevel: oldLevel,
        newLevel: oldLevel,
      );
    }

    final targetLevel = oldLevel + 1;
    final cost = config.mojianshiCostFor(targetLevel);

    if (currentMojianshi < cost) {
      return EnhanceResult(
        outcome: EnhanceOutcome.insufficientMojianshi,
        oldLevel: oldLevel,
        newLevel: oldLevel,
      );
    }

    final successRate = config.successRateFor(targetLevel);
    final roll = rng.nextDouble();

    if (roll < successRate) {
      eq.enhanceLevel = targetLevel;
      return EnhanceResult(
        outcome: EnhanceOutcome.success,
        oldLevel: oldLevel,
        newLevel: targetLevel,
        mojianshiSpent: cost,
        successRate: successRate,
        rolledRate: roll,
      );
    }

    // 失败：永不破防降级，按 penalty 扣材料 + 必给 1 颗心血结晶
    final penalty = config.materialPenaltyFor(targetLevel);
    final actualSpent = _applyPenalty(cost, penalty);
    return EnhanceResult(
      outcome: EnhanceOutcome.failure,
      oldLevel: oldLevel,
      newLevel: oldLevel,
      mojianshiSpent: actualSpent,
      crystalsGained: config.crystalGainPerFailure,
      successRate: successRate,
      rolledRate: roll,
    );
  }

  /// 心血结晶保底（GDD §6.3）。仅 +14-49 段可用，+1-13 段返回
  /// [EnhanceOutcome.noGuaranteeAvailable]。
  ///
  /// 成功必扣 [CrystalGuaranteeBracket.crystalCost] 颗结晶；调用方自行扣库存。
  ///
  /// 同 [tryEnhance],保持 static：纯函数无 Isar 依赖。
  static EnhanceResult useCrystalToGuarantee({
    required Equipment eq,
    required int characterAbsoluteLevel,
    required int currentCrystals,
    required EnhancementConfig config,
  }) {
    final oldLevel = eq.enhanceLevel;
    final cap = _enhanceLevelCap(characterAbsoluteLevel);
    if (oldLevel >= cap) {
      return EnhanceResult(
        outcome: EnhanceOutcome.capped,
        oldLevel: oldLevel,
        newLevel: oldLevel,
      );
    }

    final targetLevel = oldLevel + 1;
    final crystalCost = config.crystalCostToGuarantee(targetLevel);
    if (crystalCost == null) {
      return EnhanceResult(
        outcome: EnhanceOutcome.noGuaranteeAvailable,
        oldLevel: oldLevel,
        newLevel: oldLevel,
      );
    }

    if (currentCrystals < crystalCost) {
      return EnhanceResult(
        outcome: EnhanceOutcome.insufficientCrystal,
        oldLevel: oldLevel,
        newLevel: oldLevel,
      );
    }

    eq.enhanceLevel = targetLevel;
    return EnhanceResult(
      outcome: EnhanceOutcome.success,
      oldLevel: oldLevel,
      newLevel: targetLevel,
      crystalsSpent: crystalCost,
      successRate: 1.0,
    );
  }

  /// T32 #22a：将 [tryEnhance] / [useCrystalToGuarantee] 的 in-place 改写
  /// 落地到 Isar，副作用合并到一个 writeTxn：
  /// 1. 成功 outcome → `equipments.put(eq)`（enhanceLevel 已被 service +1）
  /// 2. `result.mojianshiSpent > 0` → 扣 mojianshi 行 quantity
  /// 3. `result.crystalsGained / crystalsSpent > 0` → 增 / 扣 jieJing 行
  ///
  /// 材料行不存在直接抛 [StateError]（fail-fast，种子阶段必创）。Widget 层
  /// 调用此方法后自行 invalidate riverpod provider。
  Future<void> persistResult({
    required Equipment eq,
    required EnhanceResult result,
  }) async {
    await isar.writeTxn(() async {
      if (result.outcome == EnhanceOutcome.success) {
        await isar.equipments.put(eq);
      }
      if (result.mojianshiSpent > 0) {
        final row = await isar.inventoryItems
            .filter()
            .itemTypeEqualTo(ItemType.moJianShi)
            .findFirst();
        if (row == null) {
          throw StateError(
            'InventoryItem(itemType=moJianShi) 行不存在；种子阶段必须创建',
          );
        }
        row.quantity -= result.mojianshiSpent;
        await isar.inventoryItems.put(row);
      }
      if (result.crystalsGained > 0 || result.crystalsSpent > 0) {
        final row = await isar.inventoryItems
            .filter()
            .itemTypeEqualTo(ItemType.xinXueJieJing)
            .findFirst();
        if (row == null) {
          throw StateError(
            'InventoryItem(itemType=xinXueJieJing) 行不存在；种子阶段必须创建',
          );
        }
        row.quantity += result.crystalsGained;
        row.quantity -= result.crystalsSpent;
        await isar.inventoryItems.put(row);
      }
    });
  }

  /// 强化上限：`min(49, characterAbsoluteLevel)`。学徒-启蒙 absoluteLevel=1
  /// 时只能 +1，武圣-极境 49 时满 +49。
  static int _enhanceLevelCap(int characterAbsoluteLevel) {
    return characterAbsoluteLevel < 49 ? characterAbsoluteLevel : 49;
  }

  static int _applyPenalty(int cost, MaterialPenalty penalty) {
    switch (penalty) {
      case MaterialPenalty.none:
        return 0;
      case MaterialPenalty.half:
        return cost ~/ 2;
      case MaterialPenalty.full:
        return cost;
    }
  }
}
