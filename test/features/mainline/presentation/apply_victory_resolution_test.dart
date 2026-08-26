import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/combat_shared/application/combat_content_providers.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

/// `applyVictoryResolution`（stage_entry_flow.dart L767-973）分支面直测。
///
/// 真 Isar（tempDir + IsarSetup.init）+ engine-neutral settlement snapshot；覆盖：
///   - L772-773 Isar 未 ready → null
///   - L774-775 战斗未结束 → null
///   - L778-780 无 activeCharacterIds → null
///   - L787/815 activeIds 指向不存在角色 → 全 skip → null
///   - L868-904 writeTxn：装备入背包 / item 新建 / item 合并 / 秘籍首通门控
///   - L845-862 首通快照 + isFirstClearStage 推导
///   - L926-937 Boss 首通 → bossVictory 事件上下文（founderId 非空才记）
///   - L942-972 heroCamera / extraDisplayTiers / 返回 record
///
/// **FakeAsync 注意**：testWidgets 体跑在 fake-async zone，真实 Isar async
/// 必须经 `tester.runAsync` 执行，否则 future 永不完成（本文件开发期实测
/// 挂死 2 分钟确认此模式）。
void main() {
  late Directory tempDir;

  /// 摘掉 `rare_bonus_drop` 段的 NumbersConfig(其余段与生产同一份 yaml)。
  ///
  /// flaky 根治 2026-07-22:`applyVictoryResolution` 内 `rng: DefaultRng()`
  /// 无种子(stage_entry_flow.dart L826),resolve 的稀有彩头 roll
  /// (battle_resolution.dart L211-230)一周目 5%/1.5% 独立命中 → 额外掉一件
  /// 高阶装备 → equipmentObtained 事件偶发 2 条(本文件实测 1/20 失败,
  /// 第二条为 weapon_xiangyang_chang_jian)。改生产 RNG 接线超出测试修复面,
  /// 故测试层把彩头关闸(RareBonusDropConfig.empty → enabled=false →
  /// rollRareBonus 永不命中),断言语义(固定掉落 1 件 = 事件 1 条)保持不变。
  late final NumbersConfig noRareBonusNumbers;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
    final numbersYaml = Map<String, dynamic>.from(
      parseYamlMap(await loadTestAsset('data/numbers.yaml')),
    )..remove('rare_bonus_drop');
    noRareBonusNumbers = NumbersConfig.fromYaml(numbersYaml);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_avr_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ── fixtures ─────────────────────────────────────────────────────────────

  StageDef normalStage({
    List<DropEntry> dropTable = const [],
    int baseExpReward = 0,
    StageType stageType = StageType.mainline,
  }) => StageDef(
    id: 'stage_avr_normal',
    name: '测试普通关',
    stageType: stageType,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: const [],
    isBossStage: false,
    baseExpReward: baseExpReward,
    difficultyMultiplier: 1.0,
    dropTable: dropTable,
  );

  StageDef bossStage() => const StageDef(
    id: 'stage_avr_boss',
    name: '测试 Boss 关',
    stageType: StageType.mainline,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: [],
    isBossStage: true,
    baseExpReward: 0,
    difficultyMultiplier: 1.0,
  );

  CombatSettlementSnapshot finishedSettlement(List<int> participantIds) =>
      CombatSettlementSnapshot(
        result: BattleResult.leftWin,
        totalTicks: 1,
        hadActions: true,
        playerCharacterId: participantIds.first,
        participants: [
          for (final id in participantIds)
            CombatParticipantSnapshot(
              characterId: id,
              currentHp: 8000,
              maxHp: 8000,
            ),
        ],
        skillCasts: const [],
        totalDamage: 0,
        criticalCount: 0,
        damageByCharacterId: {for (final id in participantIds) id: 0},
      );

  CombatSettlementSnapshot defeatSettlement(int participantId) =>
      CombatSettlementSnapshot(
        result: BattleResult.rightWin,
        totalTicks: 9,
        hadActions: true,
        playerCharacterId: participantId,
        participants: [
          CombatParticipantSnapshot(
            characterId: participantId,
            currentHp: 0,
            maxHp: 8000,
          ),
        ],
        skillCasts: const [],
        totalDamage: 0,
        criticalCount: 0,
        damageByCharacterId: const {},
      );

  Future<void> writeSaveData({
    List<int> activeIds = const [],
    int? founderId,
  }) async {
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..slotId = IsarSetup.currentSlotId
          ..saveVersion = '0.0.1'
          ..createdAt = DateTime(2026, 7, 18)
          ..lastSavedAt = DateTime(2026, 7, 18)
          ..lastOnlineAt = DateTime(2026, 7, 18)
          ..activeCharacterIds = activeIds
          ..founderCharacterId = founderId,
      ),
    );
  }

  Future<int> insertCharacter({required String name, int? mainTechId}) async {
    final c = Character.create(
      name: name,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 7, 18),
      internalForce: 3000,
      mainTechniqueId: mainTechId,
    );
    return IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.characters.put(c),
    );
  }

  Future<int> insertTechnique({
    required int ownerId,
    String defId = 'tech_gangmeng_jichu',
  }) async {
    final t = Technique.create(
      defId: defId,
      ownerCharacterId: ownerId,
      tier: TechniqueTier.values.first,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 7, 18),
    );
    return IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.techniques.put(t),
    );
  }

  Future<void> markCleared(String stageId) async {
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.mainlineProgress.put(
        MainlineProgress()
          ..saveDataId = IsarSetup.currentSlotId
          ..clearedStageIds = [stageId]
          ..clearedAt = [DateTime(2026, 7, 1)],
      ),
    );
  }

  /// 经 Consumer 捕获 WidgetRef，在 runAsync 真实时钟区执行 body。
  /// （testWidgets 的 fake-async zone 中真 Isar future 的行为不可预期,
  /// 全部 Isar 交互统一收进 tester.runAsync。）
  Future<T> runWithRef<T>(
    WidgetTester tester,
    Future<T> Function(WidgetRef ref) body,
  ) async {
    WidgetRef? capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 全文件关稀有彩头 roll,消除 victory 结算的随机额外装备(见上方注释)。
          numbersConfigProvider.overrideWithValue(noRareBonusNumbers),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    final result = await tester.runAsync(() => body(capturedRef!));
    return result as T;
  }

  // ── tests ────────────────────────────────────────────────────────────────

  testWidgets('Isar 未 ready → 返回 null(L772-773)', (tester) async {
    await IsarSetup.close();
    IsarSetup.resetForTest();

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: normalStage(),
        settlementSnapshot: finishedSettlement([1]),
      ),
    );

    expect(outcome, isNull, reason: 'instanceOrNull == null → 早返 null');
  });

  testWidgets('战斗未结束(result=null) → 返回 null(L774-775)', (tester) async {
    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(ref: ref, stage: normalStage()),
    );

    expect(outcome, isNull, reason: 'finalState.isFinished == false → null');
  });

  testWidgets('轻功 exact participant 缺少完成快照时 fail closed', (tester) async {
    final participantId = (await tester.runAsync(() async {
      final participant = await insertCharacter(name: '轻功门人');
      await writeSaveData(activeIds: const []);
      return participant;
    }))!;
    final error = await runWithRef<Object?>(tester, (ref) async {
      try {
        await applyVictoryResolution(
          ref: ref,
          stage: normalStage(),
          expectedParticipantId: participantId,
        );
        return null;
      } catch (caught) {
        return caught;
      }
    });
    expect(error, isA<StateError>());
  });

  testWidgets('显式 0A 末态胜利 → 不读未结束的旧 provider,只结算真实参战者', (tester) async {
    final (founderId, reserveId) = (await tester.runAsync(() async {
      final founder = await insertCharacter(name: '祖师');
      final reserve = await insertCharacter(name: '替补');
      await writeSaveData(activeIds: [founder, reserve], founderId: founder);
      return (founder, reserve);
    }))!;
    final settlement = CombatSettlementSnapshot(
      result: BattleResult.leftWin,
      totalTicks: 12,
      hadActions: true,
      playerCharacterId: founderId,
      participants: [
        CombatParticipantSnapshot(
          characterId: founderId,
          currentHp: 7000,
          maxHp: 8000,
        ),
      ],
      skillCasts: const [],
      totalDamage: 321,
      criticalCount: 2,
      damageByCharacterId: {founderId: 321},
    );
    final stage = normalStage(
      baseExpReward: 30,
      dropTable: const [
        ItemDrop(
          inventoryItemDefId: 'item_silver',
          quantityMin: 5,
          quantityMax: 5,
          dropChance: 1.0,
        ),
      ],
    );

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: stage,
        settlementSnapshot: settlement,
      ),
    );

    expect(outcome, isNotNull, reason: '显式 0A 胜利末态必须驱动结算');
    expect(outcome!.stats.totalDamage, 321);
    expect(outcome.stats.critCount, 2);
    expect(outcome.stats.totalTicks, 12);
    expect(outcome.characters.map((character) => character.id), [founderId]);
    await tester.runAsync(() async {
      final founder = await IsarSetup.instance.characters.get(founderId);
      final reserve = await IsarSetup.instance.characters.get(reserveId);
      final silver = await IsarSetup.instance.inventoryItems.getByDefId(
        'item_silver',
      );
      expect(founder!.experience, 30, reason: '真实参战祖师获得经验');
      expect(reserve!.experience, 0, reason: '未参战替补不得被结算');
      expect(silver!.quantity, 5, reason: '0A 胜利照常发放关卡掉落');
    });
  });

  testWidgets('可见重打的经验与无主掉落事件归实际参与门人，不回落掌门', (tester) async {
    final (founderId, participantId) = (await tester.runAsync(() async {
      final founder = await insertCharacter(name: '掌门');
      final participant = await insertCharacter(name: '重打门人');
      await writeSaveData(
        activeIds: [founder, participant],
        founderId: founder,
      );
      await markCleared('stage_avr_normal');
      return (founder, participant);
    }))!;
    final stage = normalStage(
      baseExpReward: 17,
      dropTable: const [
        EquipmentDrop(
          equipmentDefId: 'weapon_xunchang_tie_jian',
          dropChance: 1,
        ),
      ],
    );

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: stage,
        settlementSnapshot: finishedSettlement([participantId]),
      ),
    );
    expect(outcome, isNotNull);

    await tester.runAsync(() async {
      final isar = IsarSetup.instance;
      expect((await isar.characters.get(founderId))!.experience, 0);
      expect((await isar.characters.get(participantId))!.experience, 17);
      final events = await isar.gameEvents
          .filter()
          .eventTypeEqualTo(GameEventType.equipmentObtained)
          .findAll();
      expect(events, isNotEmpty);
      expect(
        events.map((event) => event.relatedCharacterId),
        everyElement(participantId),
      );
    });
  });

  testWidgets('真实 Ch1 映射 + headless 末态 → Isar 奖励/经验/伤势全链', (tester) async {
    final (founderId, reserveId) = (await tester.runAsync(() async {
      final founder = await insertCharacter(name: '祖师');
      final reserve = await insertCharacter(name: '替补');
      await writeSaveData(activeIds: [founder, reserve], founderId: founder);
      return (founder, reserve);
    }))!;
    final stage = GameRepository.instance.getStage('stage_01_01');
    final mapping = Phase0aStageContentMapper.map(
      stage: stage,
      playerSnapshot: testCombatantSnapshot(
        characterId: founderId,
        name: '祖师',
        maxHp: 8000,
        currentHp: 8000,
        includeProductionBasicAttack: true,
      ),
      numbers: noRareBonusNumbers,
    );
    final flow = Phase0aProductionFlowAssembler.assemble(
      initialState: mapping.initialState,
      waves: mapping.waves,
      combatants: mapping.combatants,
      moveBindings: mapping.moveBindings,
      numbers: noRareBonusNumbers,
      rng: Random(20260820),
      playerAdapter: mapping.playerAdapter,
      enemyAiAdapter: mapping.enemyAiAdapter,
    );
    final headless = Phase0aHeadlessRunner.runToEnd(
      flow: flow,
      bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
      deltaSeconds: noRareBonusNumbers.phase0aArena.fixedDeltaSeconds,
      maxTicks: noRareBonusNumbers.phase0aArena.maxSimulationTicks,
    );
    final settlement = Phase0aSettlementAdapter.fromMapping(
      mapping: mapping,
      outcome: headless.outcome,
      finalState: headless.finalState,
      events: headless.events,
    );

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: stage,
        settlementSnapshot: settlement,
      ),
    );

    expect(settlement.result, BattleResult.leftWin);
    expect(outcome, isNotNull);
    expect(outcome!.characters.map((character) => character.id), [founderId]);
    expect(outcome.drops.items, isNotEmpty, reason: 'stage_01_01 固定掉落应入结算');
    await tester.runAsync(() async {
      final founder = await IsarSetup.instance.characters.get(founderId);
      final reserve = await IsarSetup.instance.characters.get(reserveId);
      expect(founder!.experience, stage.baseExpReward);
      expect(founder.lightInjuryStacks, 1, reason: '真实参战者累积连战轻伤');
      expect(reserve!.experience, 0);
      expect(reserve.lightInjuryStacks, 0, reason: '未参战替补零污染');
      for (final item in outcome.drops.items) {
        final stored = await IsarSetup.instance.inventoryItems.getByDefId(
          item.defId,
        );
        expect(stored, isNotNull, reason: '${item.defId} 应写入 Isar');
      }
    });
  });

  testWidgets('SaveData 无 activeCharacterIds → 返回 null(L778-780)', (
    tester,
  ) async {
    await tester.runAsync(writeSaveData);

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: normalStage(),
        settlementSnapshot: finishedSettlement([1]),
      ),
    );

    expect(outcome, isNull, reason: 'ids 空 → 早返 null');
  });

  testWidgets('守城 exact participant 可结算非 active 当代门人且掌门零污染', (tester) async {
    final (founderId, participantId) = (await tester.runAsync(() async {
      final founder = await insertCharacter(name: '掌门');
      final participant = await insertCharacter(name: '轻功门人');
      await writeSaveData(activeIds: [founder], founderId: founder);
      return (founder, participant);
    }))!;

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: normalStage(baseExpReward: 23, stageType: StageType.massBattle),
        settlementSnapshot: finishedSettlement([participantId]),
        expectedParticipantId: participantId,
      ),
    );

    expect(outcome, isNotNull);
    expect(outcome!.characters.map((character) => character.id), [
      participantId,
    ]);
    await tester.runAsync(() async {
      expect(
        (await IsarSetup.instance.characters.get(founderId))!.experience,
        0,
      );
      expect(
        (await IsarSetup.instance.characters.get(participantId))!.experience,
        23,
      );
    });
  });

  testWidgets('轻功结算快照身份与 exact participant 不一致时 fail closed 且零写入', (
    tester,
  ) async {
    final (founderId, participantId) = (await tester.runAsync(() async {
      final founder = await insertCharacter(name: '掌门');
      final participant = await insertCharacter(name: '轻功门人');
      await writeSaveData(activeIds: [founder], founderId: founder);
      return (founder, participant);
    }))!;

    final error = await runWithRef<Object?>(tester, (ref) async {
      try {
        await applyVictoryResolution(
          ref: ref,
          stage: normalStage(baseExpReward: 23),
          settlementSnapshot: finishedSettlement([founderId]),
          expectedParticipantId: participantId,
        );
        return null;
      } catch (caught) {
        return caught;
      }
    });
    expect(error, isA<StateError>());
    await tester.runAsync(() async {
      expect(
        (await IsarSetup.instance.characters.get(founderId))!.experience,
        0,
      );
      expect(
        (await IsarSetup.instance.characters.get(participantId))!.experience,
        0,
      );
    });
  });

  testWidgets('轻功最终败北只给 exact 非 active 门人记伤势且不发经验', (tester) async {
    final (founderId, participantId) = (await tester.runAsync(() async {
      final founder = await insertCharacter(name: '掌门');
      final participant = await insertCharacter(name: '轻功门人');
      await writeSaveData(activeIds: [founder], founderId: founder);
      return (founder, participant);
    }))!;

    await runWithRef(
      tester,
      (ref) => applyParticipantDefeatResolution(
        ref: ref,
        stage: normalStage(baseExpReward: 99),
        settlementSnapshot: defeatSettlement(participantId),
        expectedParticipantId: participantId,
      ),
    );

    await tester.runAsync(() async {
      final founder = (await IsarSetup.instance.characters.get(founderId))!;
      final participant = (await IsarSetup.instance.characters.get(
        participantId,
      ))!;
      expect(founder.lightInjuryStacks, 0);
      expect(participant.lightInjuryStacks, 1);
      expect(founder.experience, 0);
      expect(participant.experience, 0);
    });
  });

  testWidgets('activeIds 全部指向不存在角色 → characters 空 → null(L787/815)', (
    tester,
  ) async {
    await tester.runAsync(() => writeSaveData(activeIds: [777, 778]));

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: normalStage(),
        settlementSnapshot: finishedSettlement([777, 778]),
      ),
    );

    expect(outcome, isNull, reason: 'characters.isEmpty → null');
  });

  testWidgets('胜利全量:装备入背包 + item 新建 + 首通秘籍写入 + 心法拉取', (tester) async {
    final (charId, techId) = (await tester.runAsync(() async {
      final cid = await insertCharacter(name: '祖师');
      final tid = await insertTechnique(ownerId: cid);
      // 主修指回刚入库的心法,覆盖 techsByCh 拉取 + skillUsageCount growable 转换。
      await IsarSetup.instance.writeTxn(() async {
        final c = await IsarSetup.instance.characters.get(cid);
        c!.mainTechniqueId = tid;
        await IsarSetup.instance.characters.put(c);
      });
      await writeSaveData(activeIds: [cid], founderId: cid);
      return (cid, tid);
    }))!;

    final stage = normalStage(
      dropTable: const [
        EquipmentDrop(
          equipmentDefId: 'weapon_xunchang_tie_jian',
          dropChance: 1.0,
        ),
        ItemDrop(
          inventoryItemDefId: 'item_silver',
          quantityMin: 5,
          quantityMax: 5,
          dropChance: 1.0,
        ),
        ItemDrop(
          inventoryItemDefId: 'item_scroll_kai_bei_shou',
          quantityMin: 1,
          quantityMax: 1,
          dropChance: 1.0,
        ),
      ],
    );

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: stage,
        settlementSnapshot: finishedSettlement([charId]),
      ),
    );

    expect(outcome, isNotNull);
    expect(outcome!.characters, hasLength(1));

    await tester.runAsync(() async {
      final isar = IsarSetup.instance;
      // 掉落装备入背包(owner=null)
      final dropped = outcome.drops.equipments
          .where((e) => e.defId == 'weapon_xunchang_tie_jian')
          .toList();
      expect(dropped, hasLength(1), reason: 'dropChance=1.0 必掉铁剑');
      final storedSword = await isar.equipments.get(dropped.single.id);
      expect(storedSword, isNotNull);
      expect(storedSword!.ownerCharacterId, isNull, reason: '掉落装备入背包而非装备');

      // 银两新建 inventoryItem(quantity=5)
      final silver = await isar.inventoryItems.getByDefId('item_silver');
      expect(silver, isNotNull);
      expect(silver!.quantity, 5);

      // 首通(MainlineProgress 未写)→ 秘籍不被 gate,写入背包
      final scroll = await isar.inventoryItems.getByDefId(
        'item_scroll_kai_bei_shou',
      );
      expect(scroll, isNotNull, reason: '首通必得:item_scroll_* 首通不跳过');
      expect(scroll!.quantity, 1, reason: 'quantityMin=Max=1,数量语义锁死');

      // equipmentObtained 事件已写
      final events = await isar.gameEvents.where().findAll();
      final obtained = events
          .where((e) => e.eventType == GameEventType.equipmentObtained)
          .toList();
      expect(
        obtained,
        hasLength(1),
        // 2026-07-19 全量并发曾见 2 条;2026-07-22 复现实锤为稀有彩头额外
        // 掉落(根因见文件头 noRareBonusNumbers 注释),已通过 numbersConfig
        // override 关闸。失败时仍打印全部命中事件便于定位。
        // (title/summary/relatedEntityIds/occurredAt)。
        reason:
            '命中 ${obtained.length} 条: '
            '${obtained.map((e) => '${e.title}|${e.summary}|'
                '${e.relatedEntityIds}|${e.occurredAt}').toList()}',
      );

      // 心法已拉取入库可查(skillUsageCount growable 转换未抛 UnsupportedError)
      final techRow = await isar.techniques.get(techId);
      expect(techRow, isNotNull);
      expect(
        techRow!.skillUsageCount,
        isEmpty,
        reason: '未放技能 → 计数仍空,growable 转换写回不丢数据',
      );
    });
  });

  testWidgets('重打(MainlineProgress 已含 stageId) → 秘籍被 gate,银两照掉', (
    tester,
  ) async {
    final charId = (await tester.runAsync(() async {
      final cid = await insertCharacter(name: '祖师');
      await writeSaveData(activeIds: [cid]);
      await markCleared('stage_avr_normal');
      return cid;
    }))!;

    final stage = normalStage(
      dropTable: const [
        ItemDrop(
          inventoryItemDefId: 'item_silver',
          quantityMin: 5,
          quantityMax: 5,
          dropChance: 1.0,
        ),
        ItemDrop(
          inventoryItemDefId: 'item_scroll_kai_bei_shou',
          quantityMin: 1,
          quantityMax: 1,
          dropChance: 1.0,
        ),
      ],
    );

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: stage,
        settlementSnapshot: finishedSettlement([charId]),
      ),
    );

    expect(outcome, isNotNull);
    await tester.runAsync(() async {
      final isar = IsarSetup.instance;
      expect(
        await isar.inventoryItems.getByDefId('item_scroll_kai_bei_shou'),
        isNull,
        reason: 'shouldSkipScrollDrop:重打跳过秘籍写入',
      );
      final silver = await isar.inventoryItems.getByDefId('item_silver');
      expect(silver, isNotNull, reason: '银两不受首通门控');
      expect(silver!.quantity, 5);
    });
  });

  testWidgets('既有 inventoryItem → 数量合并 + lastObtainedAt 刷新(L889-893)', (
    tester,
  ) async {
    final oldTime = DateTime(2026, 1, 1);
    final charId = (await tester.runAsync(() async {
      final cid = await insertCharacter(name: '祖师');
      await writeSaveData(activeIds: [cid]);
      await IsarSetup.instance.writeTxn(
        () => IsarSetup.instance.inventoryItems.put(
          InventoryItem()
            ..defId = 'item_silver'
            ..itemType = ItemType.silver
            ..quantity = 3
            ..firstObtainedAt = oldTime
            ..lastObtainedAt = oldTime,
        ),
      );
      return cid;
    }))!;

    final stage = normalStage(
      dropTable: const [
        ItemDrop(
          inventoryItemDefId: 'item_silver',
          quantityMin: 5,
          quantityMax: 5,
          dropChance: 1.0,
        ),
      ],
    );

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: stage,
        settlementSnapshot: finishedSettlement([charId]),
      ),
    );

    expect(outcome, isNotNull);
    await tester.runAsync(() async {
      final silver = await IsarSetup.instance.inventoryItems.getByDefId(
        'item_silver',
      );
      expect(silver, isNotNull);
      expect(silver!.quantity, 8, reason: '3 + 5 合并到既有行');
      expect(silver.firstObtainedAt, oldTime, reason: 'firstObtainedAt 不改');
      expect(
        silver.lastObtainedAt.isAfter(oldTime),
        isTrue,
        reason: 'lastObtainedAt 刷新为本次掉落时间',
      );
      final all = await IsarSetup.instance.inventoryItems.where().findAll();
      expect(all, hasLength(1), reason: '合并不新增行');
    });
  });

  testWidgets('Boss 首通 + founderId 非空 → bossDefeated 事件写入(L926-937)', (
    tester,
  ) async {
    final charId = (await tester.runAsync(() async {
      final cid = await insertCharacter(name: '祖师');
      await writeSaveData(activeIds: [cid], founderId: cid);
      return cid;
    }))!;

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: bossStage(),
        settlementSnapshot: finishedSettlement([charId]),
      ),
    );

    expect(outcome, isNotNull);
    await tester.runAsync(() async {
      final events = await IsarSetup.instance.gameEvents.where().findAll();
      expect(
        events.where((e) => e.eventType == GameEventType.bossDefeated),
        hasLength(1),
        reason: 'Boss 首通(bossVictory context 非空)→ recordBossDefeated',
      );
    });
  });

  testWidgets('Boss 重打(非首通) → 不写 bossDefeated 事件', (tester) async {
    final charId = (await tester.runAsync(() async {
      final cid = await insertCharacter(name: '祖师');
      await writeSaveData(activeIds: [cid], founderId: cid);
      await markCleared('stage_avr_boss');
      return cid;
    }))!;

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: bossStage(),
        settlementSnapshot: finishedSettlement([charId]),
      ),
    );

    expect(outcome, isNotNull);
    await tester.runAsync(() async {
      final events = await IsarSetup.instance.gameEvents.where().findAll();
      expect(
        events.where((e) => e.eventType == GameEventType.bossDefeated),
        isEmpty,
        reason: '非首通 → bossVictory context 为 null → 不记事件',
      );
    });
  });

  testWidgets('Boss 首通但 founderId 为 null → 不写 bossDefeated 事件', (tester) async {
    final charId = (await tester.runAsync(() async {
      final cid = await insertCharacter(name: '祖师');
      await writeSaveData(activeIds: [cid]);
      return cid;
    }))!;

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: bossStage(),
        settlementSnapshot: finishedSettlement([charId]),
      ),
    );

    expect(outcome, isNotNull);
    await tester.runAsync(() async {
      final events = await IsarSetup.instance.gameEvents.where().findAll();
      expect(
        events.where((e) => e.eventType == GameEventType.bossDefeated),
        isEmpty,
        reason: 'recordCommonEvents 要求 founderId 非空才记 boss 事件',
      );
    });
  });

  // ── L785-788 per-id skip:部分悬空 activeIds 不拖垮整批结算 ────────────────
  testWidgets('activeIds 部分悬空 → 跳过不存在角色,存活角色照常结算', (tester) async {
    final charId = (await tester.runAsync(() async {
      final cid = await insertCharacter(name: '祖师');
      await writeSaveData(activeIds: [cid, 999]);
      return cid;
    }))!;

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: normalStage(),
        settlementSnapshot: finishedSettlement([charId]),
      ),
    );

    expect(outcome, isNotNull, reason: '部分悬空不清零,有效角色照常结算');
    expect(outcome!.characters, hasLength(1), reason: '999 被 per-id skip');
    expect(outcome.characters.single.id, charId, reason: '只有存活角色进入结算记录');
  });

  // ── L851-859 经验结算路径(既有用例全 baseExpReward=0,未覆盖)────────────────
  testWidgets('baseExpReward>0 → advancements 非空 + EXP 全额落库未升层', (
    tester,
  ) async {
    final charId = (await tester.runAsync(() async {
      final cid = await insertCharacter(name: '祖师');
      await writeSaveData(activeIds: [cid]);
      return cid;
    }))!;

    final outcome = await runWithRef(
      tester,
      (ref) => applyVictoryResolution(
        ref: ref,
        stage: normalStage(baseExpReward: 30),
        settlementSnapshot: finishedSettlement([charId]),
      ),
    );

    expect(outcome, isNotNull);
    expect(
      outcome!.advancements,
      hasLength(1),
      reason: 'baseExpReward>0 → applyExperience 出结算记录',
    );
    expect(outcome.advancements.single.characterId, charId);
    expect(
      outcome.advancements.single.result.experienceGained,
      30,
      reason: '全额发放 baseExpReward',
    );
    expect(
      outcome.advancements.single.result.layersGained,
      0,
      reason: '30 EXP 不足 xueTu.qiMeng 阈值(50) → 不升层',
    );

    await tester.runAsync(() async {
      final ch = await IsarSetup.instance.characters.get(charId);
      expect(ch!.experience, 30, reason: '未达阈值,EXP 全额落库');
      expect(ch.realmLayer, RealmLayer.qiMeng, reason: '未升层,境界不变');
    });
  });
}
