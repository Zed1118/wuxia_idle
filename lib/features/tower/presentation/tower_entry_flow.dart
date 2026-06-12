import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:isar_community/isar.dart';

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
import '../../../data/isar_provider.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/sound_manager.dart';
import '../../battle/application/battle_resolution.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../features/equipment/application/drop_service.dart';
import '../../battle/application/stage_battle_setup.dart';
import '../../battle/presentation/battle_screen.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../../cultivation/presentation/advancement_summary.dart';
import '../../cultivation/domain/skill_unlock_service.dart';
import '../../cultivation/presentation/stage_skill_drop_hook.dart';
import '../../encounter/presentation/encounter_hook.dart';
import '../../event/application/game_event_service.dart';
import '../../inner_demon/application/inner_demon_service.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../battle/domain/battle_stats.dart';
import '../../battle/presentation/victory_ceremony.dart';
import '../../mainline/presentation/stage_victory_dialog.dart'
    show FirstClearBanner, ResonanceUpgradeNotice, ResonanceUpgradeBanner;
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../tutorial/application/tutorial_service.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/utils/rng.dart';
import '../application/tower_progress_service.dart';
import '../application/tower_providers.dart';
import '../domain/tower_floor_def.dart';

/// Phase 3 T43 爬塔进入流程串联。
///
/// 状态机（async 串联）：
///   1. opening（仅 Boss 层且 narrativeOpeningId 非空）→ NarrativeReaderScreen
///   2. battle → push BattleScreen → wait onVictory / onDefeat
///   3a. victory → recordClear(isFirstClear) → invalidate provider
///       → T44 接入：isFirstClear true 才发奖
///       → Boss + victoryNarrative → NarrativeReaderScreen
///   3b. defeat → recordDefeat（unawaited）→ pop 回层列表
///
/// [battleRunnerForTest] / [clearRecorderForTest] / [defeatRecorderForTest]
/// 仅供 widget test 注入，生产端勿传（[@visibleForTesting]）。
@Dependencies([towerProgress])
Future<void> runTowerFlow({
  required BuildContext context,
  required WidgetRef ref,
  required TowerFloorDef floor,
  @visibleForTesting Future<bool> Function()? battleRunnerForTest,
  @visibleForTesting
  Future<TowerClearResult> Function(int floorIndex, int elapsedMs)?
  clearRecorderForTest,
  @visibleForTesting Future<void> Function()? defeatRecorderForTest,
}) async {
  // ── opening（仅 Boss 层）──
  if (floor.isBoss && floor.narrativeOpeningId != null) {
    final opening = await NarrativeLoader.load(floor.narrativeOpeningId!);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: opening,
          fallbackTitle: UiStrings.towerFloorLabel(floor.floorIndex),
        ),
      ),
    );
  }

  // ── battle ──
  if (!context.mounted) return;
  // P0.2 #40 Phase 2:计时本次战斗耗时(从 BattleScreen push 起到 onVictory/Defeat
  // 回调触发,含 push/pop 动画 ≈ 600ms 误差,可接受;不为 test 注入路径计时)
  final stopwatch = Stopwatch()..start();
  final bool won;
  if (battleRunnerForTest != null) {
    won = await battleRunnerForTest();
  } else {
    won = await _runTowerBattle(context: context, ref: ref, floor: floor);
  }
  stopwatch.stop();
  final elapsedMs = stopwatch.elapsedMilliseconds;

  // ── defeat ──
  if (!won) {
    // 不退层，只增统计；unawaited 不阻 UI
    if (defeatRecorderForTest != null) {
      unawaited(defeatRecorderForTest().catchError((_) {}));
    } else {
      // W12 fix: provider 副作用 getOrCreate 与 record* 存在 race（W6 重构遗留），
      // 主动 ensure 避免 recordDefeat 抛 StateError 后被 catchError 静默吞掉
      unawaited(
        () async {
          final svc = TowerProgressService(isar: IsarSetup.instance);
          await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
          await svc.recordDefeat(now: DateTime.now());
        }().catchError((e, st) {
          debugPrint('runTowerFlow recordDefeat failed: $e\n$st');
        }),
      );
    }
    return;
  }

  // ── victory ──
  TowerClearResult clearResult;
  try {
    if (clearRecorderForTest != null) {
      clearResult = await clearRecorderForTest(floor.floorIndex, elapsedMs);
    } else {
      // W12 fix: 同 defeat 分支，ensure getOrCreate 避免 race
      final svc = TowerProgressService(isar: IsarSetup.instance);
      await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
      clearResult = await svc.recordClear(
        floorIndex: floor.floorIndex,
        now: DateTime.now(),
        elapsedMs: elapsedMs,
      );
    }
  } catch (e, st) {
    // 加 log 便于诊断（W12 之前是 catch (_) 静默吞，Codex 视觉验收无法追踪根因）
    debugPrint('runTowerFlow recordClear unexpected failure: $e\n$st');
    clearResult = (isFirstClear: false, highestAfter: 0);
  }

  // 可玩性 P1a：爬塔 Boss 残页掉落(spec §二)。每次 Boss 胜利 rng 掉(非首通限定,
  // 重复刷集残页 grind)。纯数据写;test stub(clearRecorderForTest)路径跳过
  // (与 recordClear 一致,不依赖未初始化 IsarSetup)。
  if (clearRecorderForTest == null &&
      floor.dropSkillFragmentId != null &&
      GameRepository.isLoaded) {
    await runTowerSkillDropHookAfterVictory(
      floor: floor,
      svc: SkillUnlockService(IsarSetup.instance),
      towerFragmentDropProb:
          GameRepository.instance.numbers.skillUnlock.towerFragmentDropProb,
      rng: Random(),
    );
  }

  // Phase 4 W11 #32 销账：爬塔 victory 战斗结算（装备 battleCount / 心法 skillUsage /
  // 主修升层 in-place + writeTxn putAll）。drops 仍走下方 rollTowerRewards 路径，
  // 首通才发奖控制不变（stageDef=null 让 service.resolve 不内部 roll drops）。
  // W15 #30 P3:isFirstClear 时 EXP 写回 + 升层(沿 drops 首通发奖体例,
  // 防刷塔无脑刷 EXP)。
  // W15 #30 P3 后续 A:收 advancements 暂存供 victory dialog banner。
  // P1.1 候选 3-a:同段收 resonanceUpgrades 供 dialog 显共鸣度晋阶 sub-row。
  final victoryRes = await _applyTowerVictoryResolution(
    ref: ref,
    floor: floor,
    isFirstClear: clearResult.isFirstClear,
  );
  final advancements = victoryRes.advancements;
  final resonanceUpgrades = victoryRes.resonanceUpgrades;
  // W13-v3 fix: invalidate character/equipment/technique family,否则下次进
  // 角色面板看到 Riverpod 缓存的旧 battleCount / cultivationProgress
  ref.invalidate(characterByIdProvider);
  ref.invalidate(equipmentByIdProvider);
  ref.invalidate(techniqueByIdProvider);
  ref.invalidate(characterAllTechniquesProvider);
  ref.invalidate(allEquipmentsProvider);

  // ── drops（isFirstClear 控发奖；重打不发奖 CLAUDE §5.1 防刷）──
  DropResult drops = const DropResult(equipments: [], items: []);
  if (clearResult.isFirstClear && GameRepository.isLoaded) {
    drops = DropService(
      equipmentDefLookup: GameRepository.instance.getEquipment,
      defaultObtainedFrom: UiStrings.towerDropSource,
    ).rollTowerRewards(floor, DefaultRng());
    await _persistDrops(ref, drops, floor: floor);
  }

  // ── leaderboard sync(P0.2 #40 Phase 3,D 方案 Noop placeholder)──
  // 仅 isFirstClear 触发(GDD §5.1 反主流防刷,与 drops 同纪律);
  // 整段 try-catch 兜底(IsarSetup 未 init / progress 读失败时降级,
  // unawaited reportClear 内再 catchError 防 Future 飘错);
  // memory feedback_layered_bugs 警示:留 log 不静默吞 + 下层 bug 不掩盖主流程。
  // 接 Supabase 时只换 leaderboardSyncProvider 注入,本 hook 0 改动。
  if (clearResult.isFirstClear) {
    try {
      final sync = ref.read(leaderboardSyncProvider);
      final svc = TowerProgressService(isar: IsarSetup.instance);
      final progress = await svc.getOrCreate(
        saveDataId: IsarSetup.currentSlotId,
      );
      unawaited(
        sync
            .reportClear(
              highestFloor: progress.highestClearedFloor,
              bestClearTimeMs: progress.bestClearTime,
              totalAttempts: progress.totalAttempts,
              clearedAt: progress.lastClearedAt ?? DateTime.now(),
            )
            .catchError((e, st) {
              debugPrint(
                'runTowerFlow leaderboardSync reportClear failed: $e\n$st',
              );
            }),
      );
    } catch (e, st) {
      debugPrint('runTowerFlow leaderboardSync setup failed: $e\n$st');
    }
  }

  if (context.mounted) ref.invalidate(towerProgressProvider);

  // ── victory dialog ──
  if (context.mounted) {
    await _showVictoryDialog(
      context: context,
      floor: floor,
      isFirstClear: clearResult.isFirstClear,
      drops: drops,
      advancements: advancements,
      resonanceUpgrades: resonanceUpgrades,
      stats: victoryRes.stats,
    );
  }

  // 胜利仪式 + 结算在战斗界面之上播完,退回塔层列表。
  if (context.mounted && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }

  // victory narrative（仅 Boss 层）
  if (floor.isBoss && floor.narrativeVictoryId != null) {
    if (!context.mounted) return;
    final victory = await NarrativeLoader.load(floor.narrativeVictoryId!);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: victory,
          fallbackTitle: '${UiStrings.towerFloorLabel(floor.floorIndex)} · 胜利',
        ),
      ),
    );
  }

  // Phase 4 W14-2:爬塔 victory 也接奇遇 hook(与主线共享 encounter_hook)。
  // 放在 victory narrative 之后,与 stage_entry_flow 体例一致。
  if (!context.mounted) return;
  await runEncounterHookAfterVictory(
    context: context,
    ref: ref,
    defeatedSchools: floor.enemyTeam
        .map((e) => e.school)
        .toList(growable: false),
  );
}

/// 推 BattleScreen 并 wait 胜/败回调。
Future<bool> _runTowerBattle({
  required BuildContext context,
  required WidgetRef ref,
  required TowerFloorDef floor,
}) async {
  final completer = Completer<bool>();
  // 不 await push:胜利时 BattleScreen 留栈,由 runTowerFlow 播完仪式/结算后再 pop。
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => _TowerBattleHost(
        floor: floor,
        onVictory: () {
          if (!completer.isCompleted) completer.complete(true);
        },
        onDefeat: () {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    ),
  ).then((_) {
    if (!completer.isCompleted) completer.complete(false);
  });
  return completer.future;
}

/// Phase 4 W11 #32 销账：爬塔 victory 战斗结算（in-place 副作用 + 写回 Isar）。
///
/// 与主线 `_applyVictoryResolution` 体例对齐，但传 `stageDef: null` 让
/// [BattleResolutionService.resolve] 不内部 roll drops（爬塔走 rollTowerRewards
/// + isFirstClear 首通发奖控制，落地在 _persistDrops；此函数仅取
/// battleCount / skillUsage / cultivationEvents 副作用）。
///
/// W15 #30 P3:[isFirstClear] 时 active 3 character 每人 += floor.baseExpReward
/// + 升层(沿 drops 首通发奖体例,防刷塔无脑刷 EXP)。
///
/// **错误兜底**：Isar 未 ready / 角色为空 / finalState 异常 → 返回空 list，
/// caller dialog 仅显 drop 部分不显升层 banner（不阻塞 victory dialog / narrative）。
///
/// W15 #30 P3 后续 A:返回升层结果 list 供 caller push `_showVictoryDialog`
/// 时显多角色升层 banner。
/// P1.1 候选 3-a:record 加 `resonanceUpgrades` 供 dialog 显共鸣度晋阶 sub-row。
Future<
  ({
    List<AdvancementEntry> advancements,
    List<ResonanceUpgradeNotice> resonanceUpgrades,
    BattleStatsSummary stats,
  })
>
_applyTowerVictoryResolution({
  required WidgetRef ref,
  required TowerFloorDef floor,
  required bool isFirstClear,
}) async {
  const empty = (
    advancements: <AdvancementEntry>[],
    resonanceUpgrades: <ResonanceUpgradeNotice>[],
    stats: BattleStatsSummary(totalDamage: 0, critCount: 0, totalTicks: 0),
  );
  final isar = ref.read(isarProvider);
  if (isar == null) return empty;
  final finalState = ref.read(battleProvider);
  if (!finalState.isFinished) return empty;
  final stats = BattleStatsSummary.from(finalState);

  final save = await isar.saveDatas.get(0);
  final ids = save?.activeCharacterIds ?? const <int>[];
  if (ids.isEmpty) return empty;

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
  if (characters.isEmpty) return empty;

  final numbers = ref.read(numbersConfigProvider);
  final dropSvc = ref.read(dropServiceProvider);

  final battleResult = BattleResolutionService.resolve(
    finalState: finalState,
    participatingCharacters: characters,
    equipmentsByCharacter: equipsByCh,
    techniquesByCharacter: techsByCh,
    rng: DefaultRng(),
    progressToNextMap: numbers.cultivationProgressToNext,
    techniqueDefLookup: GameRepository.instance.getTechnique,
    dropService: dropSvc,
    isVictory: true,
    numbersConfig: numbers,
    // stageDef: null —— 爬塔不走 service 内部 roll drops；drops 在外层
    // rollTowerRewards + _persistDrops 单独控制（首通才发奖）
  );

  // W15 #30 P3:isFirstClear 时 active 3 character 每人 += floor.baseExpReward
  // + 升层(重打不发奖,沿 drops 体例防刷)。
  // W15 #30 P3 后续 A:收集 AdvancementResult 供 victory dialog banner。
  final advancements = <AdvancementEntry>[];
  if (isFirstClear && floor.baseExpReward > 0) {
    // P2.2 §12.1 心魔关 unlock 拦截 hook(Batch 2.2.B):loop 外一次性算 cleared 集
    // 避免 N character 各查一次 isar(爬塔通常 wuSheng 以下,hook 短路 false 不影响)。
    final progress = await IsarSetup.instance.mainlineProgress
        .filter()
        .saveDataIdEqualTo(IsarSetup.currentSlotId)
        .findFirst();
    final clearedSet = progress?.clearedStageIds.toSet() ?? <String>{};
    final innerDemonDef = GameRepository.instance.numbers.innerDemon;
    for (final c in characters) {
      final r = CharacterAdvancementService.applyExperience(
        c,
        floor.baseExpReward,
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

  final founderId = save?.founderCharacterId;
  // P1.1 候选 3-a:writeTxn 内 push notice,函数末 return 给 caller 传 dialog。
  final resonanceUpgrades = <ResonanceUpgradeNotice>[];
  await isar.writeTxn(() async {
    await isar.characters.putAll(characters);
    for (final list in techsByCh.values) {
      if (list.isNotEmpty) await isar.techniques.putAll(list);
    }
    for (final list in equipsByCh.values) {
      if (list.isNotEmpty) await isar.equipments.putAll(list);
    }

    // P1 #42 Phase 2:GameEvent 写入(同 writeTxn 原子)。
    // #6 realmBreakthrough 每角色判 didAdvance;#7 resonanceUpgraded 战斗中跨档;
    // #8 bossDefeated 仅 floor.isBoss && isFirstClear 防刷(沿 drops 体例)。
    final events = GameEventService(isar);
    final allEquips = equipsByCh.values
        .expand((list) => list)
        .toList(growable: false);
    for (final eqId in battleResult.resonanceUpgradedEquipmentIds) {
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
      resonanceUpgrades.add(
        ResonanceUpgradeNotice(equipmentName: def.name, newStage: stage),
      );
    }
    final tutorialSvc = TutorialService(isar);
    for (final entry in advancements) {
      if (!entry.result.didAdvance) continue;
      final ch = characters.firstWhere(
        (c) => c.name == entry.chName,
        orElse: () => characters.first,
      );
      await events.recordRealmBreakthrough(character: ch, result: entry.result);
      // P1 #42 Phase 2 §10 P1.y:主角达一流 → 推 step 6(收徒门槛)。
      if (founderId != null && ch.id == founderId) {
        await tutorialSvc.advanceForRealmBreakthrough(entry.result.tierAfter);
      }
    }
    if (floor.isBoss && isFirstClear && founderId != null) {
      final bossName = floor.enemyTeam.isNotEmpty
          ? floor.enemyTeam.last.name
          : UiStrings.towerFloorLabel(floor.floorIndex);
      final warborn = equipsByCh[founderId] ?? const <Equipment>[];
      await events.recordBossDefeated(
        characterId: founderId,
        stageId: 'tower_floor_${floor.floorIndex}',
        stageName: UiStrings.towerFloorLabel(floor.floorIndex),
        bossName: bossName,
        warbornEquipment: warborn,
      );
    }
  });

  return (advancements: advancements, resonanceUpgrades: resonanceUpgrades, stats: stats);
}

/// Isar 持久化爬塔掉落（W6 nullable propagation：isarProvider 为 null 时短路，测试安全）。
///
/// P1 #42 Phase 2:加 [floor] 入参,内部同事务写入 #3 equipmentObtained GameEvent。
Future<void> _persistDrops(
  WidgetRef ref,
  DropResult drops, {
  TowerFloorDef? floor,
}) async {
  if (drops.isEmpty) return;
  final isar = ref.read(isarProvider);
  if (isar == null) return;
  final now = DateTime.now();
  final save = await isar.saveDatas.get(0);
  final founderId = save?.founderCharacterId;
  await isar.writeTxn(() async {
    if (drops.equipments.isNotEmpty) {
      await isar.equipments.putAll(drops.equipments);
    }
    for (final item in drops.items) {
      final existing = await isar.inventoryItems.getByDefId(item.defId);
      if (existing != null) {
        existing.quantity += item.quantity;
        existing.lastObtainedAt = now;
        await isar.inventoryItems.put(existing);
      } else {
        await isar.inventoryItems.put(
          InventoryItem()
            ..defId = item.defId
            ..itemType = ItemType.fromDefId(item.defId)
            ..quantity = item.quantity
            ..firstObtainedAt = now
            ..lastObtainedAt = now,
        );
      }
    }

    // P1 #42 Phase 2:GameEvent #3 equipmentObtained(同事务原子)。
    if (drops.equipments.isNotEmpty && floor != null) {
      final events = GameEventService(isar);
      final source = UiStrings.towerFloorLabel(floor.floorIndex);
      for (final drop in drops.equipments) {
        final def = GameRepository.instance.getEquipment(drop.defId);
        await events.recordEquipmentObtained(
          characterId: founderId,
          equipmentId: drop.id,
          equipmentDefId: drop.defId,
          equipmentName: def.name,
          source: source,
          equipment: drop,
        );
      }
    }
  });
}

/// 胜利奖励弹窗：首通显示掉落清单，重打显示「重打不发奖」。
///
/// W15 #30 P3 后续 A:加 advancements 参数,首通时在 drop 列后追升层 banner。
Future<void> _showVictoryDialog({
  required BuildContext context,
  required TowerFloorDef floor,
  required bool isFirstClear,
  required DropResult drops,
  required List<AdvancementEntry> advancements,
  List<ResonanceUpgradeNotice> resonanceUpgrades = const [],
  BattleStatsSummary? stats,
}) async {
  // 胜利仪式分档:首通有重器→爆品镜头;否则(普通/重打)→简版勝。
  // realmAdvance 在仪式之后、随 dialog 出现时响,避免 fanfare 早响 1.3s。
  await presentVictoryCeremony(context, drops, treasureGate: isFirstClear);
  if (!context.mounted) return;
  // 结算 jingle:跨 tier 大境界突破响 realmAdvance(首通限定)。
  if (isFirstClear && advancements.any((e) => e.result.crossedTier)) {
    SoundManager.instance.playSfx(SfxId.realmAdvance);
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(UiStrings.towerFloorLabel(floor.floorIndex)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isFirstClear
              ? _FirstClearContent(
                  floor: floor,
                  drops: drops,
                  advancements: advancements,
                  resonanceUpgrades: resonanceUpgrades,
                )
              : const Text(UiStrings.towerReplayNoReward),
          if (stats != null) ...[
            const SizedBox(height: 12),
            Text(
              UiStrings.battleSummary(
                  stats.totalDamage, stats.critCount, stats.totalTicks),
              style: const TextStyle(
                  color: WuxiaColors.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: WuxiaColors.resultHighlight,
          ),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(UiStrings.towerVictoryConfirm),
        ),
      ],
    ),
  );
}

/// BattleScreen 的 setup 容器（爬塔版，对应主线 _StageBattleHost）。
class _TowerBattleHost extends ConsumerStatefulWidget {
  const _TowerBattleHost({
    required this.floor,
    required this.onVictory,
    required this.onDefeat,
  });

  final TowerFloorDef floor;
  final VoidCallback onVictory;
  final VoidCallback onDefeat;

  @override
  ConsumerState<_TowerBattleHost> createState() => _TowerBattleHostState();
}

class _TowerBattleHostState extends ConsumerState<_TowerBattleHost> {
  String? _setupError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final (left, right) = await StageBattleSetup(
          isar: IsarSetup.instance,
        ).buildTeamsForTower(widget.floor);
        if (!mounted) return;
        ref.read(battleProvider.notifier).startBattle(left, right);
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
        appBar: AppBar(
          title: Text(UiStrings.towerFloorLabel(widget.floor.floorIndex)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(UiStrings.battleSetupFailed(_setupError!)),
          ),
        ),
      );
    }
    return BattleScreen(
      hint: UiStrings.towerFloorLabel(widget.floor.floorIndex),
      sceneBackgroundPath: widget.floor.sceneBackgroundPath,
      bgmTrack: BgmTrack.tower,
      deferVictoryToCaller: true,
      onVictory: () {
        widget.onVictory();
        // 不 pop:胜利仪式由 runTowerFlow 在战斗界面之上播完后再 pop。
      },
      onDefeat: () {
        widget.onDefeat();
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
    );
  }
}

/// 首通奖励清单（DropResult 非空时列条目，空则显示「无固定奖励」）。
///
/// W15 #30 P3 后续 A:drop 列后追多角色升层 banner([AdvancementSummary])。
class _FirstClearContent extends StatelessWidget {
  const _FirstClearContent({
    required this.floor,
    required this.drops,
    required this.advancements,
    this.resonanceUpgrades = const [],
  });

  final TowerFloorDef floor;
  final DropResult drops;
  final List<AdvancementEntry> advancements;
  final List<ResonanceUpgradeNotice> resonanceUpgrades;

  @override
  Widget build(BuildContext context) {
    final hasAdvanced = advancements.any((e) => e.result.didAdvance);
    final hasResonance = resonanceUpgrades.isNotEmpty;
    final lines = <String>[
      for (final eq in drops.equipments)
        GameRepository.isLoaded
            ? GameRepository.instance.getEquipment(eq.defId).name
            : eq.defId,
      for (final item in drops.items)
        '${EnumL10n.itemType(ItemType.fromDefId(item.defId))} ×${item.quantity}',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FirstClearBanner(
          title: UiStrings.towerFirstClearCeremony(
            floor.floorIndex,
            isBoss: floor.isBoss,
          ),
        ),
        const SizedBox(height: 12),
        if (drops.isEmpty)
          const Text(UiStrings.towerFirstClearNoReward)
        else ...[
          const Text(UiStrings.towerFirstClearLabel),
          const SizedBox(height: 4),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('· $line'),
            ),
        ],
        if (hasAdvanced) ...[
          const SizedBox(height: 12),
          AdvancementSummary(entries: advancements),
        ],
        if (hasResonance) ...[
          const SizedBox(height: 12),
          ResonanceUpgradeBanner(notices: resonanceUpgrades),
        ],
      ],
    );
  }
}
