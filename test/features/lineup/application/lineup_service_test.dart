import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/lineup/application/lineup_service.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

/// LineupService 校验矩阵(spec `2026-07-14-team-lineup-screen-design.md` §2/§5)。
///
/// 锚:`activeCharacterIds` 唯一真相源(列表序=站位序),`Character.isActive`
/// 镜像随写路径同步;祖师必在 / 1-3 人 / 闭关锁(增删拦、纯重排不拦)/
/// 已飞升太祖不可回场;失败态零副作用。
void main() {
  late GameRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_lineup_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  tearDownAll(GameRepository.resetForTest);

  // repository 仅用于确认测试数据境界表已加载(loadReserve 排序读 RealmDef)。
  Character makeChar({
    required int id,
    required String name,
    RealmTier tier = RealmTier.xueTu,
    RealmLayer layer = RealmLayer.qiMeng,
    bool isFounder = false,
    bool isActive = false,
    bool isAlive = true,
    int? currentRetreatSessionId,
    int? mainTechniqueId,
    LineageRole lineageRole = LineageRole.disciple,
  }) {
    final realm = repository.getRealm(tier, layer);
    return Character.create(
      name: name,
      realmTier: tier,
      realmLayer: layer,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: lineageRole,
      createdAt: DateTime(2026, 7, 14),
      internalForce: realm.internalForceMax,
      internalForceMax: realm.internalForceMax,
      experienceToNextLayer: realm.experienceToNext,
      isFounder: isFounder,
      isActive: isActive,
      isAlive: isAlive,
      currentRetreatSessionId: currentRetreatSessionId,
      mainTechniqueId: mainTechniqueId,
    )..id = id;
  }

  /// 主修 Technique 行(战斗组队硬前置:mainTechniqueId 指向的行必须在库)。
  Technique makeMainTech({required int id, required int ownerId}) {
    return Technique.create(
      defId: 'tech_gangmeng_jichu',
      ownerCharacterId: ownerId,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 7, 14),
      cultivationProgress: 0,
      cultivationProgressToNext: 100,
      cultivationLayer: CultivationLayer.chuKui,
    )..id = id;
  }

  /// 标准棋盘:祖师1 + 大弟子2 + 二弟子3 出战;替补4(E.1 式)、5(sect 式
  /// masterId=null);太祖9(isFounder + inactive = 已飞升)。
  Future<void> seedRoster({
    List<Character> extra = const [],
    List<int> active = const [1, 2, 3],
    int? founderCharacterId = 1,
  }) async {
    final isar = IsarSetup.instance;
    final chars = <Character>[
      makeChar(
        id: 1,
        name: '祖师',
        isFounder: true,
        isActive: true,
        lineageRole: LineageRole.founder,
        tier: RealmTier.erLiu,
        layer: RealmLayer.shuLian,
      ),
      makeChar(
        id: 2,
        name: '大弟子',
        isActive: true,
        lineageRole: LineageRole.senior,
        tier: RealmTier.sanLiu,
        layer: RealmLayer.ruMen,
      ),
      makeChar(
        id: 3,
        name: '二弟子',
        isActive: true,
        lineageRole: LineageRole.junior,
      ),
      makeChar(
        id: 4,
        name: '记名弟子',
        tier: RealmTier.sanLiu,
        mainTechniqueId: 904,
      ),
      makeChar(id: 5, name: '降将'),
      ...extra,
    ];
    await isar.writeTxn(() async {
      await isar.characters.putAll(chars);
      // 记名弟子已修主修(可上场);降将无主修(不可上场,战斗组队硬前置)。
      await isar.techniques.put(makeMainTech(id: 904, ownerId: 4));
      final save = SaveData()
        ..saveVersion = '0.36'
        ..createdAt = DateTime(2026, 7, 14)
        ..lastSavedAt = DateTime(2026, 7, 14)
        ..lastOnlineAt = DateTime(2026, 7, 14)
        ..founderCharacterId = founderCharacterId
        ..activeCharacterIds = List.of(active);
      await isar.saveDatas.put(save);
    });
  }

  Future<SaveData> readSave() async =>
      (await IsarSetup.instance.saveDatas.get(0))!;

  Future<Character> readChar(int id) async =>
      (await IsarSetup.instance.characters.get(id))!;

  group('apply 成功路径', () {
    test('换人:列表序=站位序落库,isActive 双向镜像', () async {
      await seedRoster();
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: [1, 4, 2]);

      expect(result.status, LineupApplyStatus.success);
      expect((await readSave()).activeCharacterIds, [1, 4, 2]);
      expect((await readChar(4)).isActive, isTrue, reason: '加入者镜像置真');
      expect((await readChar(3)).isActive, isFalse, reason: '移出者镜像置假');
      expect((await readChar(1)).isActive, isTrue);
      expect((await readChar(2)).isActive, isTrue);
    });

    test('缩编到仅祖师 1 人', () async {
      await seedRoster();
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: [1]);

      expect(result.status, LineupApplyStatus.success);
      expect((await readSave()).activeCharacterIds, [1]);
      expect((await readChar(2)).isActive, isFalse);
      expect((await readChar(3)).isActive, isFalse);
    });

    test('纯槽序重排:闭关中成员不拦(成员集不变)', () async {
      await seedRoster(extra: []);
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final c = await isar.characters.get(2);
        c!.currentRetreatSessionId = 77;
        await isar.characters.put(c);
      });
      final service = LineupService(isar);

      final result = await service.apply(newActiveIds: [2, 1, 3]);

      expect(result.status, LineupApplyStatus.success);
      expect((await readSave()).activeCharacterIds, [2, 1, 3]);
    });

    test('换人不动装备:移出者 equippedWeaponId 保留', () async {
      await seedRoster();
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final c = await isar.characters.get(3);
        c!.equippedWeaponId = 42;
        await isar.characters.put(c);
      });
      final service = LineupService(isar);

      await service.apply(newActiveIds: [1, 2]);

      expect((await readChar(3)).equippedWeaponId, 42);
    });
  });

  group('apply 校验拒绝(全部零副作用)', () {
    Future<void> expectNoSideEffect() async {
      expect((await readSave()).activeCharacterIds, [1, 2, 3]);
      expect((await readChar(4)).isActive, isFalse);
      expect((await readChar(2)).isActive, isTrue);
    }

    test('祖师缺席 → founderMissing', () async {
      await seedRoster();
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: [2, 4]);

      expect(result.status, LineupApplyStatus.founderMissing);
      await expectNoSideEffect();
    });

    test('空编成 → emptyLineup', () async {
      await seedRoster();
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: []);

      expect(result.status, LineupApplyStatus.emptyLineup);
      await expectNoSideEffect();
    });

    test('超 3 人 → tooMany', () async {
      await seedRoster();
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: [1, 2, 3, 4]);

      expect(result.status, LineupApplyStatus.tooMany);
      await expectNoSideEffect();
    });

    test('重复 id → duplicateIds', () async {
      await seedRoster();
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: [1, 2, 2]);

      expect(result.status, LineupApplyStatus.duplicateIds);
      await expectNoSideEffect();
    });

    test('不存在角色 → unknownCharacter', () async {
      await seedRoster();
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: [1, 2, 404]);

      expect(result.status, LineupApplyStatus.unknownCharacter);
      expect(result.offendingCharacterId, 404);
      await expectNoSideEffect();
    });

    test('已飞升太祖回场 → ascendedFounder', () async {
      await seedRoster(
        extra: [
          makeChar(
            id: 9,
            name: '太祖',
            isFounder: true,
            lineageRole: LineageRole.founder,
          ),
        ],
      );
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: [1, 9]);

      expect(result.status, LineupApplyStatus.ascendedFounder);
      expect(result.offendingCharacterId, 9);
      await expectNoSideEffect();
    });

    test('移除闭关中成员 → retreatLocked', () async {
      await seedRoster();
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final c = await isar.characters.get(3);
        c!.currentRetreatSessionId = 88;
        await isar.characters.put(c);
      });
      final service = LineupService(isar);

      final result = await service.apply(newActiveIds: [1, 2]);

      expect(result.status, LineupApplyStatus.retreatLocked);
      expect(result.offendingCharacterId, 3);
      await expectNoSideEffect();
    });

    test('加入闭关中替补 → retreatLocked', () async {
      await seedRoster(
        extra: [makeChar(id: 6, name: '闭关替补', currentRetreatSessionId: 99)],
      );
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: [1, 2, 6]);

      expect(result.status, LineupApplyStatus.retreatLocked);
      expect(result.offendingCharacterId, 6);
      await expectNoSideEffect();
    });

    test('加入非存活角色 → deadCharacter', () async {
      await seedRoster(extra: [makeChar(id: 7, name: '亡者', isAlive: false)]);
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: [1, 7]);

      expect(result.status, LineupApplyStatus.deadCharacter);
      await expectNoSideEffect();
    });

    test('加入无主修替补 → noMainTechnique(战斗组队硬前置)', () async {
      await seedRoster();
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: [1, 2, 5]);

      expect(result.status, LineupApplyStatus.noMainTechnique);
      expect(result.offendingCharacterId, 5);
      await expectNoSideEffect();
    });

    test('加入主修行悬空(Technique 缺失)→ noMainTechnique', () async {
      await seedRoster(
        extra: [makeChar(id: 8, name: '悬空主修', mainTechniqueId: 999)],
      );
      final service = LineupService(IsarSetup.instance);

      final result = await service.apply(newActiveIds: [1, 8]);

      expect(result.status, LineupApplyStatus.noMainTechnique);
      expect(result.offendingCharacterId, 8);
      await expectNoSideEffect();
    });

    test('SaveData 缺失 → saveMissing', () async {
      // IsarSetup.init 自带默认 SaveData(id=0),显式删行构造缺失态。
      final isar = IsarSetup.instance;
      await isar.writeTxn(() => isar.saveDatas.delete(0));
      final service = LineupService(isar);

      final result = await service.apply(newActiveIds: [1]);

      expect(result.status, LineupApplyStatus.saveMissing);
    });
  });

  group('loadReserve 替补池口径', () {
    test('含四管线式 inactive;排除出战/太祖/亡者;境界降序', () async {
      await seedRoster(
        extra: [
          makeChar(
            id: 9,
            name: '太祖',
            isFounder: true,
            lineageRole: LineageRole.founder,
          ),
          makeChar(id: 7, name: '亡者', isAlive: false),
          makeChar(
            id: 8,
            name: '高手替补',
            tier: RealmTier.yiLiu,
            layer: RealmLayer.jingTong,
          ),
        ],
      );
      final service = LineupService(IsarSetup.instance);

      final reserve = await service.loadReserve();

      expect(reserve.map((c) => c.id).toList(), [
        8,
        4,
        5,
      ], reason: '一流精通 > 三流启蒙 > 学徒启蒙;同级按 id 升序');
    });

    group('活动占用契约(07-21 审查 P1-5.1)', () {
      Future<void> seedExpeditionRun(List<int> memberIds) async {
        final isar = IsarSetup.instance;
        await isar.writeTxn(() async {
          await isar.expeditionRuns.put(
            ExpeditionRun()
              ..saveDataId = 0
              ..policy = ExpeditionPolicy.yiZhanLiXing
              ..seed = 1
              ..departedAt = DateTime(2026, 7, 16)
              ..currentNode = 2
              ..members = [
                for (final id in memberIds)
                  ActivityMemberSnapshot()
                    ..characterId = id
                    ..reservedEquipmentIds = []
                    ..reservedTechniqueIds = []
                    ..currentHp = 100
                    ..currentQi = 50
                    ..isDowned = false,
              ]
              ..stagedRewards = [],
          );
        });
      }

      test('在途远征成员禁换上:加入者拦 activityOccupied 且零副作用', () async {
        await seedRoster();
        await seedExpeditionRun([4]);
        final service = LineupService(IsarSetup.instance);

        final result = await service.apply(newActiveIds: [1, 2, 4]);

        expect(result.status, LineupApplyStatus.activityOccupied);
        expect(result.offendingCharacterId, 4);
        expect((await readSave()).activeCharacterIds, [
          1,
          2,
          3,
        ], reason: '失败态零副作用');
      });

      test('在途远征成员可换下:移出不拦(companion §8.1 Q5)', () async {
        await seedRoster();
        await seedExpeditionRun([2]);
        final service = LineupService(IsarSetup.instance);

        final result = await service.apply(newActiveIds: [1, 3]);

        expect(result.status, LineupApplyStatus.success);
        expect((await readSave()).activeCharacterIds, [1, 3]);
      });

      test('在途远征成员留阵纯重排不拦(成员集不变)', () async {
        await seedRoster();
        await seedExpeditionRun([2]);
        final service = LineupService(IsarSetup.instance);

        final result = await service.apply(newActiveIds: [2, 1, 3]);

        expect(result.status, LineupApplyStatus.success);
      });
    });

    test('替补池空(全员出战)→ 空列表', () async {
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        await isar.characters.put(
          makeChar(
            id: 1,
            name: '祖师',
            isFounder: true,
            isActive: true,
            lineageRole: LineageRole.founder,
          ),
        );
        final save = SaveData()
          ..saveVersion = '0.36'
          ..createdAt = DateTime(2026, 7, 14)
          ..lastSavedAt = DateTime(2026, 7, 14)
          ..lastOnlineAt = DateTime(2026, 7, 14)
          ..founderCharacterId = 1
          ..activeCharacterIds = [1];
        await isar.saveDatas.put(save);
      });
      final service = LineupService(isar);

      expect(await service.loadReserve(), isEmpty);
    });
  });
}
