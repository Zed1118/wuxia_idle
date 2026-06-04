import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_def.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_panel.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_progress.dart';

void main() {
  InnerDemonDef defWith7() {
    const layers = RealmLayer.values;
    final req = <String, RealmCoord>{};
    for (var i = 0; i < 7; i++) {
      final n = (i + 1).toString().padLeft(2, '0');
      req['stage_inner_demon_$n'] =
          RealmCoord(tier: RealmTier.wuSheng, layer: layers[i]);
    }
    final b = InnerDemonDef.empty();
    return InnerDemonDef(
      mirrorBuffPerStage: b.mirrorBuffPerStage,
      mirrorCaps: b.mirrorCaps,
      failurePenalty: b.failurePenalty,
      residueDebuff: b.residueDebuff,
      unlockTriggers: b.unlockTriggers,
      requiredRealmLayer: req,
    );
  }

  Character ch({
    required RealmTier tier,
    RealmLayer layer = RealmLayer.shuLian,
    int experience = 0,
    int experienceToNextLayer = 100,
  }) {
    final c = Character.create(
      name: 't',
      realmTier: tier,
      realmLayer: layer,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 6, 4),
      internalForce: 100,
      internalForceMax: 500,
      school: TechniqueSchool.gangMeng,
    )..id = 1;
    c.experience = experience;
    c.experienceToNextLayer = experienceToNextLayer;
    return c;
  }

  InnerDemonProgress prog(Set<String> cleared) => InnerDemonProgress.from(
        innerDemonDef: defWith7(),
        clearedStageIds: cleared,
      );

  test('非武圣 → null(shrink)', () {
    final r = resolveInnerDemonPanel(
      character: ch(tier: RealmTier.yiLiu),
      progress: prog(const {}),
      innerDemonDef: defWith7(),
    );
    expect(r, isNull);
  });

  test('武圣全通 → cleared 7/7', () {
    final cleared = {
      for (var i = 1; i <= 7; i++)
        'stage_inner_demon_${i.toString().padLeft(2, '0')}'
    };
    final r = resolveInnerDemonPanel(
      character: ch(tier: RealmTier.wuSheng, layer: RealmLayer.dengFeng),
      progress: prog(cleared),
      innerDemonDef: defWith7(),
    )!;
    expect(r.state, InnerDemonPanelState.cleared);
    expect(r.clearedCount, 7);
    expect(r.totalCount, 7);
  });

  test('武圣 exp满 + 拦截 → blocked,blockingStageId 对应当前 layer', () {
    final r = resolveInnerDemonPanel(
      character: ch(
        tier: RealmTier.wuSheng,
        layer: RealmLayer.shuLian,
        experience: 100,
        experienceToNextLayer: 100,
      ),
      progress: prog(const {'stage_inner_demon_01', 'stage_inner_demon_02'}),
      innerDemonDef: defWith7(),
    )!;
    expect(r.state, InnerDemonPanelState.blocked);
    expect(r.blockingStageId, 'stage_inner_demon_03');
    expect(r.clearedCount, 2);
  });

  test('武圣 exp未满 → inProgress,nextStageId = 首个未通', () {
    final r = resolveInnerDemonPanel(
      character: ch(
        tier: RealmTier.wuSheng,
        layer: RealmLayer.shuLian,
        experience: 10,
        experienceToNextLayer: 100,
      ),
      progress: prog(const {'stage_inner_demon_01'}),
      innerDemonDef: defWith7(),
    )!;
    expect(r.state, InnerDemonPanelState.inProgress);
    expect(r.nextStageId, 'stage_inner_demon_02');
  });

  test('武圣但空心魔配置(total 0)→ null(不显空面板)', () {
    final empty = InnerDemonProgress.from(
      innerDemonDef: InnerDemonDef.empty(),
      clearedStageIds: const {},
    );
    final r = resolveInnerDemonPanel(
      character: ch(
        tier: RealmTier.wuSheng,
        layer: RealmLayer.shuLian,
        experience: 100,
        experienceToNextLayer: 100,
      ),
      progress: empty,
      innerDemonDef: InnerDemonDef.empty(),
    );
    expect(r, isNull);
  });
}
