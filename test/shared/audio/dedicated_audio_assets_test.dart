import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/audio/dedicated_audio_assets.dart';

void main() {
  test('battleUlt / battleChargeStart 当前仍标记为临时转用素材', () {
    final ult = dedicatedSfxStatusFor(SfxId.battleUlt);
    final charge = dedicatedSfxStatusFor(SfxId.battleChargeStart);

    expect(ult, isNotNull);
    expect(charge, isNotNull);
    expect(ult!.readiness, DedicatedAudioAssetReadiness.temporaryBorrowed);
    expect(charge!.readiness, DedicatedAudioAssetReadiness.temporaryBorrowed);
    expect(ult.borrowedFrom, SfxId.realmAdvance);
    expect(charge.borrowedFrom, SfxId.defeat);
  });

  test('专属槽位状态表只登记需要补齐的两个战斗槽位', () {
    expect(dedicatedSfxAssetStatus.keys, {
      SfxId.battleUlt,
      SfxId.battleChargeStart,
    });
  });

  test('目标时长约束符合音频生成计划', () {
    expect(dedicatedSfxStatusFor(SfxId.battleUlt)!.targetDurationMsRange, (
      min: 800,
      max: 1600,
    ));
    expect(
      dedicatedSfxStatusFor(SfxId.battleChargeStart)!.targetDurationMsRange,
      (min: 500, max: 1200),
    );
  });
}
