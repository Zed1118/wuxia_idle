import 'audio_assets.dart';

/// 专属音频素材状态。
///
/// [temporaryBorrowed] 表示槽位已有可播放文件，但素材语义来自其他槽位的裁切/
/// 转用，不能当作最终专属素材验收。
enum DedicatedAudioAssetReadiness { finalAsset, temporaryBorrowed }

class DedicatedSfxAssetStatus {
  const DedicatedSfxAssetStatus({
    required this.slot,
    required this.readiness,
    required this.targetDurationMsRange,
    this.borrowedFrom,
  });

  final SfxId slot;
  final DedicatedAudioAssetReadiness readiness;
  final ({int min, int max}) targetDurationMsRange;
  final SfxId? borrowedFrom;

  bool get isFinalAsset => readiness == DedicatedAudioAssetReadiness.finalAsset;
}

/// 当前明确要求专属化的战斗 SFX 槽位。
///
/// 播放仍走 [sfxAssetPath] 的正式路径；这里仅提供状态识别，防止“文件存在”
/// 被误判为“最终专属素材已完成”。
const Map<SfxId, DedicatedSfxAssetStatus> dedicatedSfxAssetStatus = {
  SfxId.battleUlt: DedicatedSfxAssetStatus(
    slot: SfxId.battleUlt,
    readiness: DedicatedAudioAssetReadiness.temporaryBorrowed,
    borrowedFrom: SfxId.realmAdvance,
    targetDurationMsRange: (min: 800, max: 1600),
  ),
  SfxId.battleChargeStart: DedicatedSfxAssetStatus(
    slot: SfxId.battleChargeStart,
    readiness: DedicatedAudioAssetReadiness.temporaryBorrowed,
    borrowedFrom: SfxId.defeat,
    targetDurationMsRange: (min: 500, max: 1200),
  ),
};

DedicatedSfxAssetStatus? dedicatedSfxStatusFor(SfxId id) =>
    dedicatedSfxAssetStatus[id];
