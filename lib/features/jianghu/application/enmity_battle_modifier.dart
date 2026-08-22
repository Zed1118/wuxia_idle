import '../../../shared/battle_shared/enmity_target_id.dart';

/// 江湖恩怨的引擎中立战斗身份桥。
class EnmityBattleModifier {
  EnmityBattleModifier._();

  /// 为 `StageDef.npcId` 生成稳定的战斗/关系 target id。
  ///
  /// 使用独立负数空间，避免与玩家 Isar 正 id 以及普通 EnemyDef slot id
  /// (-1/-2/-3) 冲突。该 id 是 schema bridge，不是战斗数值。
  static int targetIdForNpcId(String npcId) =>
      EnmityTargetId.targetIdForNpcId(npcId);
}
