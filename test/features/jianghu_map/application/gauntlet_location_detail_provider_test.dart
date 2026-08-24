import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/boss_gauntlet_config.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/jianghu_map/application/gauntlet_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/gauntlet_location_detail.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'gauntlet_location_detail_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Character character(int id, String name) => Character()
    ..id = id
    ..name = name
    ..realmTier = RealmTier.erLiu
    ..realmLayer = RealmLayer.qiMeng
    ..attributes = Attributes()
    ..rarity = RarityTier.biaoZhun
    ..lineageRole = LineageRole.disciple
    ..mainTechniqueId = 11
    ..isAlive = true
    ..createdAt = DateTime(2026, 8, 25);

  SaveData save({bool unlocked = true}) => SaveData()
    ..saveVersion = '0.54'
    ..createdAt = DateTime(2026, 8, 25)
    ..lastSavedAt = DateTime(2026, 8, 25)
    ..lastOnlineAt = DateTime(2026, 8, 25)
    ..jianghuJourneyUnlocked = unlocked;

  Future<void> seed({bool unlocked = true, bool insertMember = true}) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.saveDatas.put(save(unlocked: unlocked));
      if (insertMember) await isar.characters.put(character(7, '沈无归'));
    });
  }

  GauntletCandidate candidate({
    required int id,
    required bool occupied,
    bool hasMainTechnique = true,
  }) => GauntletCandidate(
    character: character(id, '门人$id'),
    occupied: occupied,
    hasMainTechnique: hasMainTechnique,
  );

  Future<GauntletLocationDetail> readDetail({
    BossGauntletRun? active,
    BossGauntletConfig? config,
    int clearedCyclesMax = 2,
  }) {
    final container = ProviderContainer(
      overrides: [
        gauntletConfigProvider.overrideWithValue(
          config ?? GameRepository.instance.bossGauntletConfig,
        ),
        activeGauntletProvider.overrideWith((ref) async => active),
        gauntletLoadoutInfoProvider.overrideWith(
          (ref) async => GauntletLoadoutInfo(
            ticketCount: 3,
            supplies: const [],
            clearedCyclesMax: clearedCyclesMax,
          ),
        ),
        gauntletCandidatesProvider.overrideWith(
          (ref) async => [
            candidate(id: 8, occupied: false),
            candidate(id: 9, occupied: true),
            candidate(id: 10, occupied: false, hasMainTechnique: false),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    return container.read(gauntletLocationDetailProvider.future);
  }

  test('读取生产三关、奖励、进度、断魂帖与可用候选人', () async {
    await seed();
    final config = GameRepository.instance.bossGauntletConfig!;

    final detail = await readDetail();

    expect(detail.clearedCyclesMax, 2);
    expect(detail.totalStages, config.stages.length);
    expect(detail.ticketCount, 3);
    expect(detail.supplyCap, config.supplyCap);
    expect(detail.candidateCount, 3);
    expect(detail.availableCandidateCount, 1);
    expect(detail.activeStage, isNull);
    expect(detail.activeParticipantNames, isEmpty);
    expect(detail.recommendedRealm, RealmTier.erLiu);
    expect(detail.stages, hasLength(3));
    expect(detail.stages.first.isBoss, isFalse);
    expect(detail.stages.last.isBoss, isTrue);
    expect(detail.stages.first.enemies.first.name, '苏无咎');
    expect(
      detail.rewardSkillName,
      GameRepository.instance.getSkill(config.firstClearRewardSkillId).name,
    );
    expect(
      detail.rewardEquipmentNames,
      config.rewardCandidateEquipmentIds
          .map(GameRepository.instance.getEquipment)
          .map((def) => def.name),
    );
    expect(detail.firstClearRewardExp, config.firstClearRewardExp);
    expect(detail.firstClearRewardInsight, config.firstClearRewardInsight);
    expect(detail.eliteRewardExp, config.eliteRewardExp);
  });

  test('进行中庄局读取持久关次、阶段与真实参与者', () async {
    await seed();
    final member = ActivityMemberSnapshot()..characterId = 7;
    final run = BossGauntletRun()
      ..saveDataId = 0
      ..seed = 7
      ..currentStage = 2
      ..sessionPhase = GauntletPhase.interlude
      ..members = [member];

    final detail = await readDetail(active: run);

    expect(detail.activeStage, 2);
    expect(detail.activePhase, GauntletPhase.interlude);
    expect(detail.activeParticipantNames, const ['沈无归']);
    expect(detail.hasActiveRun, isTrue);
  });

  test('隐藏门未满足时直达 provider fail closed', () async {
    await seed(unlocked: false);

    await expectLater(readDetail(), throwsA(isA<StateError>()));
  });

  test('配置敌队引用缺失时 fail closed', () async {
    await seed();
    const invalid = BossGauntletConfig(
      stages: [
        GauntletStageConfig(role: 'elite', enemyTeamId: 'missing_a'),
        GauntletStageConfig(role: 'elite', enemyTeamId: 'missing_b'),
        GauntletStageConfig(role: 'boss', enemyTeamId: 'missing_c'),
      ],
      supplyCap: 3,
      firstClearRewardSkillId: 'skill_suo_mai_zhen',
      rewardCandidateEquipmentIds: [
        'weapon_haojiahuo_suo_mai_nang',
        'armor_haojiahuo_zhen_yue_tie_yi',
        'accessory_haojiahuo_she_hun_ling',
      ],
    );

    await expectLater(readDetail(config: invalid), throwsA(isA<StateError>()));
  });

  test('进行中参与者悬空时 fail closed', () async {
    await seed(insertMember: false);
    final run = BossGauntletRun()
      ..saveDataId = 0
      ..seed = 7
      ..currentStage = 1
      ..members = [ActivityMemberSnapshot()..characterId = 77];

    await expectLater(readDetail(active: run), throwsA(isA<StateError>()));
  });
}
