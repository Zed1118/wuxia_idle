import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/cultivation/application/insight_exchange_service.dart';

/// 根因A(2026-05-29):insightPoints 凝练兑换主修修炼度 sink。
void main() {
  late Directory tempDir;
  const kCharId = 7;
  const kTechId = 70;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_insight_test_');
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

  // 播种:角色 + 主修心法(初窥,progress 0,toNext 100),insightPoints 可配。
  Future<void> seed({
    required int insightPoints,
    bool withMainTech = true,
    int progress = 0,
  }) async {
    final ch = Character.create(
      name: 'hero',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 1, 1),
      insightPoints: insightPoints,
    )..id = kCharId;
    if (withMainTech) {
      ch.mainTechniqueId = kTechId;
    }
    final tech = Technique.create(
      defId: 'tech_test',
      ownerCharacterId: kCharId,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 1, 1),
      cultivationProgress: progress,
    )..id = kTechId;
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.characters.put(ch);
      await IsarSetup.instance.techniques.put(tech);
    });
  }

  test('凝练 50 → 主修 progress +50,insightPoints 50→0(ratio 1.0)', () async {
    expect(GameRepository.instance.numbers.insightToCultivationRatio, 1.0);
    await seed(insightPoints: 50);
    final svc = InsightExchangeService(IsarSetup.instance);
    final r = await svc.refine(characterId: kCharId, insightSpend: 50);

    expect(r.status, InsightRefineStatus.success);
    expect(r.progressGained, 50);
    expect(r.didLevelUp, isFalse);
    expect(r.remainingInsight, 0);

    final tech = await IsarSetup.instance.techniques.get(kTechId);
    expect(tech?.cultivationProgress, 50);
    final ch = await IsarSetup.instance.characters.get(kCharId);
    expect(ch?.insightPoints, 0);
  });

  test('凝练 100 → 初窥→小成 升 1 层(toNext 100)', () async {
    await seed(insightPoints: 100);
    final svc = InsightExchangeService(IsarSetup.instance);
    final r = await svc.refine(characterId: kCharId, insightSpend: 100);

    expect(r.status, InsightRefineStatus.success);
    expect(r.didLevelUp, isTrue);
    expect(r.layersGained, 1);
    final tech = await IsarSetup.instance.techniques.get(kTechId);
    expect(tech?.cultivationLayer, CultivationLayer.xiaoCheng);
  });

  test('领悟点不足 → insufficientInsight,无任何改动', () async {
    await seed(insightPoints: 30);
    final svc = InsightExchangeService(IsarSetup.instance);
    final r = await svc.refine(characterId: kCharId, insightSpend: 100);

    expect(r.status, InsightRefineStatus.insufficientInsight);
    expect(r.remainingInsight, 30);
    final tech = await IsarSetup.instance.techniques.get(kTechId);
    expect(tech?.cultivationProgress, 0, reason: '不足时不改 progress');
    final ch = await IsarSetup.instance.characters.get(kCharId);
    expect(ch?.insightPoints, 30, reason: '不足时不扣点');
  });

  test('未设主修 → noMainTechnique', () async {
    await seed(insightPoints: 50, withMainTech: false);
    final svc = InsightExchangeService(IsarSetup.instance);
    final r = await svc.refine(characterId: kCharId, insightSpend: 50);
    expect(r.status, InsightRefineStatus.noMainTechnique);
    final ch = await IsarSetup.instance.characters.get(kCharId);
    expect(ch?.insightPoints, 50, reason: '无主修不扣点');
  });

  test('消费量 ≤ 0 → invalidAmount', () async {
    await seed(insightPoints: 50);
    final svc = InsightExchangeService(IsarSetup.instance);
    final r = await svc.refine(characterId: kCharId, insightSpend: 0);
    expect(r.status, InsightRefineStatus.invalidAmount);
  });
}
