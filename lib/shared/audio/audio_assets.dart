import 'package:wuxia_idle/core/domain/enums.dart';

/// BGM 轨道槽位。文件名用 enum.name（camelCase），manifest 同步登记。
///
/// 战斗轨按 [StageType]（+ mainline 的 Boss 关）细分 6 类，营造氛围差异；
/// 非战斗场景 [lineage]（传承）/[baike]（百科）各一轨。[battle] 留通用兜底
/// （demo/debug/legacy）。缺素材时 SoundManager._guard 静默 no-op。
enum BgmTrack {
  mainMenu,
  seclusion,
  battle, // 通用兜底（demo/debug/legacy）
  mainline, // 主线普通关
  tower, // 爬塔
  boss, // 章末/主线 Boss 关（压迫感）
  innerDemon, // 心魔关
  lightFoot, // 轻功对决
  massBattle, // 群战守城
  lineage, // 传承面板（非战斗）
  baike, // 百科（非战斗）
}

/// [StageType]（+ mainline Boss 关）→ 战斗 BGM 轨。声明式路由，无中央表。
///
/// - massBattle/innerDemon/lightFoot/tower：各用同名类型轨（类型氛围优先，
///   即便该类型内是 Boss 层也保持类型轨）。
/// - mainline：Boss 关切 [BgmTrack.boss] 制造压迫感，普通关用 [BgmTrack.mainline]。
/// - legacy pvp：旧枚举值保底走 [BgmTrack.battle]，当前不再由入口生成。
BgmTrack bgmTrackForStage(StageType type, {required bool isBoss}) {
  switch (type) {
    case StageType.massBattle:
      return BgmTrack.massBattle;
    case StageType.innerDemon:
      return BgmTrack.innerDemon;
    case StageType.lightFoot:
      return BgmTrack.lightFoot;
    case StageType.tower:
      return BgmTrack.tower;
    case StageType.mainline:
      return isBoss ? BgmTrack.boss : BgmTrack.mainline;
    case StageType.pvp:
      // 保留旧 StageType.pvp 反序列化/回放兜底，不提供 PVP 玩法入口。
      return BgmTrack.battle;
  }
}

/// SFX 槽位。battleDeath 暂留位不接线（YAGNI）。
enum SfxId {
  uiTap,
  uiTabSwitch,
  uiPaperOpen,
  battleHit,
  battleCrit,
  battleUlt,
  battleDeath,
  reward, // 装备掉落 jingle(主线胜利 dialog 含装备掉落时)
  battleChargeStart, // Boss 起手蓄力(预警)
  battleInterrupt, // 破招成功("破!")
  battleStagger, // 踉跄/破绽(每次踉跄跳过)
  victory, // 战斗胜利 jingle(「勝」结算 overlay 出现时)
  defeat, // 败北 jingle(「敗」结算 overlay 出现时,非 leftWin 一律敗)
  realmAdvance, // 大境界突破 jingle(跨 tier 才响保稀有感;同 dialog 优先于 reward)
}

String bgmAssetPath(BgmTrack track) => 'audio/bgm/${track.name}.mp3';
String sfxAssetPath(SfxId id) => 'audio/sfx/${id.name}.mp3';

/// 平A 命中音按出手单位固定变体：我方(teamSide 0)兵刃轻击系 / 敌方(1)重击系各 3。
/// 文件名即接线：`battleHit_<teamSide>_<slotIndex>.mp3`。越界 clamp 到既有 6 文件；
/// 拿不到出手者时调用方走 sfxAssetPath(SfxId.battleHit) 兜底(battleHit.mp3 与 0_1 同源)。
String battleHitAssetPath({required int teamSide, required int slotIndex}) {
  final side = teamSide.clamp(0, 1);
  final slot = slotIndex.clamp(0, 2);
  return 'audio/sfx/battleHit_${side}_$slot.mp3';
}
