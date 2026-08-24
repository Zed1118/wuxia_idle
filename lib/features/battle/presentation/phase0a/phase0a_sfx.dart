import '../../../../shared/audio/audio_assets.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';

/// Phase 0A 战斗事件 → SFX 资产路径纯映射。
///
/// 对齐旧战斗 `sfxForAction` 体例:表现层消费事件流时调用,不读/写 state。
/// 只用磁盘已有资产的既有槽位,不新增无资产 SfxId(BACKLOG 二#13 ① 约束):
/// - 普攻命中按出手方选 `battleHit_<side>_0` 变体(玩家 0 / 敌方 1);
///   暴击/大招优先级高于普通命中(同 `sfxForAction`)。
/// - Q 聚怪起手用 `battleChargeStart`(力场蓄起,全库语义最接近的既有资产)。
/// - R 清场起手用 `battleUlt`(大招语义)。
/// - `Phase0aEnemyDefeated` 静默:`battleDeath.mp3` 资产不存在,待资产或拍板。
/// - 终局 jingle:`battle_victory → victory` / `battle_defeat → defeat`
///   (9B 落地,对齐旧战斗结算 overlay 语义);波次/可用性事件静默。
String? phase0aSfxAssetForEvent(
  Phase0aEvent event, {
  required String playerId,
}) {
  if (event is Phase0aHitLanded) {
    if (event.isUltimate) return sfxAssetPath(SfxId.battleUlt);
    if (event.isCritical) return sfxAssetPath(SfxId.battleCrit);
    return battleHitAssetPath(
      teamSide: event.actor == playerId ? 0 : 1,
      slotIndex: 0,
    );
  }
  if (event is Phase0aGatherStarted) {
    return sfxAssetPath(SfxId.battleChargeStart);
  }
  if (event is Phase0aClearStarted) {
    return sfxAssetPath(SfxId.battleUlt);
  }
  if (event is Phase0aDefenseStarted || event is Phase0aDefenseResolved) {
    return sfxAssetPath(SfxId.battleChargeStart);
  }
  // 终局 jingle:对齐旧战斗「勝/敗 结算 overlay 出现时」语义(9B 拍板落地)。
  if (event is Phase0aBattleVictory) {
    return sfxAssetPath(SfxId.victory);
  }
  if (event is Phase0aBattleDefeat) {
    return sfxAssetPath(SfxId.defeat);
  }
  return null;
}
