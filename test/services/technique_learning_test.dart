import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/services/technique_learning.dart';

/// T23 TechniqueLearningService 验收（phase2_tasks T23 §244-265）。
///
/// 校验顺序固定：tier → 主修存在 → 辅修槽满 → 领悟点不足。
/// 服务只构造 Technique 实例，副作用（写 Isar / 改 Character）归调用方。
void main() {
  late LearningCostConfig cost;

  setUpAll(() async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    cost = repo.numbers.learningCost;
  });

  Character newChar({
    RealmTier tier = RealmTier.erLiu,
    RealmLayer layer = RealmLayer.qiMeng,
    int? mainTechniqueId,
    List<int>? assistTechniqueIds,
  }) =>
      Character.create(
        name: '测试者',
        realmTier: tier,
        realmLayer: layer,
        attributes: Attributes()
          ..constitution = 5
          ..enlightenment = 5
          ..agility = 5
          ..fortune = 5,
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026, 5, 11),
        mainTechniqueId: mainTechniqueId,
        assistTechniqueIds: assistTechniqueIds,
      );

  TechniqueDef defWith({
    String id = 'tech_test',
    TechniqueTier tier = TechniqueTier.ruMenGong,
    TechniqueSchool school = TechniqueSchool.gangMeng,
  }) =>
      TechniqueDef(
        id: id,
        name: '测试心法',
        tier: tier,
        school: school,
        description: '',
        skillIds: const [],
        internalForceGrowthBonus: 1.0,
        speedBonus: 0,
        acquireSourceTags: const [],
      );

  final now = DateTime(2026, 5, 11, 12);

  // ────────────────────────────────────────────────────────────────────────────
  // LearningCostConfig 解析
  // ────────────────────────────────────────────────────────────────────────────

  group('LearningCostConfig', () {
    test('从 yaml 解析：assist=100 / main=500', () {
      expect(cost.assist, 100);
      expect(cost.main, 500);
    });

    test('costFor 按 role 路由', () {
      expect(cost.costFor(TechniqueRole.main), 500);
      expect(cost.costFor(TechniqueRole.assist), 100);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 失败分支（4 类）
  // ────────────────────────────────────────────────────────────────────────────

  group('校验失败', () {
    test('tier 上限：学徒学名家功（tier 3 > cap tier 1）→ techniqueTierTooHigh', () {
      final r = TechniqueLearningService.learn(
        ch: newChar(tier: RealmTier.xueTu),
        def: defWith(tier: TechniqueTier.mingJiaGong),
        role: TechniqueRole.assist,
        currentInsightPoints: 99999,
        costConfig: cost,
        learnedAt: now,
      );
      expect(r.outcome, LearnOutcome.techniqueTierTooHigh);
      expect(r.technique, isNull);
      expect(r.pointsSpent, 0);
    });

    test('主修已存在：mainTechniqueId 非 null + role=main → mainTechniqueAlreadyExists', () {
      final r = TechniqueLearningService.learn(
        ch: newChar(mainTechniqueId: 42),
        def: defWith(),
        role: TechniqueRole.main,
        currentInsightPoints: 99999,
        costConfig: cost,
        learnedAt: now,
      );
      expect(r.outcome, LearnOutcome.mainTechniqueAlreadyExists);
    });

    test('辅修槽满 3：assistTechniqueIds.length=3 + role=assist → assistSlotsFull', () {
      final r = TechniqueLearningService.learn(
        ch: newChar(assistTechniqueIds: [1, 2, 3]),
        def: defWith(),
        role: TechniqueRole.assist,
        currentInsightPoints: 99999,
        costConfig: cost,
        learnedAt: now,
      );
      expect(r.outcome, LearnOutcome.assistSlotsFull);
    });

    test('领悟点不足：499 学主修（需 500）→ insufficientInsightPoints', () {
      final r = TechniqueLearningService.learn(
        ch: newChar(),
        def: defWith(),
        role: TechniqueRole.main,
        currentInsightPoints: 499,
        costConfig: cost,
        learnedAt: now,
      );
      expect(r.outcome, LearnOutcome.insufficientInsightPoints);
    });

    test('校验顺序：tier 优先于领悟点（学徒学名家功 + 0 领悟点 → 仍报 tier）', () {
      final r = TechniqueLearningService.learn(
        ch: newChar(tier: RealmTier.xueTu),
        def: defWith(tier: TechniqueTier.mingJiaGong),
        role: TechniqueRole.assist,
        currentInsightPoints: 0,
        costConfig: cost,
        learnedAt: now,
      );
      expect(r.outcome, LearnOutcome.techniqueTierTooHigh);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // 成功路径
  // ────────────────────────────────────────────────────────────────────────────

  group('学习成功', () {
    test('主修学习：消耗 500，返回 Technique(role=main, tier 与 def 一致)', () {
      final r = TechniqueLearningService.learn(
        ch: newChar(),
        def: defWith(
          id: 'tech_gangmeng_mingjia',
          tier: TechniqueTier.mingJiaGong,
          school: TechniqueSchool.gangMeng,
        ),
        role: TechniqueRole.main,
        currentInsightPoints: 1000,
        costConfig: cost,
        learnedAt: now,
      );
      expect(r.outcome, LearnOutcome.success);
      expect(r.pointsSpent, 500);
      expect(r.technique, isNotNull);
      expect(r.technique!.defId, 'tech_gangmeng_mingjia');
      expect(r.technique!.tier, TechniqueTier.mingJiaGong);
      expect(r.technique!.school, TechniqueSchool.gangMeng);
      expect(r.technique!.role, TechniqueRole.main);
      expect(r.technique!.cultivationLayer, CultivationLayer.chuKui);
      expect(r.technique!.cultivationProgress, 0);
      expect(r.technique!.learnedAt, now);
    });

    test('辅修学习：消耗 100，role=assist；assistTechniqueIds=[1,2] 槽未满', () {
      final r = TechniqueLearningService.learn(
        ch: newChar(assistTechniqueIds: [1, 2]),
        def: defWith(tier: TechniqueTier.changLianGong),
        role: TechniqueRole.assist,
        currentInsightPoints: 100,
        costConfig: cost,
        learnedAt: now,
      );
      expect(r.outcome, LearnOutcome.success);
      expect(r.pointsSpent, 100);
      expect(r.technique!.role, TechniqueRole.assist);
    });

    test('刚好达 tier 上限可学（二流学名家功 tier 3 = cap tier 3）', () {
      final r = TechniqueLearningService.learn(
        ch: newChar(tier: RealmTier.erLiu),
        def: defWith(tier: TechniqueTier.mingJiaGong),
        role: TechniqueRole.assist,
        currentInsightPoints: 100,
        costConfig: cost,
        learnedAt: now,
      );
      expect(r.outcome, LearnOutcome.success);
    });
  });
}
