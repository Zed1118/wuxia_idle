import 'dart:math' as math;

import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/skill_unlock_entry.dart';
import '../../../data/defs/item_def.dart';
import '../../../data/defs/realm_def.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../../level/application/level_service.dart';
import '../../level/domain/level_config.dart';

/// 材料经济 P2：道具"使用"派发服务。
///
/// 消费（InventoryItem 扣减）+ 效果同一 [Isar.writeTxn] 原子（沿 ShopService）。
/// - jingYanDan → [CharacterAdvancementService.applyExperience]（founder 角色）。
/// - techniqueScroll → inline 解锁 `skillUnlockProgress`（**不调 grantManual**：
///   后者自开 writeTxn，嵌套会抛）。已解锁则不消费。
/// - recovery item（如桃花岛疗伤丹）→ 减少轻伤/重伤/心魔余毒。
class ItemUseService {
  /// 使用一份道具 [def]。
  ///
  /// - [realmLookup]：升层时查下一档 RealmDef（生产传 `GameRepository.instance.getRealm`）。
  /// - [isLayerLocked]：心魔余毒锁层 hook（可选，null=不锁）。
  static Future<ItemUseResult> use(
    Isar isar, {
    required ItemDef def,
    required RealmDef Function(RealmTier, RealmLayer) realmLookup,
    bool Function(RealmTier, RealmLayer)? isLayerLocked,
    // 第八阶段·角色等级 Lv:经验丹增益与境界 EXP 同源并行喂(null=测试不动)。
    LevelConfig? levelConfig,
  }) async {
    return isar.writeTxn(() async {
      final item = await isar.inventoryItems.getByDefId(def.defId);
      if (item == null || item.quantity <= 0) {
        return const ItemUseResult(kind: ItemUseKind.noStock);
      }

      switch (def.type) {
        case ItemType.jingYanDan:
          final founder = await isar.characters
              .filter()
              .isFounderEqualTo(true)
              .findFirst();
          if (founder == null) {
            return const ItemUseResult(kind: ItemUseKind.noTarget);
          }
          // 经验增益 = 当层升层所需经验 × layer_fraction（随境界缩放）。
          final gain = (founder.experienceToNextLayer * def.layerFraction!)
              .round();
          final result = CharacterAdvancementService.applyExperience(
            founder,
            gain,
            realmLookup: realmLookup,
            isLayerLocked: isLayerLocked,
          );
          if (levelConfig != null) {
            LevelService.applyLevelExp(founder, gain, config: levelConfig);
          }
          await isar.characters.put(founder);
          await _consumeOne(isar, item);
          return ItemUseResult(
            kind: ItemUseKind.experienceApplied,
            layersGained: result.layersGained,
            itemName: def.name,
          );

        case ItemType.techniqueScroll:
          final save = await isar.saveDatas.get(0);
          if (save == null) {
            return const ItemUseResult(kind: ItemUseKind.noTarget);
          }
          // @embedded list 取出 fixed-length → 转 growable 再 mutate。
          save.skillUnlockProgress = List.of(save.skillUnlockProgress);
          if (save.skillUnlockProgress.isUnlocked(def.unlockSkillId!)) {
            // 已解锁：不消费、不写。
            return ItemUseResult(
              kind: ItemUseKind.alreadyKnown,
              itemName: def.name,
            );
          }
          save.skillUnlockProgress.markUnlocked(def.unlockSkillId!);
          await isar.saveDatas.put(save);
          await _consumeOne(isar, item);
          return ItemUseResult(
            kind: ItemUseKind.skillUnlocked,
            itemName: def.name,
            unlockedSkillId: def.unlockSkillId,
          );

        default:
          if (def.hasRecoveryEffect) {
            final target = await _findRecoveryTarget(isar);
            if (target == null) {
              return const ItemUseResult(kind: ItemUseKind.noTarget);
            }

            final beforeInjury = target.injuryHoursRemaining;
            final beforeResidue = target.innerDemonResidueHoursRemaining;
            final beforeLight = target.lightInjuryStacks;
            final changed =
                (def.injuryHealHours > 0 && beforeInjury > 0) ||
                (def.residueHealHours > 0 && beforeResidue > 0) ||
                (def.clearLightInjury && beforeLight > 0);
            if (!changed) {
              return ItemUseResult(
                kind: ItemUseKind.noEffect,
                itemName: def.name,
                targetName: target.name,
              );
            }

            target.injuryHoursRemaining = math.max(
              0.0,
              target.injuryHoursRemaining - def.injuryHealHours,
            );
            target.innerDemonResidueHoursRemaining = math.max(
              0.0,
              target.innerDemonResidueHoursRemaining - def.residueHealHours,
            );
            if (def.clearLightInjury) {
              target.lightInjuryStacks = 0;
            }

            await isar.characters.put(target);
            await _consumeOne(isar, item);
            return ItemUseResult(
              kind: ItemUseKind.recoveryApplied,
              itemName: def.name,
              targetName: target.name,
              injuryHoursReduced: beforeInjury - target.injuryHoursRemaining,
              residueHoursReduced:
                  beforeResidue - target.innerDemonResidueHoursRemaining,
              lightInjuryStacksCleared: beforeLight - target.lightInjuryStacks,
            );
          }

          // 磨剑石/心血结晶/银两/普通杂项无"使用"语义。
          return const ItemUseResult(kind: ItemUseKind.notUsable);
      }
    });
  }

  static Future<Character?> _findRecoveryTarget(Isar isar) async {
    final active = await isar.characters
        .filter()
        .isActiveEqualTo(true)
        .findAll();
    final founder = await isar.characters
        .filter()
        .isFounderEqualTo(true)
        .findFirst();
    final candidates = active.isNotEmpty ? active : [?founder];
    if (candidates.isEmpty) return null;

    Character? best;
    var bestScore = -1.0;
    for (final c in candidates) {
      final score =
          c.injuryHoursRemaining +
          c.innerDemonResidueHoursRemaining +
          c.lightInjuryStacks;
      if (score > bestScore) {
        best = c;
        bestScore = score;
      }
    }
    return best;
  }

  /// 扣 1（归 0 删行）。
  static Future<void> _consumeOne(Isar isar, InventoryItem item) async {
    item.quantity -= 1;
    if (item.quantity <= 0) {
      await isar.inventoryItems.delete(item.id);
    } else {
      item.lastObtainedAt = DateTime.now();
      await isar.inventoryItems.put(item);
    }
  }
}

/// 使用结果类型。
enum ItemUseKind {
  experienceApplied, // 经验丹入账（layersGained 区分是否升层）
  skillUnlocked, // 秘籍新解锁
  recoveryApplied, // 疗伤/余毒恢复已应用
  alreadyKnown, // 秘籍已解锁（未消费）
  noEffect, // 有目标但无需用药（未消费）
  noStock, // 无库存
  noTarget, // 无 founder / SaveData
  notUsable, // 该 ItemType 无使用语义
}

/// 使用结果。
class ItemUseResult {
  final ItemUseKind kind;
  final int layersGained;
  final String? itemName;
  final String? unlockedSkillId;
  final String? targetName;
  final double injuryHoursReduced;
  final double residueHoursReduced;
  final int lightInjuryStacksCleared;

  const ItemUseResult({
    required this.kind,
    this.layersGained = 0,
    this.itemName,
    this.unlockedSkillId,
    this.targetName,
    this.injuryHoursReduced = 0.0,
    this.residueHoursReduced = 0.0,
    this.lightInjuryStacksCleared = 0,
  });
}
