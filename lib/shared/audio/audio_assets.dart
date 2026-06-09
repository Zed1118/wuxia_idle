import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// BGM 轨道槽位。文件名用 enum.name（camelCase），manifest 同步登记。
enum BgmTrack { mainMenu, battle, seclusion }

/// SFX 槽位。battleDeath / reward 暂留位不接线（YAGNI）。
enum SfxId {
  uiTap,
  uiTabSwitch,
  uiPaperOpen,
  battleHit,
  battleCrit,
  battleUlt,
  battleDeath,
  reward,
}

String bgmAssetPath(BgmTrack track) => 'audio/bgm/${track.name}.mp3';
String sfxAssetPath(SfxId id) => 'audio/sfx/${id.name}.mp3';

/// 战斗动作 → SFX 纯映射。表现层用，不读/写 BattleState。
/// 优先级：大招 > 暴击 > 普通命中；闪避/无结果不出声。死亡 SFX v1 不做。
SfxId? sfxForAction({required BattleAction action, required bool isUltimate}) {
  final r = action.attackResult;
  if (r == null) return null;
  if (r.isDodged) return null;
  if (isUltimate) return SfxId.battleUlt;
  if (r.isCritical) return SfxId.battleCrit;
  return SfxId.battleHit;
}
