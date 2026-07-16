import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../activity/domain/activity_member_snapshot.dart';
import '../domain/boss_gauntlet_run.dart';

/// 断魂庄应用服务（spec §5.1/§9.2）。
///
/// C2.1 入场扣帖 + 补给会话托管：单 `writeTxn` 内校验 → 扣一张断魂帖 →
/// 最多三份补给从普通库存移入 [BossGauntletRun] 托管栏 → 建 active 会话。
/// 关闭/结算返还托管、离线恢复、奖励发放见后续切片（C2.2–C2.5）。
class GauntletService {
  const GauntletService(this._isar);

  final Isar _isar;

  /// 副本凭证 defId（断魂帖）。每次入场消耗一张，消耗凭证与建会话同事务（§5.1）。
  static const String ticketDefId = 'item_duanhuntie';

  /// 入场：单 `writeTxn` 建断魂庄 active 会话，返回落库的 run id。
  ///
  /// [supplies] = defId → 份数（疗伤丹/行囊补给自由混装），总份数 ≤ [supplyCap]。
  Future<int> enter({
    required List<int> characterIds,
    Map<String, int> supplies = const {},
    required int supplyCap,
  }) async {
    if (characterIds.isEmpty || characterIds.length > 3) {
      throw StateError('断魂庄入场：队伍须 1-3 人，got ${characterIds.length}');
    }
    if (characterIds.toSet().length != characterIds.length) {
      throw StateError('断魂庄入场：队伍含重复角色');
    }
    if (supplies.values.any((v) => v <= 0)) {
      throw StateError('断魂庄入场：补给份数须为正');
    }
    final totalSupplies = supplies.values.fold(0, (a, b) => a + b);
    if (totalSupplies > supplyCap) {
      throw StateError('断魂庄入场：补给至多 $supplyCap 份，got $totalSupplies');
    }

    return _isar.writeTxn(() async {
      final save = await _isar.saveDatas.get(0);
      if (save == null) throw StateError('断魂庄入场：无存档');

      final runs = await _isar.bossGauntletRuns.where().findAll();
      if (runs.any((r) => r.saveDataId == save.id)) {
        throw StateError('断魂庄入场：已有进行中的断魂庄会话，需先结束');
      }

      final occupancy = await CharacterOccupancyService(_isar).snapshot();
      final members = <ActivityMemberSnapshot>[];
      for (final cid in characterIds) {
        final c = await _isar.characters.get(cid);
        if (c == null) throw StateError('断魂庄入场：角色 $cid 不存在');
        if (c.isFounder) throw StateError('断魂庄入场：祖师不可入场');
        if (occupancy.isCharacterOccupied(cid)) {
          throw StateError('断魂庄入场：角色 $cid 已被其它活动占用');
        }
        final mainTechId = c.mainTechniqueId;
        if (mainTechId == null) {
          throw StateError('断魂庄入场：角色 $cid 未修主修，不可入场');
        }
        members.add(
          ActivityMemberSnapshot()
            ..characterId = cid
            ..reservedEquipmentIds = [
              ?c.equippedWeaponId,
              ?c.equippedArmorId,
              ?c.equippedAccessoryId,
            ]
            ..reservedTechniqueIds = [mainTechId, ...c.assistTechniqueIds]
            ..currentHp = 0
            ..currentQi = 0
            ..isDowned = false,
        );
      }

      // 扣一张断魂帖（消耗凭证与建会话同事务·§5.1）。
      final ticket = await _isar.inventoryItems.getByDefId(ticketDefId);
      if (ticket == null || ticket.quantity < 1) {
        throw StateError('断魂庄入场：无断魂帖，不可入场');
      }
      ticket.quantity -= 1;
      await _isar.inventoryItems.put(ticket);

      // 补给移入托管栏（平行三列表·扣普通库存·usedQty 全 0）。
      final escrowDefIds = <String>[];
      final escrowLoaded = <int>[];
      final escrowUsed = <int>[];
      for (final entry in supplies.entries) {
        final item = await _isar.inventoryItems.getByDefId(entry.key);
        if (item == null || item.quantity < entry.value) {
          throw StateError('断魂庄入场：补给 ${entry.key} 库存不足');
        }
        item.quantity -= entry.value;
        await _isar.inventoryItems.put(item);
        escrowDefIds.add(entry.key);
        escrowLoaded.add(entry.value);
        escrowUsed.add(0);
      }

      final run = BossGauntletRun()
        ..saveDataId = save.id
        // seed = saveId 派生（无 run serial·异于远征）；每关组合层再混 currentStage。
        ..seed = save.id
        ..currentStage = 1
        ..sessionPhase = GauntletPhase.inBattle
        ..members = members
        ..escrowItemDefIds = escrowDefIds
        ..escrowLoadedQty = escrowLoaded
        ..escrowUsedQty = escrowUsed;

      return _isar.bossGauntletRuns.put(run);
    });
  }
}
