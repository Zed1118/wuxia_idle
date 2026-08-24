import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/expedition_config.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_providers.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/jianghu_map/application/expedition_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/expedition_location_detail.dart';

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
      'expedition_location_detail_',
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

  SaveData save({bool unlocked = true, int maxDepth = 18}) => SaveData()
    ..saveVersion = '0.54'
    ..createdAt = DateTime(2026, 8, 25)
    ..lastSavedAt = DateTime(2026, 8, 25)
    ..lastOnlineAt = DateTime(2026, 8, 25)
    ..jianghuJourneyUnlocked = unlocked
    ..baicaoMaxDepth = maxDepth;

  Future<void> seed({
    bool unlocked = true,
    int maxDepth = 18,
    bool insertMember = true,
  }) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.saveDatas.put(save(unlocked: unlocked, maxDepth: maxDepth));
      if (insertMember) await isar.characters.put(character(7, '沈无归'));
    });
  }

  ExpeditionCandidate candidate({
    required int id,
    required bool occupied,
    bool hasMainTechnique = true,
  }) => ExpeditionCandidate(
    character: character(id, '门人$id'),
    occupied: occupied,
    hasMainTechnique: hasMainTechnique,
  );

  Future<ExpeditionLocationDetail> readDetail({
    ExpeditionRun? active,
    ExpeditionConfig? config,
  }) {
    final container = ProviderContainer(
      overrides: [
        expeditionConfigProvider.overrideWithValue(
          config ?? GameRepository.instance.expeditionConfig,
        ),
        activeExpeditionProvider.overrideWith((ref) async => active),
        expeditionMaxDepthProvider.overrideWith((ref) async => 18),
        expeditionCandidatesProvider.overrideWith(
          (ref) async => [
            candidate(id: 8, occupied: false),
            candidate(id: 9, occupied: true),
            candidate(id: 10, occupied: false, hasMainTechnique: false),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    return container.read(expeditionLocationDetailProvider.future);
  }

  test('读取生产历史深度、敌队、奖励与可派遣候选人', () async {
    await seed();
    final config = GameRepository.instance.expeditionConfig!;

    final detail = await readDetail();

    expect(detail.historicalMaxDepth, 18);
    expect(detail.activeDepth, isNull);
    expect(detail.recommendedRealm, RealmTier.erLiu);
    expect(detail.normalEnemyTeams, hasLength(config.normalEnemyTeams.length));
    expect(detail.eliteEnemyTeams, hasLength(config.eliteEnemyTeams.length));
    expect(detail.normalEnemyTeams.first.enemies.first.name, isNotEmpty);
    expect(detail.coreRewardItemNames, containsAll(['药草', '灵泉水', '银两', '断魂帖']));
    expect(detail.includesExperienceReward, isTrue);
    expect(detail.candidateCount, 3);
    expect(detail.availableCandidateCount, 1);
    expect(detail.activeParticipantNames, isEmpty);
  });

  test('进行中远征读取持久深度、方针、战败态与真实参与者', () async {
    await seed();
    final run = ExpeditionRun()
      ..saveDataId = 0
      ..policy = ExpeditionPolicy.xunJiFangYou
      ..seed = 7
      ..departedAt = DateTime(2026, 8, 25)
      ..currentNode = 12
      ..cycleIndex = 2
      ..defeated = true
      ..members = [ActivityMemberSnapshot()..characterId = 7];

    final detail = await readDetail(active: run);

    expect(detail.activeDepth, 12);
    expect(detail.activePolicy, ExpeditionPolicy.xunJiFangYou);
    expect(detail.activeDefeated, isTrue);
    expect(detail.activeParticipantNames, const ['沈无归']);
    expect(detail.hasActiveRun, isTrue);
  });

  test('隐藏门未满足时直达 provider fail closed', () async {
    await seed(unlocked: false);

    await expectLater(readDetail(), throwsA(isA<StateError>()));
  });

  test('配置缺失普通敌队时 fail closed', () async {
    await seed();
    final source = GameRepository.instance.expeditionConfig!;
    final invalid = ExpeditionConfig(
      normalNodeMinutes: source.normalNodeMinutes,
      eliteNodeMinutes: source.eliteNodeMinutes,
      hpRecoverPctPerNode: source.hpRecoverPctPerNode,
      qiRecoverPctPerNode: source.qiRecoverPctPerNode,
      zhangshiPctPerLayer: source.zhangshiPctPerLayer,
      baseExpPerBattle: source.baseExpPerBattle,
      depthCurve: source.depthCurve,
      normalEnemyTeams: const [],
      eliteEnemyTeams: source.eliteEnemyTeams,
    );

    await expectLater(readDetail(config: invalid), throwsA(isA<StateError>()));
  });

  test('进行中参与者悬空时 fail closed', () async {
    await seed(insertMember: false);
    final run = ExpeditionRun()
      ..saveDataId = 0
      ..policy = ExpeditionPolicy.yanJingCaiYao
      ..seed = 7
      ..departedAt = DateTime(2026, 8, 25)
      ..currentNode = 3
      ..members = [ActivityMemberSnapshot()..characterId = 77];

    await expectLater(readDetail(active: run), throwsA(isA<StateError>()));
  });
}
