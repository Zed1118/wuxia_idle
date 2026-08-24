import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/combat_shared/application/combat_resolution_service.dart';
import 'package:wuxia_idle/features/dispel/application/dispel_service.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_service.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

/// stage_entry_flow 纯函数面补强（试点 A 单 切片 1）。
///
/// 覆盖对象（stage_entry_flow.dart）：
///   - `buildDefeatLossEntries` Boss 散功半区组合矩阵：
///     didRollback 门控 old/newLayerLabel、injuryApplied 映射、
///     `_resolveTechName` 四条解析分支、散功+心魔同角色双 entry。
///     （心魔半区已由 inner_demon_defeat_summary_test.dart 覆盖，此处不重复。）
///   - `shouldSkipScrollDrop` 三态直测。
///   - `buildDefeatLossBanner` → `_DefeatLossBanner`
///     未测分支：空 entries 早返、伤势汇总行（0 / N）、层数回退段 vs 修炼度段
///     vs 无心法段、混合 residue 标题门控。
///     （余毒段 / 双标题已由 defeat_loss_banner_residue_test.dart 覆盖。）
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  // ── fixtures ─────────────────────────────────────────────────────────────

  Character makeCharacter({
    required String name,
    int id = 1,
    int? mainTechniqueId,
    double injuryHoursRemaining = 0,
  }) {
    final c = Character.create(
      name: name,
      realmTier: RealmTier.wuSheng,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.values.first,
      lineageRole: LineageRole.values.first,
      createdAt: DateTime(2026, 1, 1),
      internalForce: 3000,
      mainTechniqueId: mainTechniqueId,
    );
    c.id = id;
    c.injuryHoursRemaining = injuryHoursRemaining;
    return c;
  }

  Technique makeTechnique({
    required int id,
    required int ownerCharacterId,
    required String defId,
  }) {
    final t = Technique.create(
      defId: defId,
      ownerCharacterId: ownerCharacterId,
      tier: TechniqueTier.values.first,
      school: TechniqueSchool.values.first,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 1, 1),
    );
    t.id = id;
    return t;
  }

  BattleResolutionResult bossDefeatResult({
    Map<int, DefeatPenaltyResult> defeatPenalty = const {},
    Map<int, InnerDemonPenaltyResult> innerDemonPenalty = const {},
  }) => BattleResolutionResult(
    updatedEquipmentIds: const [],
    skillUsageIncrements: const {},
    cultivationEvents: const {},
    dropResult: const DropResult(equipments: [], items: []),
    defeatPenaltyByCharacter: defeatPenalty,
    innerDemonPenaltyByCharacter: innerDemonPenalty,
  );

  DefeatPenaltyResult penalty({
    int layersRolledBack = 2,
    CultivationLayer oldLayer = CultivationLayer.daCheng,
    CultivationLayer newLayer = CultivationLayer.xiaoCheng,
  }) => DefeatPenaltyResult(
    internalForceBefore: 3000,
    internalForceAfter: 1500,
    oldLayer: oldLayer,
    newLayer: newLayer,
    layersRolledBack: layersRolledBack,
    progressBefore: 80,
    progressAfter: 40,
    progressToNextAfter: 100,
  );

  group('buildDefeatLossEntries · Boss 散功半区', () {
    test('didRollback(回退>0层) → old/newLayerLabel 非空且按层枚举本地化', () {
      final ch = makeCharacter(name: '张无忌', id: 1, mainTechniqueId: 10);
      final tech = makeTechnique(
        id: 10,
        ownerCharacterId: 1,
        defId: 'tech_gangmeng_jichu',
      );

      final entries = buildDefeatLossEntries(
        characters: [ch],
        techsByCh: {
          1: [tech],
        },
        result: bossDefeatResult(
          defeatPenalty: {1: penalty(layersRolledBack: 2)},
        ),
      );

      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.oldLayerLabel, '大成', reason: 'oldLayer=daCheng 应本地化');
      expect(e.newLayerLabel, '小成', reason: 'newLayer=xiaoCheng 应本地化');
      expect(e.layersRolledBack, 2);
      expect(e.residueApplied, isFalse, reason: 'Boss 散功 entry 不标余毒');
      expect(e.internalForceBefore, 3000);
      expect(e.internalForceAfter, 1500);
    });

    test('layersRolledBack=0(未回退) → old/newLayerLabel 均为 null', () {
      final ch = makeCharacter(name: '张无忌', id: 1, mainTechniqueId: 10);
      final tech = makeTechnique(
        id: 10,
        ownerCharacterId: 1,
        defId: 'tech_gangmeng_jichu',
      );

      final entries = buildDefeatLossEntries(
        characters: [ch],
        techsByCh: {
          1: [tech],
        },
        result: bossDefeatResult(
          defeatPenalty: {1: penalty(layersRolledBack: 0)},
        ),
      );

      expect(entries, hasLength(1));
      expect(entries.first.oldLayerLabel, isNull);
      expect(entries.first.newLayerLabel, isNull);
      expect(entries.first.layersRolledBack, 0);
    });

    test('injuryHoursRemaining>0 → injuryApplied=true;0 → false', () {
      final injured = makeCharacter(
        name: '伤者',
        id: 1,
        injuryHoursRemaining: 4.5,
      );
      final intact = makeCharacter(name: '无恙', id: 2);

      final entries = buildDefeatLossEntries(
        characters: [injured, intact],
        techsByCh: const {},
        result: bossDefeatResult(defeatPenalty: {1: penalty(), 2: penalty()}),
      );

      expect(entries, hasLength(2));
      expect(entries[0].injuryApplied, isTrue, reason: '有伤势剩余小时 → 重伤标记');
      expect(entries[1].injuryApplied, isFalse);
    });

    test('同一角色散功+心魔双惩罚 → 生成两条 entry(散功在前,心魔在后)', () {
      final ch = makeCharacter(name: '张无忌', id: 1, mainTechniqueId: 10);
      final tech = makeTechnique(
        id: 10,
        ownerCharacterId: 1,
        defId: 'tech_gangmeng_jichu',
      );
      const ip = InnerDemonPenaltyResult(
        internalForceBefore: 1500,
        internalForceAfter: 750,
        progressBefore: 40,
        progressAfter: 20,
        residueHoursApplied: 6.0,
      );

      final entries = buildDefeatLossEntries(
        characters: [ch],
        techsByCh: {
          1: [tech],
        },
        result: bossDefeatResult(
          defeatPenalty: {1: penalty()},
          innerDemonPenalty: {1: ip},
        ),
      );

      expect(entries, hasLength(2), reason: '两类惩罚互斥标记但共享函数,均生成');
      expect(entries[0].residueApplied, isFalse, reason: '散功 entry 在前');
      expect(entries[1].residueApplied, isTrue, reason: '心魔 entry 在后');
      expect(entries[1].internalForceBefore, 1500);
    });

    test('无惩罚角色不出现在 entries(散功 map 无该 id → continue)', () {
      final penalized = makeCharacter(name: '受罚', id: 1);
      final spared = makeCharacter(name: '幸免', id: 2);

      final entries = buildDefeatLossEntries(
        characters: [penalized, spared],
        techsByCh: const {},
        result: bossDefeatResult(defeatPenalty: {1: penalty()}),
      );

      expect(entries, hasLength(1));
      expect(entries.first.characterName, '受罚');
    });
  });

  group('buildDefeatLossEntries · _resolveTechName 分支', () {
    test('mainTechniqueId 命中 → techniqueName 取 GameRepository 心法名', () {
      final ch = makeCharacter(name: '张无忌', id: 1, mainTechniqueId: 10);
      final tech = makeTechnique(
        id: 10,
        ownerCharacterId: 1,
        defId: 'tech_gangmeng_jichu',
      );

      final entries = buildDefeatLossEntries(
        characters: [ch],
        techsByCh: {
          1: [tech],
        },
        result: bossDefeatResult(defeatPenalty: {1: penalty()}),
      );

      expect(
        entries.first.techniqueName,
        '刚猛入门',
        reason: 'tech_gangmeng_jichu 在 techniques.yaml 中的名称',
      );
    });

    test('mainTechniqueId 未命中任何 tech → 兜底取列表首个的 defId 名', () {
      final ch = makeCharacter(name: '张无忌', id: 1, mainTechniqueId: 999);
      final fallback = makeTechnique(
        id: 10,
        ownerCharacterId: 1,
        defId: 'tech_lingqiao_jichu',
      );

      final entries = buildDefeatLossEntries(
        characters: [ch],
        techsByCh: {
          1: [fallback],
        },
        result: bossDefeatResult(defeatPenalty: {1: penalty()}),
      );

      expect(
        entries.first.techniqueName,
        '灵巧入门',
        reason: 'firstWhere orElse → techs.first',
      );
    });

    test('mainTechniqueId 为 null → techniqueName 为 null', () {
      final ch = makeCharacter(name: '张无忌', id: 1);
      final tech = makeTechnique(
        id: 10,
        ownerCharacterId: 1,
        defId: 'tech_gangmeng_jichu',
      );

      final entries = buildDefeatLossEntries(
        characters: [ch],
        techsByCh: {
          1: [tech],
        },
        result: bossDefeatResult(defeatPenalty: {1: penalty()}),
      );

      expect(entries.first.techniqueName, isNull);
    });

    test('techsByCh 无该角色 / 空列表 → techniqueName 为 null', () {
      final ch = makeCharacter(name: '张无忌', id: 1, mainTechniqueId: 10);

      final missing = buildDefeatLossEntries(
        characters: [ch],
        techsByCh: const {},
        result: bossDefeatResult(defeatPenalty: {1: penalty()}),
      );
      expect(missing.first.techniqueName, isNull, reason: 'techsByCh 无 key');

      final empty = buildDefeatLossEntries(
        characters: [ch],
        techsByCh: {1: []},
        result: bossDefeatResult(defeatPenalty: {1: penalty()}),
      );
      expect(empty.first.techniqueName, isNull, reason: 'techs 列表为空');
    });

    test('defId 不在 GameRepository → getTechnique 抛异常被吞,name 为 null', () {
      final ch = makeCharacter(name: '张无忌', id: 1, mainTechniqueId: 10);
      final ghost = makeTechnique(
        id: 10,
        ownerCharacterId: 1,
        defId: 'tech_not_in_repository',
      );

      final entries = buildDefeatLossEntries(
        characters: [ch],
        techsByCh: {
          1: [ghost],
        },
        result: bossDefeatResult(defeatPenalty: {1: penalty()}),
      );

      expect(
        entries.first.techniqueName,
        isNull,
        reason: '_resolveTechName catch → null 安全兜底',
      );
    });
  });

  group('shouldSkipScrollDrop 三态', () {
    test('秘籍 defId + 非首通 → 跳过;首通 → 不跳过', () {
      expect(
        shouldSkipScrollDrop('item_scroll_gangmeng_01', isFirstClear: false),
        isTrue,
        reason: '重打跳过秘籍写入',
      );
      expect(
        shouldSkipScrollDrop('item_scroll_gangmeng_01', isFirstClear: true),
        isFalse,
        reason: '首通必得不 gate',
      );
    });

    test('非秘籍 defId(银两/经验丹) → 无论首通与否都不跳过', () {
      expect(shouldSkipScrollDrop('item_silver', isFirstClear: false), isFalse);
      expect(
        shouldSkipScrollDrop('item_exp_pill', isFirstClear: true),
        isFalse,
      );
    });
  });

  group('buildDefeatLossBanner · 未测分支', () {
    Widget wrap(List<DefeatLossEntry> entries) =>
        MaterialApp(home: Scaffold(body: buildDefeatLossBanner(entries)));

    testWidgets('entries 为空 → SizedBox.shrink(不渲染标题/容器)', (tester) async {
      await tester.pumpWidget(wrap(const []));

      expect(find.byType(Container), findsNothing);
      expect(find.text(UiStrings.defeatLossTitle), findsNothing);
      expect(find.text(UiStrings.defeatLossTitleInnerDemon), findsNothing);
    });

    testWidgets('有 entry 带 injuryApplied → 追加「N 名弟子负伤」汇总行', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(const [
          DefeatLossEntry(
            characterName: '测试甲',
            internalForceBefore: 2000,
            internalForceAfter: 1000,
            injuryApplied: true,
          ),
          DefeatLossEntry(
            characterName: '测试乙',
            internalForceBefore: 3000,
            internalForceAfter: 1500,
            injuryApplied: true,
          ),
          DefeatLossEntry(
            characterName: '测试丙',
            internalForceBefore: 4000,
            internalForceAfter: 2000,
          ),
        ]),
      );

      expect(
        find.text(UiStrings.defeatInjuredDisciples(2)),
        findsOneWidget,
        reason: '仅统计 injuryApplied=true 的 entry',
      );
    });

    testWidgets('无 injuryApplied → 不渲染负伤汇总行', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(const [
          DefeatLossEntry(
            characterName: '测试甲',
            internalForceBefore: 2000,
            internalForceAfter: 1000,
          ),
        ]),
      );

      expect(find.textContaining('名弟子负伤'), findsNothing);
    });

    testWidgets('techniqueName + layersRolledBack>0 → 渲染层数回退段', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const entry = DefeatLossEntry(
        characterName: '测试甲',
        internalForceBefore: 3000,
        internalForceAfter: 1500,
        techniqueName: '伏魔禅功',
        oldLayerLabel: '大成',
        newLayerLabel: '小成',
        layersRolledBack: 2,
      );
      await tester.pumpWidget(wrap(const [entry]));

      final expectedSegment = UiStrings.defeatTechniqueLayerSegment(
        '伏魔禅功',
        '大成',
        '小成',
        2,
      );
      final forceSegment = UiStrings.defeatInternalForceSegment(3000, 1500);
      expect(
        find.text('测试甲  $forceSegment  ·  $expectedSegment'),
        findsOneWidget,
        reason: '回退层数>0 的 Boss 整行文案保持',
      );
      expect(
        find.textContaining(UiStrings.defeatTechniqueProgressSegment('伏魔禅功')),
        findsNothing,
      );
    });

    testWidgets('techniqueName + layersRolledBack=0 → 渲染修炼度回退段', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const entry = DefeatLossEntry(
        characterName: '测试甲',
        internalForceBefore: 3000,
        internalForceAfter: 1500,
        techniqueName: '伏魔禅功',
      );
      await tester.pumpWidget(wrap(const [entry]));

      final forceSegment = UiStrings.defeatInternalForceSegment(3000, 1500);
      final progressSegment = UiStrings.defeatTechniqueProgressSegment('伏魔禅功');
      expect(
        find.text('测试甲  $forceSegment  ·  $progressSegment'),
        findsOneWidget,
        reason: '零回退层的普通 Boss 仍显示修炼度回退段',
      );
    });

    testWidgets('Boss 内力相等边界仍显示旧内力段', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const entry = DefeatLossEntry(
        characterName: '测试甲',
        internalForceBefore: 2000,
        internalForceAfter: 2000,
      );
      await tester.pumpWidget(wrap(const [entry]));

      final forceSegment = UiStrings.defeatInternalForceSegment(2000, 2000);
      expect(find.text('测试甲  $forceSegment'), findsOneWidget);
    });

    testWidgets('techniqueName 为 null → 仅内力段,无任何心法段', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const entry = DefeatLossEntry(
        characterName: '测试甲',
        internalForceBefore: 3000,
        internalForceAfter: 1500,
      );
      await tester.pumpWidget(wrap(const [entry]));

      expect(
        find.text('测试甲  ${UiStrings.defeatInternalForceSegment(3000, 1500)}'),
        findsOneWidget,
      );
      // 行文本不含心法分隔段(内力段后无「 · 」拼接)
      expect(
        find.textContaining(
          '测试甲  ${UiStrings.defeatInternalForceSegment(3000, 1500)}  ·',
        ),
        findsNothing,
      );
    });

    testWidgets('混合 residue(余毒+散功) → every() 为 false → 散功代价标题', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(const [
          DefeatLossEntry(
            characterName: '测试甲',
            internalForceBefore: 2000,
            internalForceAfter: 1000,
            residueApplied: true,
          ),
          DefeatLossEntry(
            characterName: '测试乙',
            internalForceBefore: 3000,
            internalForceAfter: 1500,
          ),
        ]),
      );

      expect(
        find.text(UiStrings.defeatLossTitle),
        findsOneWidget,
        reason: '非全余毒 → 散功代价标题',
      );
      expect(find.text(UiStrings.defeatLossTitleInnerDemon), findsNothing);
      // 余毒 entry 仍各自渲染余毒段
      expect(
        find.textContaining(UiStrings.innerDemonResidueNote),
        findsOneWidget,
      );
    });
  });
}
