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
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_floor_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_tower_participant_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<Character> insertCharacter({
    required String name,
    required bool founder,
    bool battleReady = true,
    bool alive = true,
    int? masterId,
    double injuryHoursRemaining = 0,
  }) async {
    final isar = IsarSetup.instance;
    final character =
        Character.create(
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
            isAlive: alive,
          )
          ..masterId = masterId
          ..injuryHoursRemaining = injuryHoursRemaining;
    await isar.writeTxn(() => isar.characters.put(character));
    if (battleReady) {
      final technique = Technique.create(
        defId: 'tech_gangmeng_jichu',
        ownerCharacterId: character.id,
        tier: TechniqueTier.values.first,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: DateTime.utc(2026, 8, 25),
      );
      await isar.writeTxn(() async {
        character.mainTechniqueId = await isar.techniques.put(technique);
        await isar.characters.put(character);
      });
    }
    return character;
  }

  Future<void> pointLeader(Character leader) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final save = (await isar.saveDatas.get(0))!;
      save.founderCharacterId = leader.id;
      save.activeCharacterIds = [leader.id];
      await isar.saveDatas.put(save);
    });
  }

  test('候选含当前掌门与非 active 门人，历史祖师/亡者排除并标记占用和主修', () async {
    final leader = await insertCharacter(name: '掌门', founder: true);
    await insertCharacter(name: '前代祖师', founder: true);
    final idleDisciple = await insertCharacter(
      name: '空闲门人',
      founder: false,
      masterId: leader.id,
    );
    final occupiedDisciple = await insertCharacter(
      name: '闭关门人',
      founder: false,
      masterId: leader.id,
    );
    final noMain = await insertCharacter(
      name: '未修门人',
      founder: false,
      battleReady: false,
      masterId: leader.id,
    );
    final healingDisciple = await insertCharacter(
      name: '疗伤门人',
      founder: false,
      masterId: leader.id,
      injuryHoursRemaining: 4,
    );
    await insertCharacter(
      name: '亡者',
      founder: false,
      alive: false,
      masterId: leader.id,
    );
    final previousGenerationDisciple = await insertCharacter(
      name: '前代门人',
      founder: false,
      masterId: 999999,
    );
    await pointLeader(leader);
    await IsarSetup.instance.writeTxn(() async {
      occupiedDisciple.currentRetreatSessionId = 88;
      await IsarSetup.instance.characters.put(occupiedDisciple);
    });

    final candidates = await loadTowerParticipantCandidates(
      isar: IsarSetup.instance,
    );
    final byId = {for (final value in candidates) value.character.id: value};
    expect(
      byId.keys,
      containsAll([leader.id, idleDisciple.id, occupiedDisciple.id, noMain.id]),
    );
    expect(
      candidates.where((value) => value.character.isFounder),
      hasLength(1),
    );
    expect(byId[idleDisciple.id]!.selectable, isTrue);
    expect(byId[occupiedDisciple.id]!.occupied, isTrue);
    expect(byId[occupiedDisciple.id]!.selectable, isFalse);
    expect(byId[noMain.id]!.hasMainTechnique, isFalse);
    expect(byId[noMain.id]!.selectable, isFalse);
    expect(byId[healingDisciple.id]!.healing, isTrue);
    expect(byId[healingDisciple.id]!.selectable, isFalse);
    expect(byId, isNot(contains(previousGenerationDisciple.id)));
  });

  test('非 active 门人装配为 exact snapshot；占用与悬空装备均拒绝且不回退掌门', () async {
    final leader = await insertCharacter(name: '掌门', founder: true);
    final disciple = await insertCharacter(
      name: '门人',
      founder: false,
      masterId: leader.id,
    );
    await pointLeader(leader);

    final snapshot = await resolveTowerParticipantSnapshot(
      isar: IsarSetup.instance,
      requestedParticipantId: disciple.id,
    );
    expect(snapshot.characterId, disciple.id);

    await IsarSetup.instance.writeTxn(() async {
      disciple.currentRetreatSessionId = 99;
      await IsarSetup.instance.characters.put(disciple);
    });
    await expectLater(
      resolveTowerParticipantSnapshot(
        isar: IsarSetup.instance,
        requestedParticipantId: disciple.id,
      ),
      throwsStateError,
    );
    await IsarSetup.instance.writeTxn(() async {
      disciple.currentRetreatSessionId = null;
      disciple.injuryHoursRemaining = 2;
      await IsarSetup.instance.characters.put(disciple);
    });
    await expectLater(
      resolveTowerParticipantSnapshot(
        isar: IsarSetup.instance,
        requestedParticipantId: disciple.id,
      ),
      throwsStateError,
    );
    await IsarSetup.instance.writeTxn(() async {
      disciple.injuryHoursRemaining = 0;
      disciple.equippedWeaponId = 999999;
      await IsarSetup.instance.characters.put(disciple);
    });
    await expectLater(
      resolveTowerParticipantSnapshot(
        isar: IsarSetup.instance,
        requestedParticipantId: disciple.id,
      ),
      throwsStateError,
    );
  });

  test('当前掌门指针悬空时候选与选择均 fail closed', () async {
    final disciple = await insertCharacter(name: '门人', founder: false);
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final save = (await isar.saveDatas.get(0))!;
      save.founderCharacterId = 999999;
      await isar.saveDatas.put(save);
    });
    await expectLater(
      loadTowerParticipantCandidates(isar: isar),
      throwsStateError,
    );
    await expectLater(
      resolveTowerParticipantSnapshot(
        isar: isar,
        requestedParticipantId: disciple.id,
      ),
      throwsStateError,
    );
  });

  testWidgets('选择器双视口展示禁用状态并返回实际门人 ID', (tester) async {
    final leader = Character.create(
      name: '闭关掌门',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime.utc(2026, 8, 25),
    )..id = 1;
    final disciple = Character.create(
      name: '空闲门人',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime.utc(2026, 8, 25),
    )..id = 2;
    final candidates = [
      TowerParticipantCandidate(
        character: leader,
        occupied: true,
        healing: false,
        hasMainTechnique: true,
      ),
      TowerParticipantCandidate(
        character: disciple,
        occupied: false,
        healing: false,
        hasMainTechnique: true,
      ),
    ];

    for (final viewport in const [Size(1280, 720), Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(viewport);
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await showTowerParticipantPicker(
                    context: context,
                    candidates: candidates,
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
      expect(find.text(UiStrings.towerParticipantTitle), findsOneWidget);
      expect(find.text(UiStrings.towerParticipantOccupied), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('tower_participant_1')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('空闲门人'));
      await tester.pumpAndSettle();
      expect(selected, 2);
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
