import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_def.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_progress.dart';

void main() {
  // 7 关 fixture(stage_inner_demon_01..07 → 当前学徒—三流节点)。
  InnerDemonDef defWith7() {
    const req = <String, RealmCoord>{
      'stage_inner_demon_01': RealmCoord(
        tier: RealmTier.xueTu,
        layer: RealmLayer.shuLian,
      ),
      'stage_inner_demon_02': RealmCoord(
        tier: RealmTier.xueTu,
        layer: RealmLayer.jingTong,
      ),
      'stage_inner_demon_03': RealmCoord(
        tier: RealmTier.xueTu,
        layer: RealmLayer.yuanShu,
      ),
      'stage_inner_demon_04': RealmCoord(
        tier: RealmTier.xueTu,
        layer: RealmLayer.huaJing,
      ),
      'stage_inner_demon_05': RealmCoord(
        tier: RealmTier.xueTu,
        layer: RealmLayer.dengFeng,
      ),
      'stage_inner_demon_06': RealmCoord(
        tier: RealmTier.sanLiu,
        layer: RealmLayer.qiMeng,
      ),
      'stage_inner_demon_07': RealmCoord(
        tier: RealmTier.sanLiu,
        layer: RealmLayer.ruMen,
      ),
    };
    final base = InnerDemonDef.empty();
    return InnerDemonDef(
      mirrorBuffPerStage: base.mirrorBuffPerStage,
      mirrorCaps: base.mirrorCaps,
      failurePenalty: base.failurePenalty,
      unlockTriggers: base.unlockTriggers,
      requiredRealmLayer: req,
    );
  }

  test('全未通 → 0/7,next = _01', () {
    final p = InnerDemonProgress.from(
      innerDemonDef: defWith7(),
      clearedStageIds: const {},
    );
    expect(p.clearedCount, 0);
    expect(p.totalCount, 7);
    expect(p.nextUnclearedStageId, 'stage_inner_demon_01');
  });

  test('部分通(_01,_02)→ 2/7,next = _03', () {
    final p = InnerDemonProgress.from(
      innerDemonDef: defWith7(),
      clearedStageIds: const {
        'stage_01_03',
        'stage_inner_demon_01',
        'stage_inner_demon_02',
      },
    );
    expect(p.clearedCount, 2); // stage_01_03 不计入心魔关
    expect(p.totalCount, 7);
    expect(p.nextUnclearedStageId, 'stage_inner_demon_03');
  });

  test('全通 → 7/7,next = null', () {
    final cleared = {
      for (var i = 1; i <= 7; i++)
        'stage_inner_demon_${i.toString().padLeft(2, '0')}',
    };
    final p = InnerDemonProgress.from(
      innerDemonDef: defWith7(),
      clearedStageIds: cleared,
    );
    expect(p.clearedCount, 7);
    expect(p.totalCount, 7);
    expect(p.nextUnclearedStageId, isNull);
  });

  test('空 def → 0/0,next null(不崩)', () {
    final p = InnerDemonProgress.from(
      innerDemonDef: InnerDemonDef.empty(),
      clearedStageIds: const {'stage_inner_demon_01'},
    );
    expect(p.totalCount, 0);
    expect(p.clearedCount, 0);
    expect(p.nextUnclearedStageId, isNull);
  });
}
