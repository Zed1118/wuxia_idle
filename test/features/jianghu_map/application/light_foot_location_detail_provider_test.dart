import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
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
      if (insert) await isar.characters.put(leader(7, '沈掌门'));
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

  test('读取下一可挑战路线的生产配置、掉落与真实当前掌门', () async {
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
    expect(detail.participantId, 7);
    expect(detail.participantName, '沈掌门');
  });

  test('五路全通时无下一路情报但保留真实参与者', () async {
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
    expect(detail.participantName, '沈掌门');
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
}
