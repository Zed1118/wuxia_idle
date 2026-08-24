import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/mass_battle_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/jianghu_map/application/mass_battle_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/mass_battle_location_detail.dart';
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
      'mass_battle_location_detail_',
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

  Future<MassBattleLocationDetail> readDetail(List<String> cleared) {
    final container = ProviderContainer(
      overrides: [
        mainlineProgressProvider.overrideWith(
          (ref) async => MainlineProgress()..clearedStageIds = cleared,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container.read(massBattleLocationDetailProvider.future);
  }

  test('读取下一可挑战守城关的生产配置与真实当前掌门', () async {
    await seedLeader();
    final nextStage = GameRepository.instance.getStage('stage_mass_battle_03');

    final detail = await readDetail(const [
      'stage_06_05',
      'stage_mass_battle_01',
      'stage_mass_battle_02',
    ]);

    expect(detail.clearedRoutes, 2);
    expect(detail.totalRoutes, 5);
    expect(detail.nextStageId, nextStage.id);
    expect(detail.nextStageName, nextStage.name);
    expect(detail.recommendedRealm, nextStage.requiredRealm);
    expect(
      detail.formation,
      GameRepository.instance.numbers.massBattle.stageFormations[nextStage.id],
    );
    expect(detail.waveCount, nextStage.massBattleWaveCount);
    expect(
      detail.enemyTotal,
      nextStage.massBattleEnemyCounts!.fold<int>(
        0,
        (sum, value) => sum + value,
      ),
    );
    expect(
      detail.enemies.map((enemy) => enemy.name),
      nextStage.enemyTeam.map((enemy) => enemy.name),
    );
    expect(detail.rewardRumor, isNotNull);
    expect(detail.baseExpReward, nextStage.baseExpReward);
    expect(detail.participantId, 7);
    expect(detail.participantName, '沈掌门');
  });

  test('五关全通时无下一关情报但保留真实参与者', () async {
    await seedLeader();
    final detail = await readDetail(const [
      'stage_06_05',
      'stage_mass_battle_01',
      'stage_mass_battle_02',
      'stage_mass_battle_03',
      'stage_mass_battle_04',
      'stage_mass_battle_05',
    ]);

    expect(detail.isComplete, isTrue);
    expect(detail.nextStageId, isNull);
    expect(detail.recommendedRealm, isNull);
    expect(detail.formation, isNull);
    expect(detail.waveCount, isNull);
    expect(detail.enemyTotal, isNull);
    expect(detail.enemies, isEmpty);
    expect(detail.rewardRumor, isNull);
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

  test('守城解锁前或进度断链时 fail closed', () async {
    await seedLeader();
    await expectLater(readDetail(const []), throwsA(isA<StateError>()));
    await expectLater(
      readDetail(const ['stage_06_05', 'stage_mass_battle_02']),
      throwsA(isA<StateError>()),
    );
  });

  group('守城地点解锁图 fail closed', () {
    MassBattleDef graph(Map<String, String> edges) => MassBattleDef(
      formations: const {},
      waveIntermission: const MassBattleWaveIntermission.defaults(),
      stageFormations: const {
        'stage_mass_battle_01': Formation.yanXing,
        'stage_mass_battle_02': Formation.baGua,
        'stage_mass_battle_03': Formation.fengShi,
        'stage_mass_battle_04': Formation.yanXing,
      },
      unlockTriggers: edges,
    );

    test('合法单链按生产顺序返回', () {
      expect(
        validatedMassBattleLocationStageIds(
          graph(const {
            'stage_06_05': 'stage_mass_battle_01',
            'stage_mass_battle_01': 'stage_mass_battle_02',
            'stage_mass_battle_02': 'stage_mass_battle_03',
            'stage_mass_battle_03': 'stage_mass_battle_04',
          }),
        ),
        const [
          'stage_mass_battle_01',
          'stage_mass_battle_02',
          'stage_mass_battle_03',
          'stage_mass_battle_04',
        ],
      );
    });

    test('脱离根链的环不会永久遍历', () {
      expect(
        () => validatedMassBattleLocationStageIds(
          graph(const {
            'stage_06_05': 'stage_mass_battle_01',
            'stage_mass_battle_01': 'stage_mass_battle_02',
            'stage_mass_battle_03': 'stage_mass_battle_04',
            'stage_mass_battle_04': 'stage_mass_battle_03',
          }),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('多根或汇合分支拒绝', () {
      expect(
        () => validatedMassBattleLocationStageIds(
          graph(const {
            'stage_06_05': 'stage_mass_battle_01',
            'stage_alt_gate': 'stage_mass_battle_02',
            'stage_mass_battle_01': 'stage_mass_battle_02',
            'stage_mass_battle_02': 'stage_mass_battle_03',
          }),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('截断链拒绝', () {
      expect(
        () => validatedMassBattleLocationStageIds(
          graph(const {
            'stage_06_05': 'stage_mass_battle_01',
            'stage_mass_battle_01': 'stage_mass_battle_02',
            'stage_mass_battle_02': 'stage_mass_battle_03',
          }),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
