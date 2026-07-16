import '../../activity/domain/activity_member_snapshot.dart';
import '../../battle/domain/battle_state.dart';

/// 断魂庄三关编排控制器（design §5.2-5.5）。
///
/// C1.2：关次边界白名单快照。一场战斗结束后，把玩家队伍战末态并入成员快照供下一关
/// 重建；**白名单只继承** 当前生命/当前真气/阵亡/技能冷却（§5.5）。行动条、临时
/// buff/debuff、护盾、召唤、内伤槽、敌方状态等**不进快照**——下一关按快照重建战斗时
/// 自然清空（§4.2）。reserved 装备/心法为入场占用冻结，从上一关 [before] 原样保留
/// （战斗态不含这两列）。
class GauntletController {
  const GauntletController._();

  /// 按 characterId 把 [finalState] 左队战末态并入 [before]，返回下一关边界快照。
  ///
  /// 白名单：`currentHp` / `currentQi` / `isDowned` / 技能冷却（仅 CD>0 项）。
  static List<ActivityMemberSnapshot> snapshotAfterStage({
    required List<ActivityMemberSnapshot> before,
    required BattleState finalState,
  }) {
    return [
      for (final prior in before)
        _mergeMember(prior, finalState.characterById(prior.characterId)),
    ];
  }

  static ActivityMemberSnapshot _mergeMember(
    ActivityMemberSnapshot prior,
    BattleCharacter? combatant,
  ) {
    final next = ActivityMemberSnapshot()
      ..characterId = prior.characterId
      // 占用冻结：reserved 从入场保留，战斗 finalState 不含这两列。
      ..reservedEquipmentIds = List<int>.from(prior.reservedEquipmentIds)
      ..reservedTechniqueIds = List<int>.from(prior.reservedTechniqueIds);

    if (combatant == null) {
      // 防御：finalState 缺该角色 → 保留上一关关次边界值，不凭空回满/清零。
      return next
        ..currentHp = prior.currentHp
        ..currentQi = prior.currentQi
        ..isDowned = prior.isDowned
        ..skillCooldownKeys = List<String>.from(prior.skillCooldownKeys)
        ..skillCooldownTurns = List<int>.from(prior.skillCooldownTurns);
    }

    final keys = <String>[];
    final turns = <int>[];
    combatant.skillCooldowns.forEach((skillId, cd) {
      if (cd > 0) {
        keys.add(skillId);
        turns.add(cd);
      }
    });

    return next
      ..currentHp = combatant.currentHp
      ..currentQi = combatant.currentQi
      ..isDowned = !combatant.isAlive
      ..skillCooldownKeys = keys
      ..skillCooldownTurns = turns;
  }
}
