import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_entry_flow.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/shared/utils/rng_provider.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory directory;
  late Isar isar;
  late GameRepository repo;
  final startedAt = DateTime(2026, 9, 10, 8);
  final now = startedAt.add(const Duration(hours: 8, minutes: 6));
  const expFractionBefore = 0.4;
  const materialFractionBefore = 0.2;

  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await loadTestGameRepository();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('combat_passive_');
    await IsarSetup.init(directory: directory, inspector: false);
    isar = IsarSetup.instance;
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  Future<WidgetRef> mountRef(WidgetTester tester) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rngProvider.overrideWithValue(DefaultRng(seed: 7))],
        child: MaterialApp(
          home: Consumer(
            builder: (_, ref, _) {
              captured = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  Future<int> seed({
    RealmLayer layer = RealmLayer.dengFeng,
    required int experience,
    bool unlockTier = true,
    double heavyHours = 0,
  }) => isar.writeTxn(() async {
    final character =
        Character.create(
            name: '掌门',
            realmTier: RealmTier.xueTu,
            realmLayer: layer,
            attributes: Attributes(),
            rarity: RarityTier.biaoZhun,
            lineageRole: LineageRole.founder,
            isFounder: true,
            createdAt: startedAt.subtract(const Duration(days: 1)),
            internalForce: 100,
          )
          ..experience = experience
          ..passiveExperienceRemainder = expFractionBefore
          ..injuryHoursRemaining = heavyHours
          ..lightInjuryStacks = heavyHours > 0 ? 2 : 0;
    final id = await isar.characters.put(character);
    final save = (await isar.saveDatas.get(0))!;
    save
      ..founderCharacterId = id
      ..activeCharacterIds = [id]
      ..createdAt = character.createdAt
      ..lastOnlineAt = startedAt
      ..passiveLastSettledAt = startedAt
      ..passiveMojianshiRemainder = materialFractionBefore;
    await isar.saveDatas.put(save);
    final cleared = <String>[
      for (var i = 1; i <= (unlockTier ? 5 : 4); i++) 'stage_inner_demon_0$i',
    ];
    if (layer == RealmLayer.shuLian) cleared.clear();
    await isar.mainlineProgress.put(
      MainlineProgress()
        ..saveDataId = IsarSetup.currentSlotId
        ..clearedStageIds = cleared
        ..clearedAt = [for (final _ in cleared) startedAt],
    );
    return id;
  });

  CombatSettlementSnapshot snapshot(int id, {bool won = true}) =>
      CombatSettlementSnapshot(
        result: won ? BattleResult.leftWin : BattleResult.rightWin,
        totalTicks: 10,
        hadActions: true,
        playerCharacterId: id,
        participants: [
          CombatParticipantSnapshot(
            characterId: id,
            currentHp: won ? 100 : 0,
            maxHp: 100,
          ),
        ],
        skillCasts: const [],
        totalDamage: 100,
        criticalCount: 0,
        damageByCharacterId: {id: 100},
      );

  StageDef stage({
    String id = 'stage_passive_boundary',
    int experience = 20,
    StageType type = StageType.mainline,
    bool boss = false,
  }) => StageDef(
    id: id,
    name: '边界关卡',
    stageType: type,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: const [],
    isBossStage: boss,
    baseExpReward: experience,
    difficultyMultiplier: 1,
  );

  double getExpectedExperience() =>
      repo.numbers.passiveIdle.baseExpPerHour * 8.1 + expFractionBefore;

  Future<void> expectPassiveLedger(int id) async {
    final character = (await isar.characters.get(id))!;
    final save = (await isar.saveDatas.get(0))!;
    final exactExp = getExpectedExperience();
    final exactMaterial =
        repo.numbers.passiveIdle.baseMojianshiPerHour * 8.1 +
        materialFractionBefore;
    expect(save.totalPassiveExperience, exactExp.floor());
    expect(save.totalPassiveMojianshi, exactMaterial.floor());
    expect(
      character.passiveExperienceRemainder,
      closeTo(exactExp - exactExp.floor(), 1e-8),
    );
    expect(
      save.passiveMojianshiRemainder,
      closeTo(exactMaterial - exactMaterial.floor(), 1e-8),
    );
    expect(save.passiveLastSettledAt, now);
    expect(save.lastOnlineAt, now);
  }

  testWidgets(
    'mainline commits old-rate passive EXP and fractions before battle advancement',
    (tester) async {
      final ref = await mountRef(tester);
      await tester.runAsync(() async {
        final threshold = repo
            .getRealm(RealmTier.xueTu, RealmLayer.dengFeng)
            .experienceToNext;
        final passiveExp = getExpectedExperience().floor();
        final before = threshold - passiveExp - 6;
        final id = await seed(experience: before);
        final battle = snapshot(id);

        await expectLater(
          applyVictoryResolution(
            ref: ref,
            stage: stage(),
            settlementSnapshot: battle,
            expectedParticipantId: id,
            rewardOccurrenceId: 'mainline-boundary',
            settlementAt: now,
            afterRewardWritesInTxnForTest: () async =>
                throw StateError('rollback'),
          ),
          throwsStateError,
        );
        expect((await isar.characters.get(id))!.experience, before);
        expect((await isar.saveDatas.get(0))!.passiveLastSettledAt, startedAt);
        expect((await isar.saveDatas.get(0))!.totalPassiveExperience, 0);

        final result = await applyVictoryResolution(
          ref: ref,
          stage: stage(),
          settlementSnapshot: battle,
          expectedParticipantId: id,
          rewardOccurrenceId: 'mainline-boundary',
          settlementAt: now,
        );
        expect(result, isNotNull);
        final character = (await isar.characters.get(id))!;
        expect(character.realmTier, RealmTier.sanLiu);
        expect(character.experience, 14);
        await expectPassiveLedger(id);
        expect(
          await applyVictoryResolution(
            ref: ref,
            stage: stage(),
            settlementSnapshot: battle,
            expectedParticipantId: id,
            rewardOccurrenceId: 'mainline-boundary',
            settlementAt: now,
          ),
          isNull,
        );
        await OfflinePassiveService.settleWindow(isar: isar, now: now);
        expect((await isar.characters.get(id))!.experience, 14);
        await expectPassiveLedger(id);
      });
    },
  );

  testWidgets(
    'inner demon clear cannot retroactively unlock the elapsed passive window',
    (tester) async {
      final ref = await mountRef(tester);
      await tester.runAsync(() async {
        final threshold = repo
            .getRealm(RealmTier.xueTu, RealmLayer.dengFeng)
            .experienceToNext;
        final id = await seed(experience: threshold - 1, unlockTier: false);
        await applyVictoryResolution(
          ref: ref,
          stage: stage(
            id: 'stage_inner_demon_05',
            experience: 0,
            type: StageType.innerDemon,
          ),
          settlementSnapshot: snapshot(id),
          expectedParticipantId: id,
          rewardOccurrenceId: 'lock-boundary',
          settlementAt: now,
        );
        final character = (await isar.characters.get(id))!;
        expect(character.realmTier, RealmTier.xueTu);
        expect(character.realmLayer, RealmLayer.dengFeng);
        expect(
          character.experience,
          threshold - 1 + getExpectedExperience().floor(),
        );
        expect(
          (await isar.mainlineProgress.where().findFirst())!.clearedStageIds,
          contains('stage_inner_demon_05'),
        );
        await expectPassiveLedger(id);
        await OfflinePassiveService.settleWindow(isar: isar, now: now);
        expect((await isar.characters.get(id))!.realmTier, RealmTier.xueTu);
        await expectPassiveLedger(id);
      });
    },
  );

  testWidgets(
    'mainline defeat preserves passive rewards and starts new injury time at settlement',
    (tester) async {
      final ref = await mountRef(tester);
      await tester.runAsync(() async {
        final id = await seed(experience: 0, heavyHours: 2);
        await applyParticipantDefeatResolution(
          ref: ref,
          stage: stage(boss: true),
          settlementSnapshot: snapshot(id, won: false),
          expectedParticipantId: id,
          settlementAt: now,
        );
        final character = (await isar.characters.get(id))!;
        expect(character.experience, getExpectedExperience().floor());
        expect(character.injuryHoursRemaining, greaterThan(2));
        expect(character.lightInjuryStacks, greaterThanOrEqualTo(2));
        await expectPassiveLedger(id);
      });
    },
  );

  for (final victoryClaim in [false, true]) {
    testWidgets(
      'tower ${victoryClaim ? 'victory claim' : 'direct defeat'} keeps passive ledger within the character write transaction',
      (tester) async {
        final ref = await mountRef(tester);
        await tester.runAsync(() async {
          final threshold = repo
              .getRealm(RealmTier.xueTu, RealmLayer.shuLian)
              .experienceToNext;
          final id = await seed(
            layer: RealmLayer.shuLian,
            experience: threshold,
            heavyHours: victoryClaim ? 0 : 2,
          );
          final floor = victoryClaim
              ? repo.getTowerFloor(1)
              : repo.towerFloors.firstWhere((floor) => floor.isBoss);
          if (victoryClaim) {
            await applyTowerVictorySettlement(
              ref: ref,
              floor: floor,
              participantId: id,
              elapsedMs: 1000,
              settlementSnapshot: snapshot(id),
              rewardOccurrenceId: 'tower-boundary',
              settlementAt: now,
            );
            await expectLater(
              applyTowerVictorySettlement(
                ref: ref,
                floor: floor,
                participantId: id,
                elapsedMs: 1000,
                settlementSnapshot: snapshot(id),
                rewardOccurrenceId: 'tower-boundary',
                settlementAt: now,
              ),
              throwsStateError,
            );
          } else {
            await applyTowerCombatResolution(
              ref: ref,
              floor: floor,
              grantsFirstClearExperience: false,
              expectedParticipantId: id,
              settlementSnapshot: snapshot(id, won: false),
              settlementAt: now,
            );
            expect(
              (await isar.characters.get(id))!.injuryHoursRemaining,
              greaterThan(2),
            );
          }
          expect(
            (await isar.characters.get(id))!.experience,
            threshold +
                getExpectedExperience().floor() +
                (victoryClaim ? floor.baseExpReward : 0),
          );
          await expectPassiveLedger(id);
          await OfflinePassiveService.settleWindow(isar: isar, now: now);
          await expectPassiveLedger(id);
        });
      },
    );
  }
}
