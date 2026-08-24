import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/encounter_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_pending_jianghu_affair.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

class _FixedRng implements Rng {
  const _FixedRng(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  T pick<T>(List<T> list) => list.first;
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'mainline_pending_affair_plan_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  const enemy = EnemyDef(
    id: 'pending_affair_enemy',
    name: '待处理事测试敌人',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    baseHp: 100,
    baseAttack: 10,
    baseSpeed: 10,
    skillIds: [],
    iconPath: 'assets/enemies/test.png',
  );

  MainlineSettlementIdentity identity(String stageId) =>
      MainlineSettlementIdentity(
        runId: 'pending-affair-run',
        stageId: stageId,
        loadoutVersion: 1,
        participantId: 1,
      );

  EncounterDef encounter({required double probability}) => EncounterDef(
    id: 'enc_pending_affair',
    type: EncounterType.fortuneEvent,
    trigger: const EncounterTrigger(),
    baseProbability: probability,
    outcomeMapping: const {'leave': OutcomeDef(type: OutcomeType.none)},
  );

  Future<EncounterService> seedFounderAndProgress() async {
    final isar = IsarSetup.instance;
    final founder = Character.create(
      name: '待处理事测试掌门',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime.utc(2026, 8, 25),
      internalForce: 3000,
    );
    await isar.writeTxn(() async {
      await isar.characters.put(founder);
      final save = (await isar.saveDatas.get(0))!;
      save.activeCharacterIds = [founder.id];
      save.founderCharacterId = founder.id;
      await isar.saveDatas.put(save);
    });
    final service = EncounterService(
      isar: isar,
      attributeGainCap:
          GameRepository.instance.numbers.adventureAttributeLifetimeCap,
      attributeEffects: GameRepository.instance.numbers.attributeEffects,
    );
    await service.getOrCreate(saveDataId: IsarSetup.currentSlotId);
    return service;
  }

  test('第一章普通关命中互动奇遇，ref 重建仍 canonical 去重', () async {
    final service = await seedFounderAndProgress();
    const stage = StageDef(
      id: 'stage_01_03',
      name: '黑风岭',
      stageType: StageType.mainline,
      chapterIndex: 1,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: [enemy],
      isBossStage: false,
      baseExpReward: 0,
      difficultyMultiplier: 1,
    );

    Future<List<MainlinePendingJianghuAffairRef>> plan() =>
        IsarSetup.instance.writeTxn(
          () => planMainlinePendingJianghuAffairsInTxn(
            isar: IsarSetup.instance,
            identity: identity(stage.id),
            stage: stage,
            saveDataId: IsarSetup.currentSlotId,
            encounterService: service,
            encounters: [encounter(probability: 1)],
            rng: const _FixedRng(0),
          ),
        );

    final first = await plan();
    final recovered = await plan();
    expect(first, hasLength(1));
    expect(first.single.kind, MainlinePendingJianghuAffairKind.encounterChoice);
    expect(recovered.single.effectId, first.single.effectId);
  });

  test('第一章 Boss 关同时命中时保持奇遇→招降产品顺序', () async {
    final service = await seedFounderAndProgress();
    final candidateRef = GameRepository.instance.sectCandidates.keys.first;
    final stage = StageDef(
      id: 'stage_01_05',
      name: '章末 Boss',
      stageType: StageType.mainline,
      chapterIndex: 1,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: const [enemy],
      isBossStage: true,
      bossRecruit: BossRecruitConfig(
        candidateRef: candidateRef,
        baseProbability: 1,
      ),
      baseExpReward: 0,
      difficultyMultiplier: 1,
    );

    final refs = await IsarSetup.instance.writeTxn(
      () => planMainlinePendingJianghuAffairsInTxn(
        isar: IsarSetup.instance,
        identity: identity(stage.id),
        stage: stage,
        saveDataId: IsarSetup.currentSlotId,
        encounterService: service,
        encounters: [encounter(probability: 1)],
        rng: const _FixedRng(0),
      ),
    );

    expect(refs, hasLength(2));
    expect(refs.first.kind, MainlinePendingJianghuAffairKind.encounterChoice);
    expect(refs.first.ordinal, 1);
    expect(refs.last.kind, MainlinePendingJianghuAffairKind.stageBossRecruit);
    expect(refs.last.ordinal, 2);
    expect(refs.last.candidateRef, candidateRef);
  });

  test('第一章无事项关返回空队列，不增弹窗条件', () async {
    final service = await seedFounderAndProgress();
    const stage = StageDef(
      id: 'stage_01_02',
      name: '无事项关',
      stageType: StageType.mainline,
      chapterIndex: 1,
      requiredRealm: RealmTier.xueTu,
      enemyTeam: [enemy],
      isBossStage: false,
      baseExpReward: 0,
      difficultyMultiplier: 1,
    );

    final refs = await IsarSetup.instance.writeTxn(
      () => planMainlinePendingJianghuAffairsInTxn(
        isar: IsarSetup.instance,
        identity: identity(stage.id),
        stage: stage,
        saveDataId: IsarSetup.currentSlotId,
        encounterService: service,
        encounters: [encounter(probability: 0)],
        rng: const _FixedRng(0.9),
      ),
    );

    expect(refs, isEmpty);
  });
}
