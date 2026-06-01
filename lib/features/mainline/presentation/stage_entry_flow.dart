import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../data/narrative_loader.dart';
import '../../../core/application/battle_providers.dart';
import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../battle/application/battle_resolution.dart';
import '../../battle/application/stage_battle_setup.dart';
import '../../battle/domain/enum_localizations.dart' show EnumL10n;
import '../../battle/domain/strategy/light_foot_strategy.dart';
import '../../battle/domain/strategy/mass_battle_strategy.dart';
import '../../mass_battle/application/mass_battle_service.dart';
import '../../mass_battle/domain/mass_battle_def.dart';
import '../../../shared/strings.dart';
import '../../battle/presentation/battle_screen.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../../cultivation/presentation/advancement_summary.dart';
import '../../encounter/presentation/encounter_hook.dart';
import '../../jianghu/application/jianghu_providers.dart';
import '../../sect/presentation/stage_boss_recruit_hook.dart';
import '../../equipment/application/drop_service.dart';
import '../../event/application/game_event_service.dart';
import '../../inner_demon/application/inner_demon_service.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../../tutorial/application/tutorial_service.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/utils/rng.dart';
import '../application/mainline_progress_service.dart';
import '../application/mainline_providers.dart';
import '../domain/chapter_assets.dart';
import '../domain/mainline_progress.dart';
import 'stage_victory_dialog.dart';

/// Phase 3 T37 关卡进入流程串联。
///
/// 状态机（async 串联，无中间 widget）：
///   1. opening：若 [StageDef.narrativeOpeningId] 非空，push NarrativeReaderScreen
///      → wait its pop
///   2. battle：装配 (left, right) 战斗双方 → push BattleScreen → wait
///      onVictory / onDefeat 回调（Completer 转 Future）
///   3a. victory：异步 recordVictory + invalidate progress provider；若
///       narrativeVictoryId 非空 → push 第二段剧情
///   3b. defeat：若 narrativeDefeatId 非空（章末 Boss 关）→ push 战败剧情；
///       不记录进度 / 不掉装备，返回 stage list（Phase 3 Week 5 销账 #29）
///
/// **不嵌套 widget**：每段结束后栈上仅剩 stage_list_screen，避免多层 pop。
///
/// [battleRunnerForTest] / [victoryRecorderForTest] / [bossDefeatPenaltyForTest]
/// 仅供 widget test 注入,生产端勿传。设计对齐爬塔 `runTowerFlow` DI 三件套
/// ([@visibleForTesting])。
Future<void> runStageFlow({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
  @visibleForTesting Future<bool> Function()? battleRunnerForTest,
  @visibleForTesting Future<void> Function(String stageId)? victoryRecorderForTest,
  @visibleForTesting
  Future<List<DefeatLossEntry>> Function(StageDef stage)?
      bossDefeatPenaltyForTest,
}) async {
  // ── opening ──
  if (stage.narrativeOpeningId != null) {
    final opening = await NarrativeLoader.load(stage.narrativeOpeningId!);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: opening,
          fallbackTitle: stage.name,
          backgroundImagePath: stageNarrativePath(stage.id),
        ),
      ),
    );
  }

  // ── battle ──
  if (!context.mounted) return;
  final bool won;
  if (battleRunnerForTest != null) {
    won = await battleRunnerForTest();
  } else {
    won = await _runBattle(context: context, ref: ref, stage: stage);
  }

  // ── defeat ──
  if (!won) {
    // Phase 4 W10: Boss 关战败结算（被动散功 + battleCount + skillUsage 落地）。
    // 普通关战败仍直接返，不结算（试错免费）。
    Widget? lossBanner;
    if (stage.isBossStage) {
      final summary = bossDefeatPenaltyForTest != null
          ? await bossDefeatPenaltyForTest(stage)
          : await _applyBossDefeatPenalty(ref: ref, stage: stage);
      if (summary.isNotEmpty) {
        lossBanner = _DefeatLossBanner(entries: summary);
        // W13-v3 fix: writeTxn 写回 character.internalForce / mainTech.layer
        // 后必须 invalidate provider 缓存,否则下次进角色面板/心法面板仍读旧值
        // (Codex v3 截图 15 暴露:banner 显 3800→1900,但面板仍 3800)
        _invalidateCharacterFamilyAfterCombat(ref);
      }
    }

    if (stage.narrativeDefeatId != null && context.mounted) {
      final defeat = await NarrativeLoader.load(stage.narrativeDefeatId!);
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => NarrativeReaderScreen(
            content: defeat,
            fallbackTitle: '${stage.name} · 战败',
            topBanner: lossBanner,
            backgroundImagePath: stageNarrativePath(stage.id),
          ),
        ),
      );
    }
    // 1.1 战败收降 hook(stageBossFailRecoverProb 0.30 · 沿 victory recruit 体例)
    if (context.mounted) {
      await runStageBossFailRecoverHookAfterDefeat(
        context: context,
        ref: ref,
        stage: stage,
      );
    }
    return; // 战败不记录主线进度、不推 victory 剧情
  }

  // ── victory ──
  // Phase 4 W11 #32 销账：装备 battleCount / 心法 skillUsage / 主修升层 + 关卡 drop 落地
  final outcome = await _applyVictoryResolution(ref: ref, stage: stage);
  // W13-v3 fix: 同 defeat 分支,invalidate character/equipment/technique family
  _invalidateCharacterFamilyAfterCombat(ref);

  // W12 fix: provider 副作用 getOrCreate 与 recordVictory 存在 race（W6 重构遗留），
  // 主动 ensure 避免 MainlineProgress 未初始化时抛 StateError
  if (victoryRecorderForTest != null) {
    await victoryRecorderForTest(stage.id);
  } else {
    final svc = MainlineProgressService(isar: IsarSetup.instance);
    await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
    await svc.recordVictory(
      stageId: stage.id,
      now: DateTime.now(),
      tutorialService: ref.read(tutorialServiceProvider),
    );
    ref.invalidate(mainlineProgressProvider);
    ref.invalidate(currentTutorialStepProvider);
  }

  // W15 #30 P3 后续 A:victory dialog 显 drop + 升层 banner;outcome=null 时
  // (Isar 未 ready / characters 空)兜底跳过 dialog 不阻塞剧情流。
  if (outcome != null && context.mounted) {
    await showStageVictoryDialog(
      context: context,
      stage: stage,
      drops: outcome.drops,
      advancements: outcome.advancements,
      resonanceUpgrades: outcome.resonanceUpgrades,
    );
  }

  if (stage.narrativeVictoryId != null) {
    if (!context.mounted) return;
    final victory = await NarrativeLoader.load(stage.narrativeVictoryId!);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: victory,
          fallbackTitle: '${stage.name} · 胜利',
          backgroundImagePath: stageNarrativePath(stage.id),
        ),
      ),
    );
  }

  // Phase 4 W14-1 C-1 / W14-2:奇遇/武学领悟触发检查。
  // 放在 victory narrative 之后:通关剧情是这关的收尾,奇遇作为下一段开端。
  // W14-2 抽到 encounter_hook.dart,与爬塔共享。
  if (!context.mounted) return;
  await runEncounterHookAfterVictory(
    context: context,
    ref: ref,
    defeatedSchools:
        stage.enemyTeam.map((e) => e.school).toList(growable: false),
  );

  // P4.1 1.1 Q6B · Boss 战胜后招降 hook(spec p4_1_q6b_stage_boss_recruit_spec
  // _2026-05-26.md §3.2)· 在 encounter hook 之后顺序执行 · isBossStage +
  // bossRecruit 非 null + rng 命中 + markTriggered 守通过才弹 confirm dialog。
  if (!context.mounted) return;
  await runStageBossRecruitHookAfterVictory(
    context: context,
    ref: ref,
    stage: stage,
  );

  // P1.2 Boss 击杀 → 声望 delta(boss 所属派系 -delta · 对立阵营 +rivalDelta)。
  await _applyBossKillReputation(ref: ref, stage: stage);
}

/// W13-v3 fix: 战斗结算(victory / Boss defeat)后必须 invalidate 角色相关
/// family provider,否则下次进角色面板/心法面板/仓库读到 Riverpod 缓存的
/// 旧 Character / Equipment / Technique(虽然 Isar 已写入新值)。
///
/// **触发场景**:
/// - 主线 victory:battleCount / cultivationProgress 累 + 关卡 drop 入背包
/// - 主线 Boss defeat:internalForce ×0.5 + cultivationLayer 回退
/// - 爬塔 victory:battleCount / cultivationProgress 累(同主线)
///
/// 实测根因:Codex v3 截图 15「banner 显 3800→1900,角色面板仍 3800/4180」。
void _invalidateCharacterFamilyAfterCombat(WidgetRef ref) {
  ref.invalidate(characterByIdProvider);
  ref.invalidate(equipmentByIdProvider);
  ref.invalidate(techniqueByIdProvider);
  ref.invalidate(characterAllTechniquesProvider);
  ref.invalidate(allEquipmentsProvider);
}

/// 推 BattleScreen 并 wait 胜/败回调；返回 true=胜，false=败/平。
Future<bool> _runBattle({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
}) async {
  final completer = Completer<bool>();
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => _StageBattleHost(
        stage: stage,
        onVictory: () {
          if (!completer.isCompleted) completer.complete(true);
        },
        onDefeat: () {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    ),
  );
  // BattleScreen 通过结算 dialog 关闭按钮自己 pop；此时回调已 complete。
  // 极端兜底：如果用户系统返回键直接 pop，没触发回调，按"未胜"处理。
  if (!completer.isCompleted) completer.complete(false);
  return completer.future;
}

/// BattleScreen 的 setup 容器：initState 装配队伍 + startBattle，
/// 然后渲染 [BattleScreen]。沿用 [BattleDemoLauncher] 的 postFrameCallback 模式。
class _StageBattleHost extends ConsumerStatefulWidget {
  const _StageBattleHost({
    required this.stage,
    required this.onVictory,
    required this.onDefeat,
  });

  final StageDef stage;
  final VoidCallback onVictory;
  final VoidCallback onDefeat;

  @override
  ConsumerState<_StageBattleHost> createState() => _StageBattleHostState();
}

class _StageBattleHostState extends ConsumerState<_StageBattleHost> {
  String? _setupError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final (left, right) = await StageBattleSetup(isar: IsarSetup.instance).buildTeams(widget.stage);
        if (!mounted) return;
        if (widget.stage.stageType == StageType.massBattle) {
          final enemyWaves =
              StageBattleSetup.buildEnemyTeamsPerWave(widget.stage);
          final config = GameRepository.instance.numbers.massBattle;
          final formation = await _pickFormation(context, widget.stage, config);
          if (!mounted) return;
          ref.read(battleProvider.notifier).startBattle(
                left,
                right,
                strategy: MassBattleStrategy(
                  formation: formation,
                  enemyTeamsPerWave: enemyWaves,
                  config: config,
                ),
              );
        } else if (widget.stage.stageType == StageType.lightFoot &&
            widget.stage.terrainBiome != null) {
          ref.read(battleProvider.notifier).startBattle(
                left,
                right,
                strategy: LightFootStrategy(
                  terrainBiome: widget.stage.terrainBiome!,
                  config: GameRepository.instance.numbers.lightFoot,
                ),
              );
        } else {
          ref.read(battleProvider.notifier).startBattle(left, right);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _setupError = e.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_setupError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.stage.name)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(UiStrings.battleSetupFailed(_setupError!)),
          ),
        ),
      );
    }
    return BattleScreen(
      hint: widget.stage.name,
      sceneBackgroundPath: widget.stage.sceneBackgroundPath,
      onVictory: () {
        widget.onVictory();
        // 自己 pop，让 runStageFlow 的 push await 解开
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      onDefeat: () {
        widget.onDefeat();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Phase 4 W10: Boss 战败结算
// ──────────────────────────────────────────────────────────────────────────

/// 损失摘要 entry：用于 [_DefeatLossBanner] 渲染单角色一行。
class DefeatLossEntry {
  final String characterName;
  final int internalForceBefore;
  final int internalForceAfter;
  final String? techniqueName;
  final String? oldLayerLabel;
  final String? newLayerLabel;
  final int layersRolledBack;

  const DefeatLossEntry({
    required this.characterName,
    required this.internalForceBefore,
    required this.internalForceAfter,
    this.techniqueName,
    this.oldLayerLabel,
    this.newLayerLabel,
    this.layersRolledBack = 0,
  });
}

/// Phase 4 W11 #32 销账：主线 victory 路径战斗结算。
///
/// 从 Isar 拉玩家方角色 + 心法 + 装备 → 跑 [BattleResolutionService.resolve]
/// (isVictory=true) → in-place battleCount/skillUsage/cultivationProgress 累积 +
/// stage.dropTable roll 出装备/物品 → writeTxn putAll + 装备 owner=null 入背包 +
/// items 写/更新 inventoryItems。
///
/// **错误兜底**：Isar 未 ready / 角色为空 / finalState 异常 → 返回 null，
/// caller 跳过 victory dialog（与 _applyBossDefeatPenalty 一致风格）。
///
/// W15 #30 P3 后续 A:返回 `(drops, advancements)` 供 caller push
/// [showStageVictoryDialog] 显 drop + 升层 banner。
/// P1.1 候选 3-a:record 加 `resonanceUpgrades` 供 dialog 显共鸣度晋阶 sub-row。
Future<
    ({
      DropResult drops,
      List<AdvancementEntry> advancements,
      List<ResonanceUpgradeNotice> resonanceUpgrades,
    })?> _applyVictoryResolution({
  required WidgetRef ref,
  required StageDef stage,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return null;
  final finalState = ref.read(battleProvider);
  if (!finalState.isFinished) return null;

  final save = await isar.saveDatas.get(0);
  final ids = save?.activeCharacterIds ?? const <int>[];
  if (ids.isEmpty) return null;

  final characters = <Character>[];
  final equipsByCh = <int, List<Equipment>>{};
  final techsByCh = <int, List<Technique>>{};
  for (final cid in ids) {
    final c = await isar.characters.get(cid);
    if (c == null) continue;
    characters.add(c);

    final eqs = <Equipment>[];
    for (final eqId in [
      c.equippedWeaponId,
      c.equippedArmorId,
      c.equippedAccessoryId,
    ]) {
      if (eqId == null) continue;
      final e = await isar.equipments.get(eqId);
      if (e != null) eqs.add(e);
    }
    equipsByCh[c.id] = eqs;

    final ts = await isar.techniques
        .where()
        .filter()
        .ownerCharacterIdEqualTo(c.id)
        .findAll();
    // W13 fix: Isar @embedded list 反序列化为 fixed-length,
    // skillUsageCount.increment 走 add 分支会抛 UnsupportedError。
    // 转 growable copy 让后续 _accumulateSkillUsage 可写。
    for (final t in ts) {
      t.skillUsageCount = List.of(t.skillUsageCount);
    }
    techsByCh[c.id] = ts;
  }
  if (characters.isEmpty) return null;

  final numbers = ref.read(numbersConfigProvider);
  final dropSvc = ref.read(dropServiceProvider);

  final result = BattleResolutionService.resolve(
    finalState: finalState,
    participatingCharacters: characters,
    equipmentsByCharacter: equipsByCh,
    techniquesByCharacter: techsByCh,
    stageDef: stage,
    rng: DefaultRng(),
    progressToNextMap: numbers.cultivationProgressToNext,
    techniqueDefLookup: GameRepository.instance.getTechnique,
    dropService: dropSvc,
    isVictory: true,
    numbersConfig: numbers,
  );

  // W15 #30 第 3 期:active 3 character 每人 += stage.baseExpReward + 升层。
  // 全员 full(Demo §10 不平摊,鼓励多角色养成);apply in-place 改 character,
  // 后续 putAll 写入。
  // W15 #30 P3 后续 A:收集 AdvancementResult 暂存供 victory dialog banner。
  final advancements = <AdvancementEntry>[];
  if (stage.baseExpReward > 0) {
    // P2.2 §12.1 心魔关 unlock 拦截 hook(Batch 2.2.B):loop 外一次性算 cleared 集
    // 避免 N character 各查一次 isar(主线 stage_06_05 之后 wuSheng 各 layer 升前
    // hook 才生效;Demo Ch1-6 路径 hook 短路 false 不影响)。
    final progress = await isar.mainlineProgress
        .filter()
        .saveDataIdEqualTo(IsarSetup.currentSlotId)
        .findFirst();
    final clearedSet =
        progress?.clearedStageIds.toSet() ?? <String>{};
    final innerDemonDef = GameRepository.instance.numbers.innerDemon;
    for (final c in characters) {
      final r = CharacterAdvancementService.applyExperience(
        c,
        stage.baseExpReward,
        realmLookup: GameRepository.instance.getRealm,
        isLayerLocked: (tier, layer) => InnerDemonService.isLayerLocked(
          nextTier: tier,
          nextLayer: layer,
          innerDemonDef: innerDemonDef,
          clearedStageIds: clearedSet,
        ),
      );
      advancements.add(AdvancementEntry(chName: c.name, result: r));
    }
  }

  // P1 #42 Phase 2:isFirstClear snapshot(writeTxn 之前 read MainlineProgress,
  // 含 stageId 即 repeat,不含即首通 → bossDefeated 防刷)。
  final mainlineProgressSnapshot = await isar.mainlineProgress
      .filter()
      .saveDataIdEqualTo(IsarSetup.currentSlotId)
      .findFirst();
  final isFirstClearStage = !(mainlineProgressSnapshot?.clearedStageIds
          .contains(stage.id) ??
      false);
  final founderId = save?.founderCharacterId;

  // P1.1 候选 3-a:writeTxn 内 push notice,函数末 return 给 caller 传 dialog。
  final resonanceUpgrades = <ResonanceUpgradeNotice>[];

  final now = DateTime.now();
  await isar.writeTxn(() async {
    // in-place 副作用（battleCount / skillUsage / 主修 progress + layer + EXP）
    await isar.characters.putAll(characters);
    for (final list in techsByCh.values) {
      if (list.isNotEmpty) await isar.techniques.putAll(list);
    }
    for (final list in equipsByCh.values) {
      if (list.isNotEmpty) await isar.equipments.putAll(list);
    }
    // drops：装备 owner=null 入背包 + items 写/更新 inventoryItems
    if (result.dropResult.equipments.isNotEmpty) {
      await isar.equipments.putAll(result.dropResult.equipments);
    }
    for (final item in result.dropResult.items) {
      final existing = await isar.inventoryItems.getByDefId(item.defId);
      if (existing != null) {
        existing.quantity += item.quantity;
        existing.lastObtainedAt = now;
        await isar.inventoryItems.put(existing);
      } else {
        await isar.inventoryItems.put(
          InventoryItem()
            ..defId = item.defId
            ..itemType = _itemTypeOfMainline(item.defId)
            ..quantity = item.quantity
            ..firstObtainedAt = now
            ..lastObtainedAt = now,
        );
      }
    }

    // P1 #42 Phase 2:GameEvent 写入(同 writeTxn 原子)。
    // #3 equipmentObtained 每件 drop 装备一条;#6 realmBreakthrough 每角色判
    // didAdvance;#7 resonanceUpgraded 战斗中跨档装备;#8 bossDefeated 仅
    // isBossStage && isFirstClearStage 触发。
    final events = GameEventService(isar);
    final allEquips =
        equipsByCh.values.expand((list) => list).toList(growable: false);
    for (final eqId in result.resonanceUpgradedEquipmentIds) {
      Equipment? eq;
      for (final e in allEquips) {
        if (e.id == eqId) {
          eq = e;
          break;
        }
      }
      if (eq == null) continue;
      final def = GameRepository.instance.getEquipment(eq.defId);
      final stage = eq.resonanceStage(numbers);
      await events.recordResonanceUpgraded(
        characterId: eq.ownerCharacterId ?? founderId ?? 0,
        equipmentId: eq.id,
        equipmentName: def.name,
        newStage: stage.index + 1,
      );
      // P1.1 候选 3-a:cache notice 供 victory dialog 显共鸣度晋阶 sub-row。
      resonanceUpgrades.add(ResonanceUpgradeNotice(
        equipmentName: def.name,
        newStage: stage,
      ));
    }
    for (final drop in result.dropResult.equipments) {
      final def = GameRepository.instance.getEquipment(drop.defId);
      await events.recordEquipmentObtained(
        characterId: founderId,
        equipmentId: drop.id,
        equipmentDefId: drop.defId,
        equipmentName: def.name,
        source: stage.name,
        equipment: drop,
      );
    }
    final tutorialSvc = TutorialService(isar);
    for (final entry in advancements) {
      if (!entry.result.didAdvance) continue;
      final ch = characters.firstWhere(
        (c) => c.name == entry.chName,
        orElse: () => characters.first,
      );
      await events.recordRealmBreakthrough(
        character: ch,
        result: entry.result,
      );
      // P1 #42 Phase 2 §10 P1.y:主角达一流 → 推 step 6(收徒门槛)。
      // 沿 ch == characters.first 判定主角(test fixture 多角色升层时只对
      // founder 推进,与 founderId 路径保持一致)。
      if (founderId != null && ch.id == founderId) {
        await tutorialSvc.advanceForRealmBreakthrough(entry.result.tierAfter);
      }
    }
    if (stage.isBossStage && isFirstClearStage && founderId != null) {
      final bossName = stage.enemyTeam.isNotEmpty
          ? stage.enemyTeam.last.name
          : stage.name;
      final warborn = equipsByCh[founderId] ?? const <Equipment>[];
      await events.recordBossDefeated(
        characterId: founderId,
        stageId: stage.id,
        stageName: stage.name,
        bossName: bossName,
        warbornEquipment: warborn,
      );
    }
  });

  return (
    drops: result.dropResult,
    advancements: advancements,
    resonanceUpgrades: resonanceUpgrades,
  );
}

/// 主线 victory drop items 的 ItemType 推断（与 tower _itemTypeOf 同源）。
ItemType _itemTypeOfMainline(String defId) {
  if (defId == 'item_mojianshi') return ItemType.moJianShi;
  if (defId == 'item_xinxuejiejing') return ItemType.xinXueJieJing;
  return ItemType.miscMaterial;
}

/// Boss 关战败：从 Isar 拉玩家方角色 + 心法 + 装备，跑
/// [BattleResolutionService.resolve]（isVictory=false），写回 Isar，返回
/// 用于 UI 损失摘要展示的轻量结构。
///
/// **错误兜底**：Isar 未 ready / 角色为空 / finalState 异常 → 返回空 list，
/// caller 不展示 banner（不阻塞剧情流）。
Future<List<DefeatLossEntry>> _applyBossDefeatPenalty({
  required WidgetRef ref,
  required StageDef stage,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return const [];
  final finalState = ref.read(battleProvider);
  if (!finalState.isFinished) return const [];

  final save = await isar.saveDatas.get(0);
  final ids = save?.activeCharacterIds ?? const <int>[];
  if (ids.isEmpty) return const [];

  final characters = <Character>[];
  final equipsByCh = <int, List<Equipment>>{};
  final techsByCh = <int, List<Technique>>{};
  for (final cid in ids) {
    final c = await isar.characters.get(cid);
    if (c == null) continue;
    characters.add(c);

    final eqs = <Equipment>[];
    for (final eqId in [
      c.equippedWeaponId,
      c.equippedArmorId,
      c.equippedAccessoryId,
    ]) {
      if (eqId == null) continue;
      final e = await isar.equipments.get(eqId);
      if (e != null) eqs.add(e);
    }
    equipsByCh[c.id] = eqs;

    final ts = await isar.techniques
        .where()
        .filter()
        .ownerCharacterIdEqualTo(c.id)
        .findAll();
    // W13 fix: Isar @embedded list 反序列化为 fixed-length（同 _applyVictoryResolution）
    for (final t in ts) {
      t.skillUsageCount = List.of(t.skillUsageCount);
    }
    techsByCh[c.id] = ts;
  }
  if (characters.isEmpty) return const [];

  final numbers = ref.read(numbersConfigProvider);
  final dropSvc = ref.read(dropServiceProvider);

  final result = BattleResolutionService.resolve(
    finalState: finalState,
    participatingCharacters: characters,
    equipmentsByCharacter: equipsByCh,
    techniquesByCharacter: techsByCh,
    stageDef: stage,
    rng: DefaultRng(),
    progressToNextMap: numbers.cultivationProgressToNext,
    techniqueDefLookup: GameRepository.instance.getTechnique,
    dropService: dropSvc,
    isVictory: false,
    numbersConfig: numbers,
  );

  // 写回 Isar：受影响的 character + 所有 technique + 所有装备
  await isar.writeTxn(() async {
    await isar.characters.putAll(characters);
    for (final list in techsByCh.values) {
      if (list.isNotEmpty) await isar.techniques.putAll(list);
    }
    for (final list in equipsByCh.values) {
      if (list.isNotEmpty) await isar.equipments.putAll(list);
    }
  });

  // 构造损失摘要：只展示有 defeatPenalty 的角色
  final entries = <DefeatLossEntry>[];
  for (final ch in characters) {
    final p = result.defeatPenaltyByCharacter[ch.id];
    if (p == null) continue;
    final mainTechId = ch.mainTechniqueId;
    final mainTech = mainTechId == null
        ? null
        : techsByCh[ch.id]?.firstWhere(
            (t) => t.id == mainTechId,
            orElse: () => techsByCh[ch.id]!.first,
          );
    String? techName;
    if (mainTech != null) {
      try {
        techName = GameRepository.instance.getTechnique(mainTech.defId).name;
      } catch (_) {
        techName = null;
      }
    }
    entries.add(DefeatLossEntry(
      characterName: ch.name,
      internalForceBefore: p.internalForceBefore,
      internalForceAfter: p.internalForceAfter,
      techniqueName: techName,
      oldLayerLabel: p.didRollback ? EnumL10n.cultivationLayer(p.oldLayer) : null,
      newLayerLabel: p.didRollback ? EnumL10n.cultivationLayer(p.newLayer) : null,
      layersRolledBack: p.layersRolledBack,
    ));
  }
  return entries;
}

/// 战败损失摘要 banner（Phase 4 W10）。
///
/// 渲染于 [NarrativeReaderScreen] 顶部（在占位提示下方）。每个 entry 一行：
/// 「{角色} 内力 {before}→{after} · {心法} {oldLayer}→{newLayer} (-{N}层)」
class _DefeatLossBanner extends StatelessWidget {
  const _DefeatLossBanner({required this.entries});

  final List<DefeatLossEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: WuxiaColors.hpLow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: WuxiaColors.hpLow.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              '战败 · 散功代价',
              style: TextStyle(
                color: WuxiaColors.hpLow,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final e in entries) _entryLine(e),
        ],
      ),
    );
  }

  Widget _entryLine(DefeatLossEntry e) {
    final ifSegment = '内力 ${e.internalForceBefore}→${e.internalForceAfter}';
    String? techSegment;
    if (e.techniqueName != null && e.layersRolledBack > 0) {
      techSegment =
          '${e.techniqueName} ${e.oldLayerLabel}→${e.newLayerLabel} (-${e.layersRolledBack}层)';
    } else if (e.techniqueName != null) {
      techSegment = '${e.techniqueName} 修炼度回退';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        techSegment == null
            ? '${e.characterName}  $ifSegment'
            : '${e.characterName}  $ifSegment  ·  $techSegment',
        style: const TextStyle(
          color: WuxiaColors.textPrimary,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }
}

Future<void> _applyBossKillReputation({
  required WidgetRef ref,
  required StageDef stage,
}) async {
  if (!stage.isBossStage || stage.factionId == null) return;
  final svc = ref.read(reputationServiceProvider);
  if (svc == null) return;
  final repo = GameRepository.instance;
  final triggers = repo.numbers.jianghu.triggers;
  final factionId = stage.factionId!;

  // Boss 所属派系 -delta
  await svc.applyDelta(1, factionId, -triggers.stageBossKillDelta);

  // 对立阵营 +rivalDelta
  final rivals = repo.rivalFactionIds(factionId);
  for (final rival in rivals) {
    await svc.applyDelta(1, rival, triggers.stageBossKillRivalDelta);
  }

  ref.invalidate(reputationsForCurrentPlayerProvider);
}

Future<Formation> _pickFormation(
  BuildContext context,
  StageDef stage,
  MassBattleDef config,
) async {
  final defaultFormation = MassBattleService.formationFor(
    stageId: stage.id,
    config: config,
  );
  if (!context.mounted) return defaultFormation;
  final picked = await showDialog<Formation>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FormationPickerDialog(defaultFormation: defaultFormation),
  );
  return picked ?? defaultFormation;
}

class _FormationPickerDialog extends StatelessWidget {
  final Formation defaultFormation;
  const _FormationPickerDialog({required this.defaultFormation});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(UiStrings.massBattleFormationTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tile(context, Formation.yanXing,
              UiStrings.massBattleFormationYanXing,
              UiStrings.massBattleFormationYanXingHint),
          _tile(context, Formation.baGua,
              UiStrings.massBattleFormationBaGua,
              UiStrings.massBattleFormationBaGuaHint),
          _tile(context, Formation.fengShi,
              UiStrings.massBattleFormationFengShi,
              UiStrings.massBattleFormationFengShiHint),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Formation f, String label, String hint) {
    return ListTile(
      title: Text(label),
      subtitle: Text(hint, style: const TextStyle(fontSize: 12)),
      selected: f == defaultFormation,
      onTap: () => Navigator.of(context).pop(f),
    );
  }
}
