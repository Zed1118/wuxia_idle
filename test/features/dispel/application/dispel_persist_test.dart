import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/dispel/application/dispel_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import "../../../support/isar_test_support.dart";
import '../../../support/test_data.dart';

/// T32 #22b DispelService.persistResult 真 Isar 落地测试。
///
/// 测点：dispel 后 putAll 3 个对象（ch / 旧 mainTech / 新 mainTech），关闭再读
/// 字段全部一致：
/// - ch.internalForce -50% / mainTechniqueId 切到新主修
/// - oldMain.role=assist + cultivationProgress ×0.5 + layer 回退
/// - newMain.role=main
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_dispel_persist_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('dispel + persistResult → 关闭再读，3 个对象字段全部落地', () async {
    final isar = IsarSetup.instance;

    final ch = Character.create(
      name: '测试者',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 5, 11),
      internalForce: 10000,
      internalForceMax: 15000,
      school: TechniqueSchool.gangMeng,
    );
    final mainTech = Technique.create(
      defId: 'tech_main',
      ownerCharacterId: 0,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 5, 11),
      cultivationLayer: CultivationLayer.yuanMan,
      cultivationProgress: 1500,
      cultivationProgressToNext: 2000,
    );
    final assistTech = Technique.create(
      defId: 'tech_assist',
      ownerCharacterId: 0,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.assist,
      learnedAt: DateTime(2026, 5, 11),
      cultivationLayer: CultivationLayer.chuKui,
      cultivationProgress: 0,
      cultivationProgressToNext: 100,
    );

    // 先 put 拿到 id，再回填 ownerCharacterId + mainTechniqueId/assistTechniqueIds
    await isar.writeTxn(() async {
      await isar.characters.put(ch);
      await isar.techniques.put(mainTech);
      await isar.techniques.put(assistTech);
    });
    mainTech.ownerCharacterId = ch.id;
    assistTech.ownerCharacterId = ch.id;
    ch.mainTechniqueId = mainTech.id;
    ch.assistTechniqueIds = [assistTech.id];
    await isar.writeTxn(() async {
      await isar.characters.put(ch);
      await isar.techniques.put(mainTech);
      await isar.techniques.put(assistTech);
    });

    final ifBefore = ch.internalForce;
    final progressBefore = mainTech.cultivationProgress;

    final result = DispelService.dispel(
      ch: ch,
      mainTech: mainTech,
      newMainTech: assistTech,
      n: GameRepository.instance.numbers,
    );
    expect(result.success, isTrue);

    await DispelService(
      isar: IsarSetup.instance,
    ).persistResult(ch: ch, mainTech: mainTech, newMainTech: assistTech);

    // 关闭再读，验证落盘
    final chId = ch.id;
    final mainId = mainTech.id;
    final assistId = assistTech.id;
    await IsarSetup.close();
    await IsarSetup.init(directory: tempDir, inspector: false);
    final isar2 = IsarSetup.instance;

    final chBack = await isar2.characters.get(chId);
    expect(chBack, isNotNull);
    expect(chBack!.internalForce, ifBefore, reason: '散功不再永久扣内力');
    expect(
      chBack.innerBreathDisorderHoursRemaining,
      greaterThan(0),
      reason: '内息紊乱应落盘',
    );
    expect(chBack.mainTechniqueId, assistId, reason: 'mainTechniqueId 应切到新主修');
    expect(chBack.assistTechniqueIds, contains(mainId), reason: '旧主修挪入辅修');
    expect(
      chBack.assistTechniqueIds,
      isNot(contains(assistId)),
      reason: '新主修不再在辅修槽',
    );

    final mainBack = await isar2.techniques.get(mainId);
    expect(mainBack, isNotNull);
    expect(mainBack!.role, TechniqueRole.assist, reason: '旧主修 role=assist 应落盘');
    expect(
      mainBack.cultivationProgress,
      progressBefore ~/ 2,
      reason: 'progress ×0.5 应落盘',
    );

    final newMainBack = await isar2.techniques.get(assistId);
    expect(newMainBack, isNotNull);
    expect(newMainBack!.role, TechniqueRole.main, reason: '新主修 role=main 应落盘');
  });

  group('活动占用契约守卫（07-22 #58 Gate 发现补接）', () {
    Character occChar(int id, {int? retreatSessionId}) {
      final c = Character.create(
        name: '门人$id',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026, 7, 16),
      );
      c.id = id;
      c.currentRetreatSessionId = retreatSessionId;
      return c;
    }

    test('闭关/远征/断魂庄在途 → 占用；无活动 → 不占用', () async {
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        await isar.characters.put(occChar(1));
        await isar.characters.put(occChar(2, retreatSessionId: 7));
      });
      final svc = DispelService(isar: isar);

      expect(await svc.isCharacterOccupied(1), isFalse, reason: '无活动');
      expect(await svc.isCharacterOccupied(2), isTrue, reason: '闭关在途');

      // 闭关解除 → 改远征在途（run 成员快照占用）。
      await isar.writeTxn(() async {
        final ch = (await isar.characters.get(2))!
          ..currentRetreatSessionId = null;
        await isar.characters.put(ch);
        await isar.expeditionRuns.put(
          ExpeditionRun()
            ..saveDataId = 0
            ..policy = ExpeditionPolicy.yiZhanLiXing
            ..seed = 1
            ..departedAt = DateTime(2026, 7, 16)
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
      expect(await svc.isCharacterOccupied(2), isFalse, reason: '闭关已解除');
      expect(await svc.isCharacterOccupied(1), isTrue, reason: '远征在途');
    });
  });
}
