import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../data/numbers_config.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../../level/application/level_service.dart';
import '../../inner_demon/application/inner_demon_service.dart';
import '../../mainline/domain/mainline_progress.dart';

/// 被动离线挂机一次结算的产量（纯数据）。
typedef PassiveYield = ({
  int mojianshi,
  int experience,
  double awayHours,
  double settledHours,
  bool isCapped,
});

/// M2 范围 B 通用被动离线挂机服务。
///
/// [compute] 纯函数算产量（≈闭关 25%，base 走 numbers.yaml passive_idle）。
/// 副作用入库见 [settle]（Task 4）。与闭关互斥：仅在无 active 闭关时由 gate 调用。
class OfflinePassiveService {
  OfflinePassiveService._();

  /// 按离线时长 + 主角境界算被动产量。
  /// [awayHours] 由 caller 传入（gate 已 clamp 下界 0）；内部按 cap 截上界。
  static PassiveYield compute({
    required double awayHours,
    required RealmTier realmTier,
    required PassiveIdleConfig config,
  }) {
    final capped = awayHours.clamp(0, config.capHours.toDouble());
    final scale = config.realmScaleFor(realmTier);
    final mojianshi = (config.baseMojianshiPerHour * capped * scale)
        .floor()
        .clamp(0, 999999);
    final experience = (config.baseExpPerHour * capped * scale).floor().clamp(
      0,
      999999,
    );
    return (
      mojianshi: mojianshi,
      experience: experience,
      awayHours: awayHours,
      settledHours: capped.toDouble(),
      isCapped: awayHours > config.capHours,
    );
  }

  /// 结算一次被动离线产出并写 Isar（同事务）：
  ///   1. 磨剑石 → InventoryItem(item_mojianshi)
  ///   2. 经验 → CharacterAdvancementService.applyExperience（含升层 + 心魔锁，
  ///      与闭关收功一致）
  ///   3. SaveData 累计 += + lastOnlineAt = now（重置基准，防重复结算）
  /// 仅由 gate 在「无 active 闭关 + 离线>0」时调用（互斥见 spec）。返回本次产量。
  static Future<PassiveYield> settle({
    required int saveDataId,
    required int characterId,
    required double awayHours,
    required DateTime now,
  }) async {
    final isar = IsarSetup.instance;
    final ch = await isar.characters.get(characterId);
    final realmTier = ch?.realmTier ?? RealmTier.xueTu;
    final yield_ = compute(
      awayHours: awayHours,
      realmTier: realmTier,
      config: GameRepository.instance.numbers.passiveIdle,
    );

    await isar.writeTxn(() async {
      if (yield_.mojianshi > 0) {
        final existing = await isar.inventoryItems.getByDefId('item_mojianshi');
        if (existing != null) {
          existing.quantity += yield_.mojianshi;
          existing.lastObtainedAt = now;
          await isar.inventoryItems.put(existing);
        } else {
          await isar.inventoryItems.put(
            InventoryItem()
              ..defId = 'item_mojianshi'
              ..itemType = ItemType.moJianShi
              ..quantity = yield_.mojianshi
              ..firstObtainedAt = now
              ..lastObtainedAt = now,
          );
        }
      }

      final c = await isar.characters.get(characterId);
      if (c != null) {
        // Task 8: 双层伤势疗养（§5.5 在线=离线，按 awayHours 真实离线时长累减，
        // 无加速）。重伤按时长累减 clamp ≥ 0；轻伤离线结算即清零。
        // 关键：放在 experience>0 之外的无条件路径——即使本次 0 产出，挂机即疗养。
        if (c.injuryHoursRemaining > 0) {
          final left = c.injuryHoursRemaining - awayHours;
          c.injuryHoursRemaining = left < 0 ? 0 : left;
        }
        c.lightInjuryStacks = 0;

        if (yield_.experience > 0) {
          final progress = await isar.mainlineProgress
              .filter()
              .saveDataIdEqualTo(saveDataId)
              .findFirst();
          final clearedSet = progress?.clearedStageIds.toSet() ?? <String>{};
          final innerDemonDef = GameRepository.instance.numbers.innerDemon;
          CharacterAdvancementService.applyExperience(
            c,
            yield_.experience,
            realmLookup: GameRepository.instance.getRealm,
            isLayerLocked: (tier, layer) => InnerDemonService.isLayerLocked(
              nextTier: tier,
              nextLayer: layer,
              innerDemonDef: innerDemonDef,
              clearedStageIds: clearedSet,
            ),
          );
          // 第八阶段·角色等级 Lv:与境界 EXP 同源并行喂(离线被动 · 在线=离线守 §5.5)。
          LevelService.applyLevelExp(
            c,
            yield_.experience,
            config: GameRepository.instance.numbers.level,
          );
        }
        await isar.characters.put(c);
      }

      final save = await isar.saveDatas.get(0);
      if (save != null) {
        save.totalPassiveMojianshi += yield_.mojianshi;
        save.totalPassiveExperience += yield_.experience;
        save.lastOnlineAt = now;
        await isar.saveDatas.put(save);
      }
    });

    return yield_;
  }
}
