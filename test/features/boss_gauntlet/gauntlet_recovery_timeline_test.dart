import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attribute_effect_policy.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_controller.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/phase0a_gauntlet_stage_runner.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  late Directory directory;
  late Isar isar;
  late DateTime startedAt;
  late GauntletService service;

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'gauntlet_recovery_clock_',
    );
    await IsarSetup.init(directory: directory, inspector: false);
    isar = IsarSetup.instance;
    await Phase2SeedService(isar: isar).seedP3();
    service = GauntletService(isar);
    startedAt = DateTime.now().toUtc();
    await isar.writeTxn(() async {
      final character = (await isar.characters.get(1))!
        ..recoverySettledAt = startedAt
        ..injuryHoursRemaining = 4
        ..innerBreathDisorderHoursRemaining = 4
        ..lightInjuryStacks = 2;
      await isar.characters.put(character);
      await isar.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 71
          ..currentStage = 1
          ..sessionPhase = GauntletPhase.inBattle
          ..members = [ActivityMemberSnapshot()..characterId = 1],
      );
    });
  });
  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  GauntletStageSettlement defeat({bool hadActions = true}) =>
      GauntletStageSettlement(
        leftWin: false,
        checkpoint: const GauntletMemberCheckpoint(
          characterId: 1,
          currentHp: 0,
          currentQi: 0,
          maxHp: 100,
          maxQi: 100,
        ),
        combatSettlement: CombatSettlementSnapshot(
          result: BattleResult.rightWin,
          totalTicks: 1,
          hadActions: hadActions,
          playerCharacterId: 1,
          participants: const [
            CombatParticipantSnapshot(characterId: 1, currentHp: 0, maxHp: 100),
          ],
          skillCasts: const [],
          totalDamage: 0,
          criticalCount: 0,
          damageByCharacterId: const {1: 0},
        ),
      );

  test(
    'stage applies elapsed recovery before the existing battle recovery',
    () async {
      final at = startedAt.add(const Duration(hours: 1));
      await service.settlePhase0aStageResult(
        result: defeat(),
        config: GameRepository.instance.bossGauntletConfig!,
        now: at,
      );
      final character = (await isar.characters.get(1))!;
      final battleRecovery = GameRepository
          .instance
          .numbers
          .innerBreathDisorder
          .battleRecoveryHours;
      expect(character.injuryHoursRemaining, closeTo(3, 1e-9));
      expect(
        character.innerBreathDisorderHoursRemaining,
        closeTo(3 - battleRecovery, 1e-9),
      );
      expect(character.lightInjuryStacks, 2);
      expect(character.recoverySettledAt!.toUtc(), at);
    },
  );

  test(
    'stage preparation recovers once and a rollback never rewinds the anchor',
    () async {
      final at = startedAt.add(const Duration(hours: 1));
      final config = GameRepository.instance.bossGauntletConfig!;
      await service.preparePhase0aStage(config: config, now: at);
      final once = await isar.characters.where().exportJson();
      await service.preparePhase0aStage(config: config, now: at);
      expect(await isar.characters.where().exportJson(), once);
      await service.preparePhase0aStage(config: config, now: startedAt);
      expect(await isar.characters.where().exportJson(), once);
      final character = (await isar.characters.get(1))!;
      expect(character.injuryHoursRemaining, closeTo(3, 1e-9));
      expect(character.innerBreathDisorderHoursRemaining, closeTo(3, 1e-9));
      expect(character.lightInjuryStacks, 2);
    },
  );

  test(
    'defeat creates its new injury after old recovery and retry cannot recover it early',
    () async {
      final at = startedAt.add(const Duration(hours: 2));
      final repository = GameRepository.instance;
      await service.settlePhase0aStageResult(
        result: defeat(),
        config: repository.bossGauntletConfig!,
        now: at,
      );
      await service.settleDefeat(
        config: repository.bossGauntletConfig!,
        numbers: repository.numbers,
        now: at,
      );
      final character = (await isar.characters.get(1))!;
      final expectedInjury =
          AttributeEffectPolicy(
            repository.numbers.attributeEffects,
          ).heavyInjuryHours(
            baseHours: repository.numbers.injury.heavyRecoveryHours,
            constitution: character.attributes.constitution,
          );
      expect(character.injuryHoursRemaining, expectedInjury);
      expect(character.recoverySettledAt!.toUtc(), at);
      final afterDefeat = await isar.characters.where().exportJson();
      await service.settleDefeat(
        config: repository.bossGauntletConfig!,
        numbers: repository.numbers,
        now: at,
      );
      expect(await isar.characters.where().exportJson(), afterDefeat);
      await OfflinePassiveService.settleWindow(
        isar: isar,
        now: at.add(const Duration(minutes: 30)),
      );
      expect(
        (await isar.characters.get(1))!.injuryHoursRemaining,
        closeTo(expectedInjury - 0.5, 1e-9),
      );
    },
  );
}
