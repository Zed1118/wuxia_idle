import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/cultivation/application/technique_learn_flow_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';

import '../../../support/test_data.dart';
import '../../../support/isar_test_support.dart';

void main() {
  late GameRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_learn_flow_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  tearDownAll(GameRepository.resetForTest);

  // 学徒境界 → cap = ruMenGong；xueTu 全阶只可学 ruMenGong 心法。
  Character makeApprentice({int insightPoints = 1000, int? mainTechniqueId}) {
    final realm = repository.getRealm(RealmTier.xueTu, RealmLayer.qiMeng);
    return Character.create(
      name: '祖师',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 7, 14),
      internalForce: realm.internalForceMax,
      internalForceMax: realm.internalForceMax,
      experienceToNextLayer: realm.experienceToNext,
      insightPoints: insightPoints,
      mainTechniqueId: mainTechniqueId,
    )..id = 1;
  }

  Future<int> seed(Character ch) async {
    final isar = IsarSetup.instance;
    return isar.writeTxn(() => isar.characters.put(ch));
  }

  test('学辅修成功：落库 + 扣点 + assist 列表 + 事件行', () async {
    final isar = IsarSetup.instance;
    await seed(makeApprentice(insightPoints: 300));
    final service = TechniqueLearnFlowService(isar);

    final result = await service.learn(
      characterId: 1,
      techniqueDefId: 'tech_gangmeng_jichu',
      role: TechniqueRole.assist,
    );

    expect(result.status, TechniqueLearnFlowStatus.success);
    expect(result.pointsSpent, repository.numbers.learningCost.assist);
    expect(result.remainingInsightPoints, 300 - result.pointsSpent);

    final ch = await isar.characters.get(1);
    expect(ch!.insightPoints, 300 - result.pointsSpent);
    expect(ch.assistTechniqueIds, contains(result.learnedTechniqueId));
    final tech = await isar.techniques.get(result.learnedTechniqueId!);
    expect(tech!.defId, 'tech_gangmeng_jichu');
    expect(tech.role, TechniqueRole.assist);

    final events = await isar.gameEvents.where().findAll();
    expect(
      events.where((e) => e.eventType == GameEventType.techniqueLearned),
      hasLength(1),
    );
  });

  test('无主修时学主修成功：写 mainTechniqueId', () async {
    final isar = IsarSetup.instance;
    await seed(makeApprentice(insightPoints: 1000));
    final service = TechniqueLearnFlowService(isar);

    final result = await service.learn(
      characterId: 1,
      techniqueDefId: 'tech_gangmeng_jichu',
      role: TechniqueRole.main,
    );

    expect(result.status, TechniqueLearnFlowStatus.success);
    final ch = await isar.characters.get(1);
    expect(ch!.mainTechniqueId, result.learnedTechniqueId);
    expect(result.pointsSpent, repository.numbers.learningCost.main);
  });

  test('已持有同心法 → alreadyOwned 拒绝，零副作用', () async {
    final isar = IsarSetup.instance;
    await seed(makeApprentice(insightPoints: 1000));
    final service = TechniqueLearnFlowService(isar);
    await service.learn(
      characterId: 1,
      techniqueDefId: 'tech_gangmeng_jichu',
      role: TechniqueRole.assist,
    );
    final insightAfterFirst = (await isar.characters.get(1))!.insightPoints;

    final second = await service.learn(
      characterId: 1,
      techniqueDefId: 'tech_gangmeng_jichu',
      role: TechniqueRole.assist,
    );

    expect(second.status, TechniqueLearnFlowStatus.alreadyOwned);
    expect((await isar.characters.get(1))!.insightPoints, insightAfterFirst);
    expect(
      await isar.techniques.filter().ownerCharacterIdEqualTo(1).count(),
      1,
    );
  });

  test('境界不足学高阶 → techniqueTierTooHigh（§5.3 三系锁死），零副作用', () async {
    final isar = IsarSetup.instance;
    await seed(makeApprentice(insightPoints: 1000));
    final service = TechniqueLearnFlowService(isar);

    // 找一本高于 ruMenGong 的心法 def。
    final highTierDef = repository.techniqueDefs.values.firstWhere(
      (d) => d.tier.index > TechniqueTier.ruMenGong.index,
    );

    final result = await service.learn(
      characterId: 1,
      techniqueDefId: highTierDef.id,
      role: TechniqueRole.assist,
    );

    expect(result.status, TechniqueLearnFlowStatus.techniqueTierTooHigh);
    expect((await isar.characters.get(1))!.insightPoints, 1000);
    expect(
      await isar.techniques.filter().ownerCharacterIdEqualTo(1).count(),
      0,
    );
    expect(await isar.gameEvents.where().count(), 0);
  });

  test('主修已存在再学主修 → mainTechniqueAlreadyExists', () async {
    final isar = IsarSetup.instance;
    await seed(makeApprentice(insightPoints: 2000, mainTechniqueId: 999));
    final service = TechniqueLearnFlowService(isar);

    final result = await service.learn(
      characterId: 1,
      techniqueDefId: 'tech_gangmeng_jichu',
      role: TechniqueRole.main,
    );

    expect(result.status, TechniqueLearnFlowStatus.mainTechniqueAlreadyExists);
    expect((await isar.characters.get(1))!.insightPoints, 2000);
  });

  test('领悟点不足 → insufficientInsightPoints，零副作用', () async {
    final isar = IsarSetup.instance;
    await seed(makeApprentice(insightPoints: 1));
    final service = TechniqueLearnFlowService(isar);

    final result = await service.learn(
      characterId: 1,
      techniqueDefId: 'tech_gangmeng_jichu',
      role: TechniqueRole.assist,
    );

    expect(result.status, TechniqueLearnFlowStatus.insufficientInsightPoints);
    expect((await isar.characters.get(1))!.insightPoints, 1);
    expect(
      await isar.techniques.filter().ownerCharacterIdEqualTo(1).count(),
      0,
    );
  });

  test('角色不存在 → characterMissing', () async {
    final isar = IsarSetup.instance;
    final service = TechniqueLearnFlowService(isar);

    final result = await service.learn(
      characterId: 42,
      techniqueDefId: 'tech_gangmeng_jichu',
      role: TechniqueRole.assist,
    );

    expect(result.status, TechniqueLearnFlowStatus.characterMissing);
  });

  test('心法 def 不存在 → techniqueDefMissing', () async {
    final isar = IsarSetup.instance;
    await seed(makeApprentice());
    final service = TechniqueLearnFlowService(isar);

    final result = await service.learn(
      characterId: 1,
      techniqueDefId: 'tech_not_a_real_def',
      role: TechniqueRole.assist,
    );

    expect(result.status, TechniqueLearnFlowStatus.techniqueDefMissing);
  });

  test('在途活动成员研习 → characterOccupied 零副作用（07-21 审查 P1-5.1）', () async {
    final isar = IsarSetup.instance;
    await seed(makeApprentice(insightPoints: 300));
    await isar.writeTxn(() async {
      await isar.expeditionRuns.put(
        ExpeditionRun()
          ..saveDataId = 0
          ..policy = ExpeditionPolicy.yiZhanLiXing
          ..seed = 1
          ..departedAt = DateTime(2026, 7, 16)
          ..currentNode = 1
          ..members = [
            ActivityMemberSnapshot()
              ..characterId = 1
              ..reservedEquipmentIds = []
              ..reservedTechniqueIds = []
              ..currentHp = 100
              ..currentQi = 50
              ..isDowned = false,
          ]
          ..stagedRewards = [],
      );
    });
    final service = TechniqueLearnFlowService(isar);

    final result = await service.learn(
      characterId: 1,
      techniqueDefId: 'tech_gangmeng_jichu',
      role: TechniqueRole.assist,
    );

    expect(result.status, TechniqueLearnFlowStatus.characterOccupied);
    final ch = await isar.characters.get(1);
    expect(ch!.insightPoints, 300, reason: '失败态零副作用');
    expect(ch.assistTechniqueIds, isEmpty);
  });
}
