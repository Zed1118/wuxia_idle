import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_key.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_unlock_service.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_progress.dart';
import 'package:wuxia_idle/features/jianghu/domain/reputation.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_settlement_journal_service.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_pending_jianghu_affair_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_victory_dialog.dart';
import 'package:wuxia_idle/features/weapon_codex/domain/equipment_catalog_entry.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
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
      'wuxia_mainline_durable_settlement_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  testWidgets('第一章核心写入与 receipt 原子落库；重启只恢复结算后动作', (tester) async {
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, value, child) {
              ref = value;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final evidence = (await tester.runAsync(() async {
      final isar = IsarSetup.instance;
      final character = Character.create(
        name: '持久结算参与者',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        createdAt: DateTime.utc(2026, 8, 24),
        internalForce: 3000,
      );
      await isar.writeTxn(() async {
        await isar.characters.put(character);
        final save = (await isar.saveDatas.get(0))!;
        save.activeCharacterIds = [character.id];
        save.founderCharacterId = character.id;
        await isar.saveDatas.put(save);
      });

      final identity = MainlineSettlementIdentity(
        runId: 'durable-ch1-run',
        stageId: 'stage_01_05',
        loadoutVersion: 5,
        participantId: character.id,
      );
      final journalService = MainlineSettlementJournalService(isar);
      await journalService.prepare(
        saveDataId: IsarSetup.currentSlotId,
        identity: identity,
        loadoutSnapshotId: 'snapshot-5',
        loadoutSnapshotIds: const [
          'snapshot-1',
          'snapshot-2',
          'snapshot-3',
          'snapshot-4',
          'snapshot-5',
        ],
        now: DateTime.utc(2026, 8, 24),
      );

      const stage = StageDef(
        id: 'stage_01_05',
        name: '持久结算测试关',
        stageType: StageType.mainline,
        chapterIndex: 1,
        requiredRealm: RealmTier.xueTu,
        enemyTeam: [
          EnemyDef(
            id: 'durable_enemy',
            name: '持久结算敌手',
            realmTier: RealmTier.xueTu,
            realmLayer: RealmLayer.qiMeng,
            school: TechniqueSchool.yinRou,
            baseHp: 100,
            baseAttack: 1,
            baseSpeed: 1,
            skillIds: [],
            iconPath: 'assets/enemies/umbrella.png',
          ),
        ],
        isBossStage: true,
        factionId: 'shaolin',
        dropSkillManualId: 'skill_xie_yu_chuan_lian',
        baseExpReward: 7,
        difficultyMultiplier: 1,
        dropTable: [
          EquipmentDrop(
            equipmentDefId: 'weapon_xunchang_tie_jian',
            dropChance: 1,
          ),
        ],
      );
      final settlement = CombatSettlementSnapshot(
        result: BattleResult.leftWin,
        totalTicks: 12,
        hadActions: true,
        playerCharacterId: character.id,
        participants: [
          CombatParticipantSnapshot(
            characterId: character.id,
            currentHp: 100,
            maxHp: 100,
          ),
        ],
        skillCasts: const [],
        totalDamage: 321,
        criticalCount: 2,
        damageByCharacterId: {character.id: 321},
      );

      final outcome = await applyVictoryResolution(
        ref: ref,
        stage: stage,
        settlementSnapshot: settlement,
        durableSettlement: (service: journalService, identity: identity),
      );
      final active = await journalService.activeForSave(
        IsarSetup.currentSlotId,
      );
      final progress = await isar.mainlineProgress.where().findFirst();
      final encounter = await isar.encounterProgress.where().findFirst();
      final boss = await isar.bossMemorys
          .filter()
          .bossKeyEqualTo(mainlineBossKey(stage.id))
          .findFirst();
      final catalog = await isar.equipmentCatalogEntrys
          .filter()
          .defIdEqualTo('weapon_xunchang_tie_jian')
          .findFirst();
      final participant = await isar.characters.get(character.id);
      final reputation = await isar.reputations
          .filter()
          .playerIdEqualTo(1)
          .factionIdEqualTo('shaolin')
          .findFirst();
      final manualUnlocked = await SkillUnlockService(
        isar,
      ).isUnlocked('skill_xie_yu_chuan_lian');
      final receiptCount = await isar.rewardClaimReceipts.where().count();
      return (
        identity: identity,
        service: journalService,
        outcome: outcome,
        active: active,
        progress: progress,
        encounter: encounter,
        boss: boss,
        catalog: catalog,
        participant: participant,
        reputation: reputation,
        manualUnlocked: manualUnlocked,
        receiptCount: receiptCount,
      );
    }))!;

    expect(evidence.outcome, isNotNull);
    expect(
      evidence.outcome!.skillDrop.manualGranted,
      'skill_xie_yu_chuan_lian',
    );
    expect(evidence.active!.phase, MainlineSettlementPhase.coreApplied);
    expect(
      evidence.active!.recoveryAction,
      MainlineSettlementRecoveryAction.resumePostSettlement,
    );
    expect(evidence.progress!.clearedStageIds, contains('stage_01_05'));
    expect(evidence.participant!.experience, 7);
    expect(evidence.manualUnlocked, isTrue);
    expect(evidence.receiptCount, 3);
    expect(evidence.catalog!.obtainedCount, 1);
    expect(evidence.boss!.defeatCount, 1);
    expect(evidence.reputation!.value, lessThan(0));
    expect(
      evidence.encounter!.schoolKillCounts.countOf(TechniqueSchool.yinRou),
      1,
    );

    await tester.runAsync(() async {
      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      final service = MainlineSettlementJournalService(IsarSetup.instance);
      final restored = await service.activeForSave(IsarSetup.currentSlotId);
      expect(restored!.identity, evidence.identity);
      expect(restored.phase, MainlineSettlementPhase.coreApplied);
      expect(restored.loadoutSnapshotIds, hasLength(5));
      expect(await IsarSetup.instance.rewardClaimReceipts.where().count(), 3);
      final affairs = MainlinePendingJianghuAffairService(service);
      while (true) {
        final pending = await affairs.firstPending(identity: evidence.identity);
        if (pending == null) break;
        await affairs.apply(
          identity: evidence.identity,
          affair: pending,
          now: DateTime.utc(2026, 8, 24, 0, 1),
          applyInTxn: () async {},
        );
      }
      await service.recordPostSettlementAction(
        identity: evidence.identity,
        action: MainlinePostSettlementAction.enterNextStage,
        now: DateTime.utc(2026, 8, 24, 0, 2),
      );
      await service.close(
        identity: evidence.identity,
        now: DateTime.utc(2026, 8, 24, 0, 3),
      );
      expect(await service.activeForSave(IsarSetup.currentSlotId), isNull);
    });
  });

  testWidgets('已结算恢复页明确不重发并可继续下一关', (tester) async {
    StageVictoryAction? action;
    const stage = StageDef(
      id: 'stage_01_03',
      name: '黑风岭',
      stageType: StageType.mainline,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: [],
      isBossStage: false,
      baseExpReward: 0,
      difficultyMultiplier: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              action = await showRecoveredStageSettlementDialog(
                context: context,
                stage: stage,
                allowEnterNextStage: true,
              );
            },
            child: const Text('recover'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('recover'));
    await tester.pumpAndSettle();
    expect(
      find.text(UiStrings.mainlineSettlementRecoveredBody),
      findsOneWidget,
    );
    await tester.tap(find.text(UiStrings.stageVictoryEnterNextStage));
    await tester.pumpAndSettle();
    expect(action, StageVictoryAction.enterNextStage);
  });
}
