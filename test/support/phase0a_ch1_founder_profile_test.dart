import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';

import 'phase0a_ch1_founder_profile.dart';
import 'isar_test_support.dart';
import 'test_data.dart';

void main() {
  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  test('three production founder schools produce real Ch1 profiles', () async {
    for (final schoolId in ['gang_meng', 'ling_qiao', 'yin_rou']) {
      final dir = await Directory.systemTemp.createTemp('ch1_profile_');
      try {
        await IsarSetup.init(directory: dir, inspector: false);
        final profile = await seedPhase0aCh1FounderProfile(
          isar: IsarSetup.instance,
          schoolId: schoolId,
          originId: 'mountain_wanderer',
          fateId: 'clear_mind',
          rngSeed: 42,
        );
        final snapshot = profile.snapshot;
        expect(profile.profileId, '$schoolId/mountain_wanderer/clear_mind/42');
        expect(snapshot.characterId, 1);
        expect(snapshot.realmTier, RealmTier.xueTu);
        expect(snapshot.realmLayer, RealmLayer.qiMeng);
        expect(snapshot.skillLoadout.basicAttack, isNotNull);
        expect(snapshot.skillLoadout.main1, isNotNull);
        expect(
          snapshot.skillLoadout.main1!.type,
          SkillType.normalAttack,
          reason: 'Ch1 初窥解锁池当前只有主修 basic，autoFill 落 main1',
        );
        expect(snapshot.skillLoadout.ultimate, isNull);
        expect(snapshot.totalEquipmentAttack, greaterThan(0));
        final mapping = Phase0aStageContentMapper.map(
          stage: GameRepository.instance.getStage('stage_01_01'),
          playerSnapshot: snapshot,
          numbers: GameRepository.instance.numbers,
        );
        expect(
          mapping.numericSkillBindings.equipped,
          isEmpty,
          reason: '鼠标 basic 不得重复进入数字 1–6',
        );
      } finally {
        await IsarSetup.close();
        IsarSetup.resetForTest();
        await dir.delete(recursive: true);
      }
    }
  });

  test('duplicate option and duplicate seed fail fast', () async {
    final config = GameRepository.instance.founderCreation;
    expect(config.schools.where((e) => e.id == 'gang_meng'), hasLength(1));
    final dir = await Directory.systemTemp.createTemp('ch1_profile_');
    try {
      await IsarSetup.init(directory: dir, inspector: false);
      await seedPhase0aCh1FounderProfile(
        isar: IsarSetup.instance,
        schoolId: 'gang_meng',
        originId: 'mountain_wanderer',
        fateId: 'clear_mind',
        rngSeed: 1,
      );
      await expectLater(
        seedPhase0aCh1FounderProfile(
          isar: IsarSetup.instance,
          schoolId: 'gang_meng',
          originId: 'mountain_wanderer',
          fateId: 'clear_mind',
          rngSeed: 1,
        ),
        throwsStateError,
      );
      await expectLater(
        seedPhase0aCh1FounderProfile(
          isar: IsarSetup.instance,
          schoolId: 'missing',
          originId: 'mountain_wanderer',
          fateId: 'clear_mind',
          rngSeed: 1,
        ),
        throwsStateError,
      );
    } finally {
      await IsarSetup.close();
      IsarSetup.resetForTest();
      await dir.delete(recursive: true);
    }
  });
}
