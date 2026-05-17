import 'dart:async';

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
import '../../battle/application/battle_resolution.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../features/equipment/application/drop_service.dart';
import '../../battle/application/stage_battle_setup.dart';
import '../../battle/presentation/battle_screen.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../../cultivation/presentation/advancement_summary.dart';
import '../../encounter/presentation/encounter_hook.dart';
import '../../event/application/game_event_service.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../../shared/strings.dart';
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
      unawaited(() async {
        final svc = TowerProgressService(isar: IsarSetup.instance);
        await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
        await svc.recordDefeat(now: DateTime.now());
      }().catchError((e, st) {
        debugPrint('runTowerFlow recordDefeat failed: $e\n$st');
      }));
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

  // Phase 4 W11 #32 销账：爬塔 victory 战斗结算（装备 battleCount / 心法 skillUsage /
  // 主修升层 in-place + writeTxn putAll）。drops 仍走下方 rollTowerRewards 路径，
  // 首通才发奖控制不变（stageDef=null 让 service.resolve 不内部 roll drops）。
  // W15 #30 P3:isFirstClear 时 EXP 写回 + 升层(沿 drops 首通发奖体例,
  // 防刷塔无脑刷 EXP)。
  // W15 #30 P3 后续 A:收 advancements 暂存供 victory dialog banner。
  final advancements = await _applyTowerVictoryResolution(
    ref: ref,
    floor: floor,
    isFirstClear: clearResult.isFirstClear,
  );
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
      final progress =
          await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
      unawaited(sync.reportClear(
        highestFloor: progress.highestClearedFloor,
        bestClearTimeMs: progress.bestClearTime,
        totalAttempts: progress.totalAttempts,
        clearedAt: progress.lastClearedAt ?? DateTime.now(),
      ).catchError((e, st) {
        debugPrint('runTowerFlow leaderboardSync reportClear failed: $e\n$st');
      }));
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
    );
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
          fallbackTitle:
              '${UiStrings.towerFloorLabel(floor.floorIndex)} · 胜利',
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
    defeatedSchools:
        floor.enemyTeam.map((e) => e.school).toList(growable: false),
  );
}

/// 推 BattleScreen 并 wait 胜/败回调。
Future<bool> _runTowerBattle({
  required BuildContext context,
  required WidgetRef ref,
  required TowerFloorDef floor,
}) async {
  final completer = Completer<bool>();
  await Navigator.of(context).push<void>(
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
  );
  if (!completer.isCompleted) completer.complete(false);
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
Future<List<AdvancementEntry>> _applyTowerVictoryResolution({
  required WidgetRef ref,
  required TowerFloorDef floor,
  required bool isFirstClear,
}) async {
  final isar = ref.read(isarProvider);
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
    // W13 fix: Isar @embedded list 反序列化为 fixed-length,
    // skillUsageCount.increment 走 add 分支会抛 UnsupportedError。
    // 转 growable copy 让后续 _accumulateSkillUsage 可写。
    for (final t in ts) {
      t.skillUsageCount = List.of(t.skillUsageCount);
    }
    techsByCh[c.id] = ts;
  }
  if (characters.isEmpty) return const [];

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
    for (final c in characters) {
      final r = CharacterAdvancementService.applyExperience(
        c,
        floor.baseExpReward,
        realmLookup: GameRepository.instance.getRealm,
      );
      advancements.add(AdvancementEntry(chName: c.name, result: r));
    }
  }

  final founderId = save?.founderCharacterId;
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
    final allEquips =
        equipsByCh.values.expand((list) => list).toList(growable: false);
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
      await events.recordResonanceUpgraded(
        characterId: eq.ownerCharacterId ?? founderId ?? 0,
        equipmentId: eq.id,
        equipmentName: def.name,
        newStage: eq.resonanceStage(numbers).index + 1,
      );
    }
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

  return advancements;
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
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(UiStrings.towerFloorLabel(floor.floorIndex)),
      content: isFirstClear
          ? _FirstClearContent(drops: drops, advancements: advancements)
          : const Text(UiStrings.towerReplayNoReward),
      actions: [
        TextButton(
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
        final (left, right) =
            await StageBattleSetup(isar: IsarSetup.instance).buildTeamsForTower(widget.floor);
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
            child: SelectableText('战斗准备失败：$_setupError'),
          ),
        ),
      );
    }
    return BattleScreen(
      hint: UiStrings.towerFloorLabel(widget.floor.floorIndex),
      onVictory: () {
        widget.onVictory();
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
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
    required this.drops,
    required this.advancements,
  });

  final DropResult drops;
  final List<AdvancementEntry> advancements;

  @override
  Widget build(BuildContext context) {
    final hasAdvanced = advancements.any((e) => e.result.didAdvance);
    if (drops.isEmpty && !hasAdvanced) {
      return const Text(UiStrings.towerFirstClearNoReward);
    }
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
      ],
    );
  }
}
