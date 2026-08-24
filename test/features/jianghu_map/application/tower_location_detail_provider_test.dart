import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/jianghu_map/application/tower_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/tower_location_detail.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tower_location_detail_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Character leader(int id, String name) => Character()
    ..id = id
    ..name = name
    ..realmTier = RealmTier.xueTu
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

  TowerProgress progress(int highest) => TowerProgress()
    ..saveDataId = 0
    ..highestClearedFloor = highest;

  Future<void> seedLeader({int? pointer = 7, bool insert = true}) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      if (insert) await isar.characters.put(leader(7, '沈掌门'));
      await isar.saveDatas.put(save(leaderId: pointer));
    });
  }

  Future<TowerLocationDetail> readDetail(int highest) async {
    final container = ProviderContainer(
      overrides: [
        towerProgressProvider.overrideWith((ref) async => progress(highest)),
      ],
    );
    addTearDown(container.dispose);
    return container.read(towerLocationDetailProvider.future);
  }

  test('读取下一层生产配置、掉落与真实当前领队', () async {
    await seedLeader();
    final repository = GameRepository.instance;
    final nextFloor = repository.getTowerFloor(7);

    final detail = await readDetail(6);

    expect(detail.highestClearedFloor, 6);
    expect(detail.totalFloors, repository.towerMaxFloor);
    expect(detail.nextFloorIndex, 7);
    expect(detail.recommendedRealm, nextFloor.requiredRealm);
    expect(
      detail.enemies.map((enemy) => enemy.name),
      nextFloor.enemyTeam.map((enemy) => enemy.name),
    );
    expect(detail.rewardRumor, isNotNull);
    expect(detail.baseExpReward, nextFloor.baseExpReward);
    expect(detail.participantId, 7);
    expect(detail.participantName, '沈掌门');
  });

  test('登顶态无下一层情报但保留真实参与者', () async {
    await seedLeader();
    final maxFloor = GameRepository.instance.towerMaxFloor;

    final detail = await readDetail(maxFloor);

    expect(detail.isComplete, isTrue);
    expect(detail.nextFloorIndex, isNull);
    expect(detail.recommendedRealm, isNull);
    expect(detail.enemies, isEmpty);
    expect(detail.rewardRumor, isNull);
    expect(detail.baseExpReward, isNull);
    expect(detail.participantName, '沈掌门');
  });

  test('领队指针缺失或悬空时 fail closed', () async {
    await seedLeader(pointer: null);
    await expectLater(readDetail(6), throwsA(isA<StateError>()));

    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(save(leaderId: 99));
    });
    await expectLater(readDetail(6), throwsA(isA<StateError>()));
  });

  test('塔进度越过生产最高层时 fail closed', () async {
    await seedLeader();
    await expectLater(
      readDetail(GameRepository.instance.towerMaxFloor + 1),
      throwsA(isA<StateError>()),
    );
  });
}
