import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/inner_breath_disorder.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';
import '../../cultivation/application/progression_gate_service.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../taohua_island/application/island_settle_service.dart';
import '../domain/retreat_session.dart';
import 'passive_idle_integrator.dart';

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
/// [compute] 纯函数算产量（经验/磨剑石各走 numbers.yaml passive_idle 锚点）。
/// Persisted accrual uses [settleWindow]; active retreats own their whole window.
class OfflinePassiveService {
  OfflinePassiveService._();

  /// 按离线时长 + 主角境界算被动产量。
  /// [awayHours] is clamped at zero and has no upper time cap.
  static PassiveYield compute({
    required double awayHours,
    required RealmTier realmTier,
    required PassiveIdleConfig config,
  }) {
    final settledHours = awayHours < 0 ? 0.0 : awayHours;
    final scale = config.realmScaleFor(realmTier);
    final mojianshi = (config.baseMojianshiPerHour * settledHours * scale)
        .floor();
    final experience = (config.baseExpPerHour * settledHours * scale).floor();
    return (
      mojianshi: mojianshi,
      experience: experience,
      awayHours: awayHours,
      settledHours: settledHours,
      isCapped: false,
    );
  }

  /// Settles the persistent passive ledger atomically. Lifecycle presence and
  /// injury recovery are separate opt-ins; ordinary reward boundaries use the
  /// defaults and cannot heal the character or overwrite the recovery window.
  static Future<PassiveYield?> settleWindow({
    required Isar isar,
    required DateTime now,
    bool recoverInjuries = false,
    bool updatePresence = false,
    bool settleIslandBeforeGrowth = false,
  }) => isar.writeTxn(
    () => settleWithinTxn(
      isar: isar,
      now: now,
      recoverInjuries: recoverInjuries,
      updatePresence: updatePresence,
      settleIslandBeforeGrowth: settleIslandBeforeGrowth,
    ),
  );

  /// Caller must own the Isar write transaction. Read the character again after
  /// this call before applying another reward: passive experience can advance it.
  /// External growth and succession also settle an already opened island at the
  /// current realm before they change it. Routine heartbeats leave its window.
  static Future<PassiveYield?> settleWithinTxn({
    required Isar isar,
    required DateTime now,
    bool recoverInjuries = false,
    bool updatePresence = false,
    bool settleIslandBeforeGrowth = false,
  }) async {
    final save = await isar.saveDatas.get(0);
    if (save == null) return null;
    final ownerId = save.founderCharacterId;
    if (ownerId == null) return null;
    final character = await isar.characters.get(ownerId);
    if (character == null || !character.isAlive) return null;

    final anchor = save.passiveLastSettledAt ?? save.lastOnlineAt;
    if (now.isBefore(anchor)) return null;
    _validateRemainder(save.passiveMojianshiRemainder);
    _validateRemainder(character.passiveExperienceRemainder);

    final active = await isar.retreatSessions
        .filter()
        .saveDataIdEqualTo(save.slotId)
        .statusEqualTo(RetreatStatus.active)
        .findFirst();
    if (active != null) {
      // The retreat owns this entire window, including its ordinary tail after
      // 72 hours. Preserve pre-retreat fractions but never accrue it twice.
      if (settleIslandBeforeGrowth) {
        await _settleIslandIfInitialized(isar, save, now, character.realmTier);
      }
      save.passiveLastSettledAt = now;
      if (updatePresence && !now.isBefore(save.lastOnlineAt)) {
        save.lastOnlineAt = now;
      }
      await isar.saveDatas.put(save);
      return null;
    }

    if (save.passiveLastSettledAt == null &&
        save.lastOnlineAt == save.createdAt) {
      // An unestablished legacy timestamp is not evidence of earned time.
      if (settleIslandBeforeGrowth) {
        await _settleIslandIfInitialized(isar, save, now, character.realmTier);
      }
      save.passiveLastSettledAt = now;
      if (updatePresence) save.lastOnlineAt = now;
      await isar.saveDatas.put(save);
      return null;
    }

    final elapsed = now.difference(anchor).inMicroseconds;
    final hours = elapsed / Duration.microsecondsPerHour;
    final repository = GameRepository.instance;
    final progress = await isar.mainlineProgress
        .filter()
        .saveDataIdEqualTo(save.slotId)
        .findFirst();
    final cleared = progress?.clearedStageIds.toSet() ?? <String>{};
    final accrual = PassiveIdleIntegrator.accrue(
      character: character,
      elapsedMicroseconds: elapsed,
      config: repository.numbers.passiveIdle,
      experienceRemainder: character.passiveExperienceRemainder,
      mojianshiRemainder: save.passiveMojianshiRemainder,
      realmLookup: repository.getRealm,
      isLayerLocked: (tier, layer) => ProgressionGateService.isLayerLocked(
        nextTier: tier,
        nextLayer: layer,
        releaseCap: repository.numbers.progressionReleaseCap,
        realmLookup: repository.getRealm,
        innerDemonDef: repository.numbers.innerDemon,
        clearedStageIds: cleared,
      ),
    );

    for (final change in accrual.realmTierChanges) {
      await _settleIslandIfInitialized(
        isar,
        save,
        anchor.add(Duration(microseconds: change.elapsedMicroseconds)),
        change.previousTier,
      );
    }
    if (settleIslandBeforeGrowth) {
      await _settleIslandIfInitialized(isar, save, now, character.realmTier);
    }

    if (accrual.mojianshi > 0) {
      final item =
          await isar.inventoryItems.getByDefId('item_mojianshi') ??
          (InventoryItem()
            ..defId = 'item_mojianshi'
            ..itemType = ItemType.moJianShi
            ..firstObtainedAt = now);
      item.quantity += accrual.mojianshi;
      item.lastObtainedAt = now;
      await isar.inventoryItems.put(item);
    }
    character.passiveExperienceRemainder = accrual.experienceRemainder;
    save.passiveMojianshiRemainder = accrual.mojianshiRemainder;

    if (recoverInjuries) {
      final recoveryHours =
          now.difference(save.lastOnlineAt).inMicroseconds /
          Duration.microsecondsPerHour;
      if (recoveryHours > 0) {
        InnerBreathDisorder.recover(character: character, hours: recoveryHours);
        final remaining = character.injuryHoursRemaining - recoveryHours;
        character.injuryHoursRemaining = remaining < 0 ? 0 : remaining;
        character.lightInjuryStacks = 0;
      }
    }

    save.totalPassiveMojianshi += accrual.mojianshi;
    save.totalPassiveExperience += accrual.experience;
    save.passiveLastSettledAt = now;
    if (updatePresence && !now.isBefore(save.lastOnlineAt)) {
      save.lastOnlineAt = now;
    }
    await isar.characters.put(character);
    await isar.saveDatas.put(save);
    if (elapsed == 0) return null;
    return (
      mojianshi: accrual.mojianshi,
      experience: accrual.experience,
      awayHours: hours,
      settledHours: hours,
      isCapped: false,
    );
  }

  /// The completed retreat has already settled its interval. Resume ordinary
  /// accrual at that boundary without awarding it again or discarding fractions.
  static Future<void> resumeAfterRetreatWithinTxn({
    required Isar isar,
    required DateTime now,
  }) async {
    final save = await isar.saveDatas.get(0);
    if (save == null) return;
    final anchor = save.passiveLastSettledAt;
    if (anchor != null && now.isBefore(anchor)) return;
    save.passiveLastSettledAt = now;
    await isar.saveDatas.put(save);
  }

  static void _validateRemainder(double value) {
    if (!value.isFinite || value < 0 || value >= 1) {
      throw StateError('Invalid passive resource remainder: $value');
    }
  }

  static Future<void> _settleIslandIfInitialized(
    Isar isar,
    SaveData save,
    DateTime now,
    RealmTier realmTier,
  ) async {
    if (save.islandLastSettledAt == null) return;
    await IslandSettleService.settleInTxn(
      save,
      now,
      realmIndex: realmTier.index,
      database: isar,
    );
  }
}
