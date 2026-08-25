import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_controller.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/phase0a_gauntlet_stage_runner.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_factory.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// Phase 0A 断魂庄 seam：事务外准备单角色战斗计划，战末只把引擎中立检查点
/// 交给事务层，live 与 headless 路径共用同一结算入口。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_seam_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> seedSave() async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.38.0'
          ..createdAt = DateTime(2026, 7, 17)
          ..lastSavedAt = DateTime(2026, 7, 17)
          ..lastOnlineAt = DateTime(2026, 7, 17),
      );
    });
  }

  ActivityMemberSnapshot snap(int id, {int maxHp = 0, int currentHp = 0}) =>
      ActivityMemberSnapshot()
        ..characterId = id
        ..maxHp = maxHp
        ..currentHp = currentHp
        ..isDowned = false;

  Future<int> putRun({
    required GauntletPhase phase,
    required int currentStage,
    required List<ActivityMemberSnapshot> members,
  }) async {
    late int id;
    await IsarSetup.instance.writeTxn(() async {
      id = await IsarSetup.instance.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 0
          ..currentStage = currentStage
          ..sessionPhase = phase
          ..members = members,
      );
    });
    return id;
  }

  test('preparePhase0aStage：事务外建当前关出战计划（角色+敌+seed+isBoss）', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)], // maxHp=0 = 首关满血基准
    );
    final config = GameRepository.instance.bossGauntletConfig!;

    final plan = await GauntletService(
      IsarSetup.instance,
    ).preparePhase0aStage(config: config);

    expect(plan.playerSnapshot.characterId, 1, reason: '真单角色快照');
    expect(plan.enemyDefs, isNotEmpty, reason: '关次敌队非空');
    expect(
      plan.seed,
      0 * 31 + 1,
      reason: 'seed 混 currentStage（run.seed*31+stage）',
    );
    expect(plan.isBoss, config.stages[0].role == 'boss');
  });

  test('旧会话 seed=0 恢复后不重算，三关 stage seed 仍为 1/2/3', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final config = GameRepository.instance.bossGauntletConfig!;
    final service = GauntletService(IsarSetup.instance);

    for (var stage = 1; stage <= 3; stage++) {
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.bossGauntletRuns.clear();
      });
      await putRun(
        phase: GauntletPhase.inBattle,
        currentStage: stage,
        members: [snap(1)],
      );

      final plan = await service.preparePhase0aStage(config: config);
      expect(plan.seed, stage, reason: 'legacy seed=0 / stage=$stage');
      final persisted =
          (await IsarSetup.instance.bossGauntletRuns.where().findAll()).single;
      expect(persisted.seed, 0, reason: '恢复/准备战斗不得重写旧 seed');
    }
  });

  test('preparePhase0aStage 拒非 inBattle（整备页）→ 抛错', () async {
    await seedSave();
    await putRun(
      phase: GauntletPhase.interlude,
      currentStage: 2,
      members: [snap(1, maxHp: 1000, currentHp: 500)],
    );
    final config = GameRepository.instance.bossGauntletConfig!;
    await expectLater(
      GauntletService(IsarSetup.instance).preparePhase0aStage(config: config),
      throwsStateError,
    );
  });

  test('prepare + Phase0a run + settle == 原子推进战末快照', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final weaponDef = GameRepository.instance.equipmentDefs.values.firstWhere(
      (def) => def.slot.name == 'weapon',
    );
    late int equipmentId;
    await IsarSetup.instance.writeTxn(() async {
      final equipment = EquipmentFactory.fromDef(
        weaponDef,
        rng: DefaultRng(seed: 7),
        obtainedAt: DateTime(2026, 8, 25),
        obtainedFrom: 'gauntlet-settlement-red',
        ownerCharacterId: 1,
      );
      equipmentId = await IsarSetup.instance.equipments.put(equipment);
      final character = (await IsarSetup.instance.characters.get(1))!
        ..equippedWeaponId = equipmentId;
      await IsarSetup.instance.characters.put(character);
    });
    final runId = await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)],
    );
    final config = GameRepository.instance.bossGauntletConfig!;
    final numbers = GameRepository.instance.numbers;
    final service = GauntletService(IsarSetup.instance);

    final plan = await service.preparePhase0aStage(config: config);
    final result = await Phase0aGauntletStageRunner.run(
      contentId: 'gauntlet_${plan.stage}',
      playerSnapshot: plan.playerSnapshot,
      enemyTeam: plan.enemyDefs,
      numbers: numbers,
      seed: plan.seed,
      cycleIndex: plan.cycleIndex,
    );
    expect(
      result.settlement.combatSettlement.participantCharacterIds
          .where((id) => id > 0)
          .toSet(),
      {1},
      reason: 'headless 与 live 必须从真实 mapping/events 产出实际参与者共享结算快照',
    );
    await service.settlePhase0aStageResult(
      result: result.settlement,
      config: config,
    );

    final equipment = (await IsarSetup.instance.equipments.get(equipmentId))!;
    expect(equipment.battleCount, 1, reason: '逐关终局必须进入共享战斗账本');
    final characterAfterStage = (await IsarSetup.instance.characters.get(1))!;
    expect(characterAfterStage.injuryHoursRemaining, 0);
    expect(
      characterAfterStage.lightInjuryStacks,
      0,
      reason: '断魂庄逐关共享结算不得抢跑会话末伤势',
    );
    final techniques = await IsarSetup.instance.techniques.where().findAll();
    expect(
      techniques
          .expand((technique) => technique.skillUsageCount)
          .fold<int>(0, (sum, entry) => sum + entry.count),
      greaterThan(0),
      reason: '真实 Phase0a 招式事件必须写回实际参与者心法使用记录',
    );

    final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
    expect(run.members.single.maxHp, greaterThan(0), reason: '战末快照真落地');
    if (result.leftWin) {
      expect(run.sessionPhase, GauntletPhase.interlude);
      expect(run.currentStage, 2);
    } else {
      expect(run.sessionPhase, GauntletPhase.inBattle);
      expect(run.currentStage, 1);
    }
  });

  test('settlePhase0aStageResult 错人快照 → fail closed 且不推进会话', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final runId = await putRun(
      phase: GauntletPhase.inBattle,
      currentStage: 1,
      members: [snap(1)],
    );
    final config = GameRepository.instance.bossGauntletConfig!;

    await expectLater(
      GauntletService(IsarSetup.instance).settlePhase0aStageResult(
        result: GauntletStageSettlement(
          leftWin: true,
          checkpoint: const GauntletMemberCheckpoint(
            characterId: 1,
            currentHp: 1,
            currentQi: 0,
            maxHp: 1,
            maxQi: 1,
          ),
          combatSettlement: CombatSettlementSnapshot(
            result: BattleResult.leftWin,
            totalTicks: 1,
            hadActions: true,
            participants: const [
              CombatParticipantSnapshot(characterId: 2, currentHp: 1, maxHp: 1),
            ],
            skillCasts: const [],
            totalDamage: 1,
            criticalCount: 0,
            damageByCharacterId: const {2: 1},
          ),
        ),
        config: config,
      ),
      throwsStateError,
    );

    final run = (await IsarSetup.instance.bossGauntletRuns.get(runId))!;
    expect(run.currentStage, 1);
    expect(run.sessionPhase, GauntletPhase.inBattle);
    expect(run.members.single.maxHp, 0, reason: '事务回滚不得写入错人检查点');
  });

  test('settlePhase0aStageResult 会话已关闭 → 防御 no-op（不抛）', () async {
    await seedSave();
    // 无 active run → fresh 为 null → settlement 内防御返回。
    final config = GameRepository.instance.bossGauntletConfig!;
    await GauntletService(IsarSetup.instance).settlePhase0aStageResult(
      result: GauntletStageSettlement(
        leftWin: false,
        checkpoint: const GauntletMemberCheckpoint(
          characterId: 1,
          currentHp: 0,
          currentQi: 0,
          maxHp: 1,
          maxQi: 1,
        ),
        combatSettlement: CombatSettlementSnapshot(
          result: BattleResult.rightWin,
          totalTicks: 1,
          hadActions: false,
          participants: const [
            CombatParticipantSnapshot(characterId: 1, currentHp: 0, maxHp: 1),
          ],
          skillCasts: const [],
          totalDamage: 0,
          criticalCount: 0,
          damageByCharacterId: const {1: 0},
        ),
      ),
      config: config,
    );
    // 不抛即通过。
    expect(true, isTrue);
  });
}
