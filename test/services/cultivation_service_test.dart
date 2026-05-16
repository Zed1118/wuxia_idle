import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/skill_usage_entry.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/services/cultivation_service.dart';

/// T24 CultivationService 验收（phase2_tasks T24 §269-293）。
///
/// 数值锚点（numbers.yaml `techniques.cultivation.progress_to_next`）：
///   chuKui → xiaoCheng     100
///   xiaoCheng → zhongCheng 250
///   zhongCheng → daCheng   500
///   daCheng → yuanMan      900
///   yuanMan → dianFeng    1500
///   dianFeng → tongShen   2500
///   tongShen → wuXia      4000
///   wuXia → jiJing        6500
///   总和 = 16250
void main() {
  late Map<CultivationLayer, int> progressMap;

  setUpAll(() async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    progressMap = repo.numbers.cultivationProgressToNext;
  });

  Technique newTech({
    CultivationLayer layer = CultivationLayer.chuKui,
    int progress = 0,
    int progressToNext = 100,
  }) =>
      Technique.create(
        defId: 'tech_test',
        ownerCharacterId: 1,
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: DateTime(2026, 5, 11),
        cultivationLayer: layer,
        cultivationProgress: progress,
        cultivationProgressToNext: progressToNext,
      );

  // ────────────────────────────────────────────────────────────────────────────
  // yaml 解析
  // ────────────────────────────────────────────────────────────────────────────

  group('cultivationProgressToNext 解析', () {
    test('8 个 entry（jiJing 无下一层不收录）', () {
      expect(progressMap.length, 8);
      expect(progressMap.containsKey(CultivationLayer.jiJing), isFalse);
    });

    test('数值与 yaml 一致：100/250/500/900/1500/2500/4000/6500', () {
      expect(progressMap[CultivationLayer.chuKui], 100);
      expect(progressMap[CultivationLayer.xiaoCheng], 250);
      expect(progressMap[CultivationLayer.zhongCheng], 500);
      expect(progressMap[CultivationLayer.daCheng], 900);
      expect(progressMap[CultivationLayer.yuanMan], 1500);
      expect(progressMap[CultivationLayer.dianFeng], 2500);
      expect(progressMap[CultivationLayer.tongShen], 4000);
      expect(progressMap[CultivationLayer.wuXia], 6500);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 累积 + 升层主流程
  // ────────────────────────────────────────────────────────────────────────────

  group('recordSkillUsage', () {
    test('单次累积不升层：chuKui progress 0 → 1', () {
      final t = newTech();
      final r = CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_a',
        progressToNextMap: progressMap,
      );
      expect(r.didLevelUp, isFalse);
      expect(r.layersGained, 0);
      expect(r.oldLayer, CultivationLayer.chuKui);
      expect(r.newLayer, CultivationLayer.chuKui);
      expect(t.cultivationLayer, CultivationLayer.chuKui);
      expect(t.cultivationProgress, 1);
      expect(t.cultivationProgressToNext, 100);
    });

    test('跨层 +1：chuKui progress=99 + 1 → xiaoCheng progress=0 / progressToNext=250', () {
      final t = newTech(progress: 99);
      final r = CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_a',
        progressToNextMap: progressMap,
      );
      expect(r.didLevelUp, isTrue);
      expect(r.layersGained, 1);
      expect(r.oldLayer, CultivationLayer.chuKui);
      expect(r.newLayer, CultivationLayer.xiaoCheng);
      expect(t.cultivationProgress, 0);
      expect(t.cultivationProgressToNext, 250);
    });

    test('多层连升：chuKui +1000 → daCheng（100+250+500=850 用完，剩 150）', () {
      final t = newTech();
      final r = CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_a',
        progressToNextMap: progressMap,
        delta: 1000,
      );
      expect(r.layersGained, 3);
      expect(r.newLayer, CultivationLayer.daCheng);
      expect(t.cultivationProgress, 150);
      expect(t.cultivationProgressToNext, 900);
    });

    test('一次塞 5000 progress：chuKui → tongShen（100+250+500+900+1500+2500=5750>5000 → 停在 tongShen 前一层 dianFeng？）', () {
      // 100+250+500+900+1500=3250 升到 dianFeng；剩 5000-3250=1750
      // dianFeng 升下层需 2500，1750 不够，停在 dianFeng
      final t = newTech();
      final r = CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_a',
        progressToNextMap: progressMap,
        delta: 5000,
      );
      expect(r.layersGained, 5);
      expect(r.newLayer, CultivationLayer.dianFeng);
      expect(t.cultivationProgress, 1750);
      expect(t.cultivationProgressToNext, 2500);
    });

    test('9 层全升刚好用完：chuKui +16250 → jiJing progress=0', () {
      final t = newTech();
      final r = CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_a',
        progressToNextMap: progressMap,
        delta: 16250,
      );
      expect(r.layersGained, 8);
      expect(r.newLayer, CultivationLayer.jiJing);
      expect(t.cultivationProgress, 0);
      expect(t.cultivationProgressToNext, 6500); // 保留升上来时的值，作为封顶
    });

    test('9 层全升超出封顶：chuKui +30000 → jiJing progress 封顶 6500（剩 13750 被截）', () {
      // 升满消耗 16250，剩 30000-16250=13750；jiJing 封顶 progressToNext=6500
      final t = newTech();
      final r = CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_a',
        progressToNextMap: progressMap,
        delta: 30000,
      );
      expect(r.newLayer, CultivationLayer.jiJing);
      expect(t.cultivationProgress, 6500);
      expect(t.cultivationProgressToNext, 6500);
    });

    test('9 层全升不封顶：chuKui +20000 → jiJing progress=3750（未超 6500 不截）', () {
      final t = newTech();
      final r = CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_a',
        progressToNextMap: progressMap,
        delta: 20000,
      );
      expect(r.newLayer, CultivationLayer.jiJing);
      expect(t.cultivationProgress, 3750); // 20000-16250
    });

    test('已在 jiJing 再加 10000：progress 不超过 progressToNext', () {
      final t = newTech(
        layer: CultivationLayer.jiJing,
        progress: 0,
        progressToNext: 6500,
      );
      final r = CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_a',
        progressToNextMap: progressMap,
        delta: 10000,
      );
      expect(r.didLevelUp, isFalse);
      expect(r.layersGained, 0);
      expect(r.oldLayer, CultivationLayer.jiJing);
      expect(r.newLayer, CultivationLayer.jiJing);
      expect(t.cultivationProgress, 6500); // 封顶
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // skillUsageCount 累计
  // ────────────────────────────────────────────────────────────────────────────

  group('skillUsageCount', () {
    test('同 skillId 多次调用：count 单调累加', () {
      final t = newTech();
      CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_a',
        progressToNextMap: progressMap,
      );
      CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_a',
        progressToNextMap: progressMap,
        delta: 5,
      );
      expect(t.skillUsageCount.countOf('skill_a'), 6);
    });

    test('不同 skillId 各自独立累加', () {
      final t = newTech();
      CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_a',
        progressToNextMap: progressMap,
        delta: 3,
      );
      CultivationService.recordSkillUsage(
        tech: t,
        skillId: 'skill_b',
        progressToNextMap: progressMap,
        delta: 7,
      );
      expect(t.skillUsageCount.countOf('skill_a'), 3);
      expect(t.skillUsageCount.countOf('skill_b'), 7);
      // cultivationProgress 应是两次 delta 之和
      expect(t.cultivationProgress, 10);
    });
  });
}
