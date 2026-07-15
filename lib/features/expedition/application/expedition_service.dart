import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../activity/domain/activity_member_snapshot.dart';
import '../domain/expedition_run.dart';

/// 百草岭远征应用服务（§4.1/§9.1）。
///
/// A1 冻结 `ExpeditionRun`/`ActivityMemberSnapshot`/`SaveData.expeditionRunSerial`；
/// 本服务负责派遣入场事务（B2.1）。离线分批结算/召回战败见 B2.2/B2.3。
class ExpeditionService {
  const ExpeditionService(this._isar);

  final Isar _isar;

  /// 派遣入场：单 `writeTxn` 校验占用 → 建 [ExpeditionRun] 快照 → `serial++` → put。
  /// 返回落库的 run id；任一校验不过抛 [StateError]，事务回滚。
  ///
  /// 校验（§4.1）：队伍 1-3 人、无重复、不含祖师、成员未被其它活动占用、成员已修
  /// 主修；每存档最多一条 active 远征（§8.3）。成员生命/真气不在派遣期计算——
  /// `currentNode==0` 即「未开战」，B2.2 首战按 `BattleCharacter.fromCharacter`
  /// 满血起，之后写回快照 HP/qi（跨节点继承）。
  ///
  /// `run.seed` 存新 serial（run 稳定标识，B2.2 用作 `ExpeditionRules.generateNode`
  /// 的 runSerial，与 saveDataId + 节点号混合出稳定节点 seed）。
  Future<int> dispatch({
    required List<int> characterIds,
    required ExpeditionPolicy policy,
    DateTime? now,
  }) async {
    if (characterIds.isEmpty || characterIds.length > 3) {
      throw StateError('远征派遣：队伍须 1-3 人，got ${characterIds.length}');
    }
    if (characterIds.toSet().length != characterIds.length) {
      throw StateError('远征派遣：队伍含重复角色');
    }

    return _isar.writeTxn(() async {
      final save = await _isar.saveDatas.get(0);
      if (save == null) throw StateError('远征派遣：无存档');

      final runs = await _isar.expeditionRuns.where().findAll();
      if (runs.any((r) => r.saveDataId == save.id)) {
        throw StateError('远征派遣：已有进行中的远征，需先召回/结束');
      }

      final occupancy = await CharacterOccupancyService(_isar).snapshot();
      final members = <ActivityMemberSnapshot>[];
      for (final cid in characterIds) {
        final c = await _isar.characters.get(cid);
        if (c == null) throw StateError('远征派遣：角色 $cid 不存在');
        if (c.isFounder) throw StateError('远征派遣：祖师不可派遣');
        if (occupancy.isCharacterOccupied(cid)) {
          throw StateError('远征派遣：角色 $cid 已被其它活动占用');
        }
        final mainTechId = c.mainTechniqueId;
        if (mainTechId == null) {
          throw StateError('远征派遣：角色 $cid 未修主修，不可派遣');
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

      final newSerial = save.expeditionRunSerial + 1;
      save.expeditionRunSerial = newSerial;

      final run = ExpeditionRun()
        ..saveDataId = save.id
        ..policy = policy
        ..seed = newSerial
        ..departedAt = now ?? DateTime.now()
        ..lastSettledAt = null
        ..currentNode = 0
        ..members = members
        ..stagedRewards = [];

      await _isar.saveDatas.put(save);
      return _isar.expeditionRuns.put(run);
    });
  }
}
