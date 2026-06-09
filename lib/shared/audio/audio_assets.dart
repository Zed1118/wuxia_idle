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
