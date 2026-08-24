import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_participation_policy.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_mainline_visible_replay_participant_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<Character> insertBattleReadyCharacter({
    required String name,
    required bool founder,
  }) async {
    final isar = IsarSetup.instance;
    final character = Character.create(
      name: name,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: founder ? LineageRole.founder : LineageRole.disciple,
      createdAt: DateTime.utc(2026, 8, 25),
      internalForce: 3000,
      school: TechniqueSchool.gangMeng,
      isFounder: founder,
      isAlive: true,
    );
    await isar.writeTxn(() => isar.characters.put(character));
    final technique = Technique.create(
      defId: 'tech_gangmeng_jichu',
      ownerCharacterId: character.id,
      tier: TechniqueTier.values.first,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime.utc(2026, 8, 25),
    );
    await isar.writeTxn(() async {
      final techniqueId = await isar.techniques.put(technique);
      character.mainTechniqueId = techniqueId;
      await isar.characters.put(character);
    });
    return character;
  }

  Future<(Character, Character)> seedTwoCharacters() async {
    final founder = await insertBattleReadyCharacter(
      name: '掌门甲',
      founder: true,
    );
    final disciple = await insertBattleReadyCharacter(
      name: '门人乙',
      founder: false,
    );
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final save = (await isar.saveDatas.get(0))!;
      save.activeCharacterIds = [founder.id, disciple.id];
      save.founderCharacterId = founder.id;
      await isar.saveDatas.put(save);
    });
    return (founder, disciple);
  }

  testWidgets('1280×720 与 1440×900 均可选择非掌门且无溢出', (tester) async {
    final founder = Character.create(
      name: '掌门甲',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime.utc(2026, 8, 25),
    )..id = 1;
    final disciple = Character.create(
      name: '门人乙',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime.utc(2026, 8, 25),
    )..id = 2;

    for (final size in const [Size(1280, 720), Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(size);
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await showMainlineVisibleReplayParticipantPicker(
                    context: context,
                    candidates: [founder, disciple],
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        find.text(UiStrings.mainlineReplayParticipantTitle),
        findsOneWidget,
      );
      expect(find.text('掌门甲'), findsOneWidget);
      expect(find.text('门人乙'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('门人乙'));
      await tester.pumpAndSettle();
      expect(selected, disciple.id);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  test('候选只含 active roster 中存活、有主修且空闲的角色', () async {
    final (founder, disciple) = await seedTwoCharacters();
    final isar = IsarSetup.instance;

    var candidates = await loadEligibleMainlineVisibleReplayParticipants(
      isar: isar,
    );
    expect(candidates.map((character) => character.id), [
      founder.id,
      disciple.id,
    ]);

    await isar.writeTxn(() async {
      disciple.currentRetreatSessionId = 88;
      await isar.characters.put(disciple);
    });
    candidates = await loadEligibleMainlineVisibleReplayParticipants(
      isar: isar,
    );
    expect(candidates.map((character) => character.id), [founder.id]);
  });

  test('可见重打选择门人后装配同一角色；占用时拒绝且不回退掌门', () async {
    final (founder, disciple) = await seedTwoCharacters();
    final isar = IsarSetup.instance;

    final snapshot = await resolveMainlineVisibleReplayParticipantSnapshot(
      isar: isar,
      stageId: 'stage_01_01',
      requestedParticipantId: disciple.id,
    );
    expect(snapshot.characterId, disciple.id);

    await isar.writeTxn(() async {
      disciple.currentRetreatSessionId = 99;
      await isar.characters.put(disciple);
    });
    expect(
      () => resolveMainlineVisibleReplayParticipantSnapshot(
        isar: isar,
        stageId: 'stage_01_01',
        requestedParticipantId: disciple.id,
      ),
      throwsA(isA<MainlineParticipationRefusedError>()),
    );
    expect(founder.id, isNot(disciple.id));
  });

  test('所选角色主修实体缺失时按参与政策拒绝，不泄漏装配异常或回退掌门', () async {
    final (founder, disciple) = await seedTwoCharacters();
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      disciple.mainTechniqueId = 999999;
      await isar.characters.put(disciple);
    });

    expect(
      () => resolveMainlineVisibleReplayParticipantSnapshot(
        isar: isar,
        stageId: 'stage_01_01',
        requestedParticipantId: disciple.id,
      ),
      throwsA(isA<MainlineParticipationRefusedError>()),
    );
    expect(founder.id, isNot(disciple.id));
  });

  test('当前领队指针失效时拒绝可见重打，不绕过领队迁移门禁', () async {
    final (_, disciple) = await seedTwoCharacters();
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final save = (await isar.saveDatas.get(0))!;
      save.founderCharacterId = 999999;
      await isar.saveDatas.put(save);
    });

    expect(
      () => resolveMainlineVisibleReplayParticipantSnapshot(
        isar: isar,
        stageId: 'stage_01_01',
        requestedParticipantId: disciple.id,
      ),
      throwsA(isA<MainlineParticipationRefusedError>()),
    );
  });
}
