import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/dispel/application/dispel_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

class _DispelFixture {
  const _DispelFixture({
    required this.character,
    required this.mainTechnique,
    required this.newMainTechnique,
  });

  final Character character;
  final Technique mainTechnique;
  final Technique newMainTechnique;
}

class _PersistedDispelState {
  const _PersistedDispelState({
    required this.internalForce,
    required this.innerBreathDisorderHoursRemaining,
    required this.mainTechniqueId,
    required this.assistTechniqueIds,
    required this.mainOwnerCharacterId,
    required this.mainRole,
    required this.mainLayer,
    required this.mainProgress,
    required this.mainProgressToNext,
    required this.mainWasMainBeforeReset,
    required this.newMainOwnerCharacterId,
    required this.newMainRole,
    required this.newMainLayer,
    required this.newMainProgress,
    required this.newMainProgressToNext,
    required this.newMainWasMainBeforeReset,
  });

  final int internalForce;
  final double innerBreathDisorderHoursRemaining;
  final int? mainTechniqueId;
  final List<int> assistTechniqueIds;
  final int mainOwnerCharacterId;
  final TechniqueRole mainRole;
  final CultivationLayer mainLayer;
  final int mainProgress;
  final int mainProgressToNext;
  final bool mainWasMainBeforeReset;
  final int newMainOwnerCharacterId;
  final TechniqueRole newMainRole;
  final CultivationLayer newMainLayer;
  final int newMainProgress;
  final int newMainProgressToNext;
  final bool newMainWasMainBeforeReset;
}

Future<_DispelFixture> _seedDispelFixture(Isar isar) async {
  final character = Character.create(
    name: '事务守卫测试者',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 5,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.disciple,
    createdAt: DateTime(2026, 8, 24),
    internalForce: 10000,
    internalForceMax: 15000,
    school: TechniqueSchool.gangMeng,
  );
  final mainTechnique = Technique.create(
    defId: 'tech_guard_main',
    ownerCharacterId: 0,
    tier: TechniqueTier.ruMenGong,
    school: TechniqueSchool.gangMeng,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 8, 24),
    cultivationLayer: CultivationLayer.yuanMan,
    cultivationProgress: 1500,
    cultivationProgressToNext: 2000,
  );
  final newMainTechnique = Technique.create(
    defId: 'tech_guard_assist',
    ownerCharacterId: 0,
    tier: TechniqueTier.ruMenGong,
    school: TechniqueSchool.gangMeng,
    role: TechniqueRole.assist,
    learnedAt: DateTime(2026, 8, 24),
    cultivationLayer: CultivationLayer.chuKui,
    cultivationProgress: 0,
    cultivationProgressToNext: 100,
  );

  await isar.writeTxn(() async {
    await isar.characters.put(character);
    await isar.techniques.put(mainTechnique);
    await isar.techniques.put(newMainTechnique);
  });
  mainTechnique.ownerCharacterId = character.id;
  newMainTechnique.ownerCharacterId = character.id;
  character.mainTechniqueId = mainTechnique.id;
  character.assistTechniqueIds = [newMainTechnique.id];
  await isar.writeTxn(() async {
    await isar.characters.put(character);
    await isar.techniques.put(mainTechnique);
    await isar.techniques.put(newMainTechnique);
  });

  return _DispelFixture(
    character: character,
    mainTechnique: mainTechnique,
    newMainTechnique: newMainTechnique,
  );
}

Future<_PersistedDispelState> _readPersistedState(
  Isar isar,
  _DispelFixture fixture,
) async {
  final character = (await isar.characters.get(fixture.character.id))!;
  final mainTechnique = (await isar.techniques.get(fixture.mainTechnique.id))!;
  final newMainTechnique = (await isar.techniques.get(
    fixture.newMainTechnique.id,
  ))!;
  return _PersistedDispelState(
    internalForce: character.internalForce,
    innerBreathDisorderHoursRemaining:
        character.innerBreathDisorderHoursRemaining,
    mainTechniqueId: character.mainTechniqueId,
    assistTechniqueIds: List<int>.from(character.assistTechniqueIds),
    mainOwnerCharacterId: mainTechnique.ownerCharacterId,
    mainRole: mainTechnique.role,
    mainLayer: mainTechnique.cultivationLayer,
    mainProgress: mainTechnique.cultivationProgress,
    mainProgressToNext: mainTechnique.cultivationProgressToNext,
    mainWasMainBeforeReset: mainTechnique.wasMainBeforeReset,
    newMainOwnerCharacterId: newMainTechnique.ownerCharacterId,
    newMainRole: newMainTechnique.role,
    newMainLayer: newMainTechnique.cultivationLayer,
    newMainProgress: newMainTechnique.cultivationProgress,
    newMainProgressToNext: newMainTechnique.cultivationProgressToNext,
    newMainWasMainBeforeReset: newMainTechnique.wasMainBeforeReset,
  );
}

void _expectPersistedStateEquals(
  _PersistedDispelState actual,
  _PersistedDispelState expected,
) {
  expect(actual.internalForce, expected.internalForce);
  expect(
    actual.innerBreathDisorderHoursRemaining,
    expected.innerBreathDisorderHoursRemaining,
  );
  expect(actual.mainTechniqueId, expected.mainTechniqueId);
  expect(actual.assistTechniqueIds, orderedEquals(expected.assistTechniqueIds));
  expect(actual.mainOwnerCharacterId, expected.mainOwnerCharacterId);
  expect(actual.mainRole, expected.mainRole);
  expect(actual.mainLayer, expected.mainLayer);
  expect(actual.mainProgress, expected.mainProgress);
  expect(actual.mainProgressToNext, expected.mainProgressToNext);
  expect(actual.mainWasMainBeforeReset, expected.mainWasMainBeforeReset);
  expect(actual.newMainOwnerCharacterId, expected.newMainOwnerCharacterId);
  expect(actual.newMainRole, expected.newMainRole);
  expect(actual.newMainLayer, expected.newMainLayer);
  expect(actual.newMainProgress, expected.newMainProgress);
  expect(actual.newMainProgressToNext, expected.newMainProgressToNext);
  expect(actual.newMainWasMainBeforeReset, expected.newMainWasMainBeforeReset);
}

/// T32 #22b DispelService.dispelAndPersist 真 Isar 落地测试。
///
/// 测点：dispel 后 putAll 3 个对象（ch / 旧 mainTech / 新 mainTech），关闭再读
/// 字段全部一致：
/// - ch.internalForce -50% / mainTechniqueId 切到新主修
/// - oldMain.role=assist + cultivationProgress ×0.5 + layer 回退
/// - newMain.role=main
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_dispel_persist_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('dispelAndPersist → 关闭再读，3 个对象字段全部落地', () async {
    final isar = IsarSetup.instance;

    final ch = Character.create(
      name: '测试者',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 5, 11),
      internalForce: 10000,
      internalForceMax: 15000,
      school: TechniqueSchool.gangMeng,
    );
    final mainTech = Technique.create(
      defId: 'tech_main',
      ownerCharacterId: 0,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 5, 11),
      cultivationLayer: CultivationLayer.yuanMan,
      cultivationProgress: 1500,
      cultivationProgressToNext: 2000,
    );
    final assistTech = Technique.create(
      defId: 'tech_assist',
      ownerCharacterId: 0,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.assist,
      learnedAt: DateTime(2026, 5, 11),
      cultivationLayer: CultivationLayer.chuKui,
      cultivationProgress: 0,
      cultivationProgressToNext: 100,
    );

    // 先 put 拿到 id，再回填 ownerCharacterId + mainTechniqueId/assistTechniqueIds
    await isar.writeTxn(() async {
      await isar.characters.put(ch);
      await isar.techniques.put(mainTech);
      await isar.techniques.put(assistTech);
    });
    mainTech.ownerCharacterId = ch.id;
    assistTech.ownerCharacterId = ch.id;
    ch.mainTechniqueId = mainTech.id;
    ch.assistTechniqueIds = [assistTech.id];
    await isar.writeTxn(() async {
      await isar.characters.put(ch);
      await isar.techniques.put(mainTech);
      await isar.techniques.put(assistTech);
    });

    final ifBefore = ch.internalForce;
    final progressBefore = mainTech.cultivationProgress;

    final result = await DispelService(isar: IsarSetup.instance)
        .dispelAndPersist(
          characterId: ch.id,
          expectedMainTechniqueId: mainTech.id,
          newMainTechniqueId: assistTech.id,
          n: GameRepository.instance.numbers,
        );
    expect(result.success, isTrue);

    // 关闭再读，验证落盘
    final chId = ch.id;
    final mainId = mainTech.id;
    final assistId = assistTech.id;
    await IsarSetup.close();
    await IsarSetup.init(directory: tempDir, inspector: false);
    final isar2 = IsarSetup.instance;

    final chBack = await isar2.characters.get(chId);
    expect(chBack, isNotNull);
    expect(chBack!.internalForce, ifBefore, reason: '散功不再永久扣内力');
    expect(
      chBack.innerBreathDisorderHoursRemaining,
      greaterThan(0),
      reason: '内息紊乱应落盘',
    );
    expect(chBack.mainTechniqueId, assistId, reason: 'mainTechniqueId 应切到新主修');
    expect(chBack.assistTechniqueIds, contains(mainId), reason: '旧主修挪入辅修');
    expect(
      chBack.assistTechniqueIds,
      isNot(contains(assistId)),
      reason: '新主修不再在辅修槽',
    );

    final mainBack = await isar2.techniques.get(mainId);
    expect(mainBack, isNotNull);
    expect(mainBack!.role, TechniqueRole.assist, reason: '旧主修 role=assist 应落盘');
    expect(
      mainBack.cultivationProgress,
      progressBefore ~/ 2,
      reason: 'progress ×0.5 应落盘',
    );

    final newMainBack = await isar2.techniques.get(assistId);
    expect(newMainBack, isNotNull);
    expect(newMainBack!.role, TechniqueRole.main, reason: '新主修 role=main 应落盘');
  });

  group('活动占用契约守卫（07-22 #58 Gate 发现补接）', () {
    Character occChar(int id, {int? retreatSessionId}) {
      final c = Character.create(
        name: '门人$id',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026, 7, 16),
      );
      c.id = id;
      c.currentRetreatSessionId = retreatSessionId;
      return c;
    }

    test('闭关/远征/断魂庄在途 → 占用；无活动 → 不占用', () async {
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        await isar.characters.put(occChar(1));
        await isar.characters.put(occChar(2, retreatSessionId: 7));
      });
      final svc = DispelService(isar: isar);

      expect(await svc.isCharacterOccupied(1), isFalse, reason: '无活动');
      expect(await svc.isCharacterOccupied(2), isTrue, reason: '闭关在途');

      // 闭关解除 → 改远征在途（run 成员快照占用）。
      await isar.writeTxn(() async {
        final ch = (await isar.characters.get(2))!
          ..currentRetreatSessionId = null;
        await isar.characters.put(ch);
        await isar.expeditionRuns.put(
          ExpeditionRun()
            ..saveDataId = 0
            ..policy = ExpeditionPolicy.yiZhanLiXing
            ..seed = 1
            ..departedAt = DateTime(2026, 7, 16)
            ..members = [
              ActivityMemberSnapshot()
                ..characterId = 1
                ..reservedEquipmentIds = []
                ..reservedTechniqueIds = []
                ..currentHp = 100
                ..currentQi = 50
                ..isDowned = false,
            ]
            ..stagedRewards = [],
        );
      });
      expect(await svc.isCharacterOccupied(2), isFalse, reason: '闭关已解除');
      expect(await svc.isCharacterOccupied(1), isTrue, reason: '远征在途');
    });
  });

  group('dispelAndPersist 权威事务守卫', () {
    Future<void> expectOccupiedThenReleased({
      required Future<int?> Function(Isar isar, _DispelFixture fixture) occupy,
      required Future<void> Function(Isar isar, int? activityId) release,
      required DispelOutcome expectedOccupiedOutcome,
    }) async {
      var isar = IsarSetup.instance;
      final fixture = await _seedDispelFixture(isar);
      final before = await _readPersistedState(isar, fixture);
      final activityId = await occupy(isar, fixture);

      final service = DispelService(isar: isar);
      final rejected = await service.dispelAndPersist(
        characterId: fixture.character.id,
        expectedMainTechniqueId: fixture.mainTechnique.id,
        newMainTechniqueId: fixture.newMainTechnique.id,
        n: GameRepository.instance.numbers,
      );
      expect(rejected.outcome, expectedOccupiedOutcome);

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      isar = IsarSetup.instance;
      _expectPersistedStateEquals(
        await _readPersistedState(isar, fixture),
        before,
      );

      await release(isar, activityId);
      final succeeded = await DispelService(isar: isar).dispelAndPersist(
        characterId: fixture.character.id,
        expectedMainTechniqueId: fixture.mainTechnique.id,
        newMainTechniqueId: fixture.newMainTechnique.id,
        n: GameRepository.instance.numbers,
      );
      expect(succeeded.outcome, DispelOutcome.success);

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      final after = await _readPersistedState(IsarSetup.instance, fixture);
      expect(after.internalForce, before.internalForce);
      expect(after.innerBreathDisorderHoursRemaining, greaterThan(0));
      expect(after.mainTechniqueId, fixture.newMainTechnique.id);
      expect(after.assistTechniqueIds, contains(fixture.mainTechnique.id));
      expect(
        after.assistTechniqueIds,
        isNot(contains(fixture.newMainTechnique.id)),
      );
      expect(after.mainRole, TechniqueRole.assist);
      expect(after.mainProgress, before.mainProgress ~/ 2);
      expect(after.newMainRole, TechniqueRole.main);

      final repeated = await DispelService(isar: IsarSetup.instance)
          .dispelAndPersist(
            characterId: fixture.character.id,
            expectedMainTechniqueId: fixture.mainTechnique.id,
            newMainTechniqueId: fixture.newMainTechnique.id,
            n: GameRepository.instance.numbers,
          );
      expect(repeated.outcome, DispelOutcome.canonicalStateChanged);

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      _expectPersistedStateEquals(
        await _readPersistedState(IsarSetup.instance, fixture),
        after,
      );
    }

    test('闭关占用拒绝且三对象零写；收功后同一操作成功', () async {
      await expectOccupiedThenReleased(
        occupy: (isar, fixture) async {
          await isar.writeTxn(() async {
            final canonical = (await isar.characters.get(fixture.character.id))!
              ..currentRetreatSessionId = 7;
            await isar.characters.put(canonical);
          });
          return fixture.character.id;
        },
        release: (isar, characterId) async {
          await isar.writeTxn(() async {
            final canonical = (await isar.characters.get(characterId!))!
              ..currentRetreatSessionId = null;
            await isar.characters.put(canonical);
          });
        },
        expectedOccupiedOutcome: DispelOutcome.characterOccupied,
      );
    });

    test('远征占用拒绝且三对象零写；返程后同一操作成功', () async {
      await expectOccupiedThenReleased(
        occupy: (isar, fixture) async {
          return isar.writeTxn(() async {
            return isar.expeditionRuns.put(
              ExpeditionRun()
                ..saveDataId = 0
                ..policy = ExpeditionPolicy.yiZhanLiXing
                ..seed = 1
                ..departedAt = DateTime(2026, 8, 24)
                ..members = [
                  ActivityMemberSnapshot()
                    ..characterId = fixture.character.id
                    ..reservedTechniqueIds = [
                      fixture.mainTechnique.id,
                      fixture.newMainTechnique.id,
                    ],
                ]
                ..stagedRewards = [],
            );
          });
        },
        release: (isar, activityId) async {
          await isar.writeTxn(() => isar.expeditionRuns.delete(activityId!));
        },
        expectedOccupiedOutcome: DispelOutcome.characterOccupied,
      );
    });

    test('断魂庄占用拒绝且三对象零写；会话结束后同一操作成功', () async {
      await expectOccupiedThenReleased(
        occupy: (isar, fixture) async {
          return isar.writeTxn(() async {
            return isar.bossGauntletRuns.put(
              BossGauntletRun()
                ..saveDataId = 0
                ..seed = 1
                ..members = [
                  ActivityMemberSnapshot()
                    ..characterId = fixture.character.id
                    ..reservedTechniqueIds = [
                      fixture.mainTechnique.id,
                      fixture.newMainTechnique.id,
                    ],
                ],
            );
          });
        },
        release: (isar, activityId) async {
          await isar.writeTxn(() => isar.bossGauntletRuns.delete(activityId!));
        },
        expectedOccupiedOutcome: DispelOutcome.characterOccupied,
      );
    });

    test('其他角色被活动占用不误锁目标角色', () async {
      final isar = IsarSetup.instance;
      final fixture = await _seedDispelFixture(isar);
      await isar.writeTxn(() async {
        await isar.characters.put(
          Character.create(
            name: '闭关中的其他门人',
            realmTier: RealmTier.xueTu,
            realmLayer: RealmLayer.qiMeng,
            attributes: Attributes(),
            rarity: RarityTier.biaoZhun,
            lineageRole: LineageRole.disciple,
            createdAt: DateTime(2026, 8, 24),
          )..currentRetreatSessionId = 9,
        );
      });

      final result = await DispelService(isar: isar).dispelAndPersist(
        characterId: fixture.character.id,
        expectedMainTechniqueId: fixture.mainTechnique.id,
        newMainTechniqueId: fixture.newMainTechnique.id,
        n: GameRepository.instance.numbers,
      );
      expect(result.outcome, DispelOutcome.success);
    });

    test('主修指针在预检后变化 → stale 且三对象零写', () async {
      final isar = IsarSetup.instance;
      final fixture = await _seedDispelFixture(isar);
      await isar.writeTxn(() async {
        final canonical = (await isar.characters.get(fixture.character.id))!
          ..mainTechniqueId = fixture.newMainTechnique.id;
        await isar.characters.put(canonical);
      });
      final before = await _readPersistedState(isar, fixture);

      final result = await DispelService(isar: isar).dispelAndPersist(
        characterId: fixture.character.id,
        expectedMainTechniqueId: fixture.mainTechnique.id,
        newMainTechniqueId: fixture.newMainTechnique.id,
        n: GameRepository.instance.numbers,
      );
      expect(result.outcome, DispelOutcome.canonicalStateChanged);
      _expectPersistedStateEquals(
        await _readPersistedState(isar, fixture),
        before,
      );
    });

    test('旧主修 owner/role 在预检后变化 → stale 且三对象零写', () async {
      final isar = IsarSetup.instance;
      final fixture = await _seedDispelFixture(isar);
      await isar.writeTxn(() async {
        final canonical = (await isar.techniques.get(fixture.mainTechnique.id))!
          ..ownerCharacterId = fixture.character.id + 1
          ..role = TechniqueRole.assist;
        await isar.techniques.put(canonical);
      });
      final before = await _readPersistedState(isar, fixture);

      final result = await DispelService(isar: isar).dispelAndPersist(
        characterId: fixture.character.id,
        expectedMainTechniqueId: fixture.mainTechnique.id,
        newMainTechniqueId: fixture.newMainTechnique.id,
        n: GameRepository.instance.numbers,
      );
      expect(result.outcome, DispelOutcome.canonicalStateChanged);
      _expectPersistedStateEquals(
        await _readPersistedState(isar, fixture),
        before,
      );
    });

    test('候选 owner/role/辅修槽在预检后变化 → stale 且三对象零写', () async {
      final isar = IsarSetup.instance;
      final fixture = await _seedDispelFixture(isar);
      await isar.writeTxn(() async {
        final character = (await isar.characters.get(fixture.character.id))!
          ..assistTechniqueIds = [];
        final candidate =
            (await isar.techniques.get(fixture.newMainTechnique.id))!
              ..ownerCharacterId = fixture.character.id + 1
              ..role = TechniqueRole.main;
        await isar.characters.put(character);
        await isar.techniques.put(candidate);
      });
      final before = await _readPersistedState(isar, fixture);

      final result = await DispelService(isar: isar).dispelAndPersist(
        characterId: fixture.character.id,
        expectedMainTechniqueId: fixture.mainTechnique.id,
        newMainTechniqueId: fixture.newMainTechnique.id,
        n: GameRepository.instance.numbers,
      );
      expect(result.outcome, DispelOutcome.canonicalStateChanged);
      _expectPersistedStateEquals(
        await _readPersistedState(isar, fixture),
        before,
      );
    });

    test('角色/旧主修/候选任一缺失 → stale 且不补写缺失对象', () async {
      for (final missing in ['character', 'main', 'candidate']) {
        if (missing != 'character') {
          await IsarSetup.close();
          await IsarSetup.init(directory: tempDir, inspector: false);
        }
        final isar = IsarSetup.instance;
        final fixture = await _seedDispelFixture(isar);
        await isar.writeTxn(() async {
          switch (missing) {
            case 'character':
              await isar.characters.delete(fixture.character.id);
            case 'main':
              await isar.techniques.delete(fixture.mainTechnique.id);
            case 'candidate':
              await isar.techniques.delete(fixture.newMainTechnique.id);
          }
        });

        final result = await DispelService(isar: isar).dispelAndPersist(
          characterId: fixture.character.id,
          expectedMainTechniqueId: fixture.mainTechnique.id,
          newMainTechniqueId: fixture.newMainTechnique.id,
          n: GameRepository.instance.numbers,
        );
        expect(
          result.outcome,
          DispelOutcome.canonicalStateChanged,
          reason: missing,
        );
        expect(
          await isar.characters.get(fixture.character.id),
          missing == 'character' ? isNull : isNotNull,
        );
        expect(
          await isar.techniques.get(fixture.mainTechnique.id),
          missing == 'main' ? isNull : isNotNull,
        );
        expect(
          await isar.techniques.get(fixture.newMainTechnique.id),
          missing == 'candidate' ? isNull : isNotNull,
        );
      }
    });
  });
}
