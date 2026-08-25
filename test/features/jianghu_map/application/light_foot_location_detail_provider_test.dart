import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/defs/light_foot_def.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/jianghu_map/application/light_foot_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/light_foot_location_detail.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';

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
      'light_foot_location_detail_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Character leader(int id, String name) => Character()
    ..id = id
    ..name = name
    ..realmTier = RealmTier.sanLiu
    ..realmLayer = RealmLayer.qiMeng
    ..attributes = Attributes()
    ..rarity = RarityTier.biaoZhun
    ..lineageRole = LineageRole.founder
    ..isFounder = true
    ..isAlive = true
    ..createdAt = DateTime(2026, 8, 25);

  SaveData save({int? leaderId = 7}) => SaveData()
    ..saveVersion = '0.54'
    ..createdAt = DateTime(2026, 8, 25)
    ..lastSavedAt = DateTime(2026, 8, 25)
    ..lastOnlineAt = DateTime(2026, 8, 25)
    ..founderCharacterId = leaderId;

  Future<void> seedLeader({int? pointer = 7, bool insert = true}) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      if (insert) {
        final value = leader(7, '沈掌门');
        await isar.characters.put(value);
        final technique = Technique.create(
          defId: 'tech_gangmeng_jichu',
          ownerCharacterId: value.id,
          tier: TechniqueTier.values.first,
          school: TechniqueSchool.gangMeng,
          role: TechniqueRole.main,
          learnedAt: DateTime(2026, 8, 25),
        );
        value.mainTechniqueId = await isar.techniques.put(technique);
        await isar.characters.put(value);
      }
      await isar.saveDatas.put(save(leaderId: pointer));
    });
  }

  Future<LightFootLocationDetail> readDetail(List<String> cleared) {
    final container = ProviderContainer(
      overrides: [
        mainlineProgressProvider.overrideWith(
          (ref) async => MainlineProgress()..clearedStageIds = cleared,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container.read(lightFootLocationDetailProvider.future);
  }

  test('读取下一可挑战路线的生产配置、掉落与逐次选人可用数', () async {
    await seedLeader();
    final nextStage = GameRepository.instance.getStage('stage_light_foot_03');

    final detail = await readDetail(const [
      'stage_06_05',
      'stage_light_foot_01',
      'stage_light_foot_02',
    ]);

    expect(detail.clearedRoutes, 2);
    expect(detail.totalRoutes, 5);
    expect(detail.nextStageId, nextStage.id);
    expect(detail.nextStageName, nextStage.name);
    expect(detail.recommendedRealm, nextStage.requiredRealm);
    expect(detail.terrainBiome, nextStage.terrainBiome);
    expect(
      detail.enemies.map((enemy) => enemy.name),
      nextStage.enemyTeam.map((enemy) => enemy.name),
    );
    expect(detail.rewardRumor, isNotNull);
    expect(detail.baseExpReward, nextStage.baseExpReward);
    expect(detail.eligibleParticipantCount, 1);
  });

  test('五路全通时无下一路情报但保留逐次选人可用数', () async {
    await seedLeader();
    final detail = await readDetail(const [
      'stage_06_05',
      'stage_light_foot_01',
      'stage_light_foot_02',
      'stage_light_foot_03',
      'stage_light_foot_04',
      'stage_light_foot_05',
    ]);

    expect(detail.isComplete, isTrue);
    expect(detail.nextStageId, isNull);
    expect(detail.nextStageName, isNull);
    expect(detail.recommendedRealm, isNull);
    expect(detail.terrainBiome, isNull);
    expect(detail.enemies, isEmpty);
    expect(detail.rewardRumor, isNull);
    expect(detail.baseExpReward, isNull);
    expect(detail.eligibleParticipantCount, 1);
  });

  test('掌门闭关时详情仍保留空闲当代门人作为可用参与者', () async {
    await seedLeader();
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final currentLeader = (await isar.characters.get(7))!;
      currentLeader.currentRetreatSessionId = 88;
      await isar.characters.put(currentLeader);

      final disciple = leader(8, '空闲门人')
        ..lineageRole = LineageRole.disciple
        ..isFounder = false
        ..masterId = 7;
      await isar.characters.put(disciple);
      final technique = Technique.create(
        defId: 'tech_gangmeng_jichu',
        ownerCharacterId: disciple.id,
        tier: TechniqueTier.values.first,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: DateTime(2026, 8, 25),
      );
      disciple.mainTechniqueId = await isar.techniques.put(technique);
      await isar.characters.put(disciple);
    });

    final detail = await readDetail(const ['stage_06_05']);
    expect(detail.eligibleParticipantCount, 1);
    expect(detail.hasEligibleParticipant, isTrue);
  });

  test('掌门指针缺失或悬空时 fail closed', () async {
    await seedLeader(pointer: null);
    await expectLater(
      readDetail(const ['stage_06_05']),
      throwsA(isA<StateError>()),
    );

    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(save(leaderId: 99));
    });
    await expectLater(
      readDetail(const ['stage_06_05']),
      throwsA(isA<StateError>()),
    );
  });

  test('轻功解锁前或进度断链时 fail closed', () async {
    await seedLeader();
    await expectLater(readDetail(const []), throwsA(isA<StateError>()));
    await expectLater(
      readDetail(const ['stage_06_05', 'stage_light_foot_02']),
      throwsA(isA<StateError>()),
    );
  });

  group('轻功地点解锁图 fail closed', () {
    LightFootDef graph(Map<String, String> edges) => LightFootDef(
      terrainModifiers: const {},
      stageTerrain: const {
        'stage_light_foot_01': TerrainBiome.water,
        'stage_light_foot_02': TerrainBiome.rooftop,
        'stage_light_foot_03': TerrainBiome.bamboo,
        'stage_light_foot_04': TerrainBiome.water,
      },
      unlockTriggers: edges,
    );

    test('合法单链按生产顺序返回', () {
      expect(
        validatedLightFootLocationStageIds(
          graph(const {
            'stage_06_05': 'stage_light_foot_01',
            'stage_light_foot_01': 'stage_light_foot_02',
            'stage_light_foot_02': 'stage_light_foot_03',
            'stage_light_foot_03': 'stage_light_foot_04',
          }),
        ),
        const [
          'stage_light_foot_01',
          'stage_light_foot_02',
          'stage_light_foot_03',
          'stage_light_foot_04',
        ],
      );
    });

    test('脱离根链的环不会永久遍历', () {
      expect(
        () => validatedLightFootLocationStageIds(
          graph(const {
            'stage_06_05': 'stage_light_foot_01',
            'stage_light_foot_01': 'stage_light_foot_02',
            'stage_light_foot_03': 'stage_light_foot_04',
            'stage_light_foot_04': 'stage_light_foot_03',
          }),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('多根或汇合分支拒绝', () {
      expect(
        () => validatedLightFootLocationStageIds(
          graph(const {
            'stage_06_05': 'stage_light_foot_01',
            'stage_alt_gate': 'stage_light_foot_02',
            'stage_light_foot_01': 'stage_light_foot_02',
            'stage_light_foot_02': 'stage_light_foot_03',
          }),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('截断链拒绝', () {
      expect(
        () => validatedLightFootLocationStageIds(
          graph(const {
            'stage_06_05': 'stage_light_foot_01',
            'stage_light_foot_01': 'stage_light_foot_02',
            'stage_light_foot_02': 'stage_light_foot_03',
          }),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
