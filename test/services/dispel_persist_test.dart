import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/models/attributes.dart';
import 'package:wuxia_idle/data/models/character.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/technique.dart';
import 'package:wuxia_idle/services/dispel_service.dart';

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
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
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

    await DispelService.persistResult(
      ch: ch,
      mainTech: mainTech,
      newMainTech: assistTech,
      isar: isar,
    );

    // 关闭再读，验证落盘
    final chId = ch.id;
    final mainId = mainTech.id;
    final assistId = assistTech.id;
    await IsarSetup.close();
    await IsarSetup.init(directory: tempDir, inspector: false);
    final isar2 = IsarSetup.instance;

    final chBack = await isar2.characters.get(chId);
    expect(chBack, isNotNull);
    expect(chBack!.internalForce, ifBefore ~/ 2,
        reason: '内力 ×0.5 应落盘');
    expect(chBack.mainTechniqueId, assistId,
        reason: 'mainTechniqueId 应切到新主修');
    expect(chBack.assistTechniqueIds, contains(mainId),
        reason: '旧主修挪入辅修');
    expect(chBack.assistTechniqueIds, isNot(contains(assistId)),
        reason: '新主修不再在辅修槽');

    final mainBack = await isar2.techniques.get(mainId);
    expect(mainBack, isNotNull);
    expect(mainBack!.role, TechniqueRole.assist,
        reason: '旧主修 role=assist 应落盘');
    expect(mainBack.cultivationProgress, progressBefore ~/ 2,
        reason: 'progress ×0.5 应落盘');

    final newMainBack = await isar2.techniques.get(assistId);
    expect(newMainBack, isNotNull);
    expect(newMainBack!.role, TechniqueRole.main,
        reason: '新主修 role=main 应落盘');
  });
}
