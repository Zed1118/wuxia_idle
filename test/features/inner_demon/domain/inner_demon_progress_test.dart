import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_def.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_progress.dart';

void main() {
  // 7 关 fixture(stage_inner_demon_01..07 → wuSheng 各 layer)。
  InnerDemonDef defWith7() {
    const layers = RealmLayer.values;
    final req = <String, RealmCoord>{};
    for (var i = 0; i < 7; i++) {
      final n = (i + 1).toString().padLeft(2, '0');
      req['stage_inner_demon_$n'] =
          RealmCoord(tier: RealmTier.wuSheng, layer: layers[i]);
    }
    final base = InnerDemonDef.empty();
    return InnerDemonDef(
      mirrorBuffPerStage: base.mirrorBuffPerStage,
      mirrorCaps: base.mirrorCaps,
      failurePenalty: base.failurePenalty,
      residueDebuff: base.residueDebuff,
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
        'stage_06_05',
        'stage_inner_demon_01',
        'stage_inner_demon_02',
      },
    );
    expect(p.clearedCount, 2); // stage_06_05 不计入心魔关
    expect(p.totalCount, 7);
    expect(p.nextUnclearedStageId, 'stage_inner_demon_03');
  });

  test('全通 → 7/7,next = null', () {
    final cleared = {
      for (var i = 1; i <= 7; i++)
        'stage_inner_demon_${i.toString().padLeft(2, '0')}'
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
