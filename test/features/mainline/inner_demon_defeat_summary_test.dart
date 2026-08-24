import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/combat_shared/application/combat_resolution_service.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_service.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';
import '../../support/test_data.dart';

/// Task 8：心魔关战败损失摘要展示心魔惩罚 + 余毒。
///
/// 测试纯数据层逻辑：[buildDefeatLossEntries] 纯函数（不涉 Isar），验证：
///   1. 心魔关战败 → entries 含受罚角色的内力 before/after，来自
///      [BattleResolutionResult.innerDemonPenaltyByCharacter]。
///   2. 心魔惩罚 entry residueApplied=true（余毒标记）。
///   3. 心魔惩罚 entry layersRolledBack=0（不掉层）。
///   4. 既有 Boss 散功 entry residueApplied 默认 false（不破回归）。
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
    int internalForce = 3000,
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
      internalForce: internalForce,
      mainTechniqueId: mainTechniqueId,
    );
    c.injuryHoursRemaining = injuryHoursRemaining;
    // 手动设定 id（Isar autoIncrement sentinel；测试中手动赋值区分角色）
    c.id = id;
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

  BattleResolutionResult innerDemonDefeatResult({
    required Map<int, InnerDemonPenaltyResult> innerDemonPenalty,
  }) => BattleResolutionResult(
    updatedEquipmentIds: const [],
    skillUsageIncrements: const {},
    cultivationEvents: const {},
    dropResult: const DropResult(equipments: [], items: []),
    defeatPenaltyByCharacter: const {},
    innerDemonPenaltyByCharacter: innerDemonPenalty,
  );

  // ── tests ────────────────────────────────────────────────────────────────

  test('心魔关战败 → entries 含受罚角色内力 before/after', () {
    final ch = makeCharacter(name: '张无忌', id: 1, mainTechniqueId: 10);
    final tech = makeTechnique(
      id: 10,
      ownerCharacterId: 1,
      defId: 'tech_jiuyang',
    );
    const penalty = InnerDemonPenaltyResult(
      internalForceBefore: 3000,
      internalForceAfter: 1500,
      progressBefore: 80,
      progressAfter: 40,
      residueHoursApplied: 12.0,
    );

    final entries = buildDefeatLossEntries(
      characters: [ch],
      techsByCh: {
        1: [tech],
      },
      result: innerDemonDefeatResult(innerDemonPenalty: {1: penalty}),
    );

    expect(entries.length, 1, reason: '受罚角色应生成 1 条 entry');
    final e = entries.first;
    expect(e.characterName, '张无忌');
    expect(e.internalForceBefore, 3000);
    expect(e.internalForceAfter, 1500);
  });

  test('心魔惩罚 entry residueApplied=true', () {
    final ch = makeCharacter(name: '张无忌', id: 1, mainTechniqueId: 10);
    final tech = makeTechnique(
      id: 10,
      ownerCharacterId: 1,
      defId: 'tech_jiuyang',
    );
    const penalty = InnerDemonPenaltyResult(
      internalForceBefore: 3000,
      internalForceAfter: 1500,
      progressBefore: 80,
      progressAfter: 40,
      residueHoursApplied: 12.0,
    );

    final entries = buildDefeatLossEntries(
      characters: [ch],
      techsByCh: {
        1: [tech],
      },
      result: innerDemonDefeatResult(innerDemonPenalty: {1: penalty}),
    );

    expect(entries.first.residueApplied, isTrue, reason: '心魔惩罚 entry 应标记余毒');
  });

  testWidgets('入场前已有伤势不冒充心魔失败后果', (tester) async {
    final ch = makeCharacter(name: '张无忌', id: 1, injuryHoursRemaining: 4.5);
    const penalty = InnerDemonPenaltyResult(
      internalForceBefore: 3000,
      internalForceAfter: 3000,
      progressBefore: 80,
      progressAfter: 80,
      residueHoursApplied: 12.0,
    );

    final entries = buildDefeatLossEntries(
      characters: [ch],
      techsByCh: const {},
      result: innerDemonDefeatResult(innerDemonPenalty: {1: penalty}),
    );

    expect(entries, hasLength(1));
    expect(entries.single.injuryApplied, isFalse);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: buildDefeatLossBanner(entries))),
    );

    expect(find.text(UiStrings.defeatInjuredDisciples(1)), findsNothing);
    expect(
      find.text('张无忌  ·  ${UiStrings.innerDemonResidueNote}'),
      findsOneWidget,
    );
  });

  test('心魔惩罚 entry layersRolledBack=0（心魔不掉层）', () {
    final ch = makeCharacter(name: '张无忌', id: 1, mainTechniqueId: 10);
    final tech = makeTechnique(
      id: 10,
      ownerCharacterId: 1,
      defId: 'tech_jiuyang',
    );
    const penalty = InnerDemonPenaltyResult(
      internalForceBefore: 3000,
      internalForceAfter: 1500,
      progressBefore: 80,
      progressAfter: 40,
      residueHoursApplied: 12.0,
    );

    final entries = buildDefeatLossEntries(
      characters: [ch],
      techsByCh: {
        1: [tech],
      },
      result: innerDemonDefeatResult(innerDemonPenalty: {1: penalty}),
    );

    expect(entries.first.layersRolledBack, 0, reason: '心魔惩罚不掉层');
    expect(
      entries.first.oldLayerLabel,
      isNull,
      reason: '心魔惩罚 oldLayerLabel 为 null',
    );
    expect(
      entries.first.newLayerLabel,
      isNull,
      reason: '心魔惩罚 newLayerLabel 为 null',
    );
  });

  test('无心魔惩罚（innerDemonPenaltyByCharacter 空）→ entries 空', () {
    final ch = makeCharacter(name: '张无忌', id: 1);

    final entries = buildDefeatLossEntries(
      characters: [ch],
      techsByCh: {1: []},
      result: innerDemonDefeatResult(innerDemonPenalty: {}),
    );

    expect(entries, isEmpty, reason: '无心魔惩罚 entry 且无散功 entry 时应为空');
  });

  test('既有 Boss 散功路径 residueApplied 默认 false（不破回归）', () {
    // DefeatLossEntry 直接构造，验证默认值
    const entry = DefeatLossEntry(
      characterName: '令狐冲',
      internalForceBefore: 2000,
      internalForceAfter: 1000,
      layersRolledBack: 1,
    );
    expect(
      entry.residueApplied,
      isFalse,
      reason: 'Boss 散功 entry 默认 residueApplied=false',
    );
  });

  test('多角色部分受罚 → 仅受罚角色生成 entry', () {
    final ch1 = makeCharacter(name: '张无忌', id: 1, mainTechniqueId: 10);
    final ch2 = makeCharacter(name: '令狐冲', id: 2, mainTechniqueId: 20);
    final tech1 = makeTechnique(
      id: 10,
      ownerCharacterId: 1,
      defId: 'tech_jiuyang',
    );
    final tech2 = makeTechnique(
      id: 20,
      ownerCharacterId: 2,
      defId: 'tech_dugu',
    );

    const penalty = InnerDemonPenaltyResult(
      internalForceBefore: 3000,
      internalForceAfter: 1500,
      progressBefore: 80,
      progressAfter: 40,
      residueHoursApplied: 12.0,
    );

    final entries = buildDefeatLossEntries(
      characters: [ch1, ch2],
      techsByCh: {
        1: [tech1],
        2: [tech2],
      },
      // 仅 ch1 受罚
      result: innerDemonDefeatResult(innerDemonPenalty: {1: penalty}),
    );

    expect(entries.length, 1, reason: '仅受罚的角色生成 entry');
    expect(entries.first.characterName, '张无忌');
  });
}
