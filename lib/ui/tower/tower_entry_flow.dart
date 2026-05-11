import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../data/defs/tower_floor_def.dart';
import '../../data/game_repository.dart';
import '../../data/models/enums.dart';
import '../../data/models/equipment.dart';
import '../../data/models/inventory_item.dart';
import '../../data/narrative_loader.dart';
import '../../providers/battle_providers.dart';
import '../../providers/tower_providers.dart';
import '../../services/drop_service.dart';
import '../../services/stage_battle_setup.dart';
import '../../services/tower_progress_service.dart';
import '../../utils/rng.dart';
import '../battle/battle_screen.dart';
import '../narrative/narrative_reader_screen.dart';
import '../strings.dart';

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
Future<void> runTowerFlow({
  required BuildContext context,
  required WidgetRef ref,
  required TowerFloorDef floor,
  @visibleForTesting Future<bool> Function()? battleRunnerForTest,
  @visibleForTesting
  Future<TowerClearResult> Function(int floorIndex)? clearRecorderForTest,
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
  final bool won;
  if (battleRunnerForTest != null) {
    won = await battleRunnerForTest();
  } else {
    won = await _runTowerBattle(context: context, ref: ref, floor: floor);
  }

  // ── defeat ──
  if (!won) {
    // 不退层，只增统计；unawaited 不阻 UI
    if (defeatRecorderForTest != null) {
      unawaited(defeatRecorderForTest().catchError((_) {}));
    } else {
      unawaited(
        TowerProgressService.recordDefeat(now: DateTime.now())
            .catchError((_) {}),
      );
    }
    return;
  }

  // ── victory ──
  TowerClearResult clearResult;
  try {
    clearResult = clearRecorderForTest != null
        ? await clearRecorderForTest(floor.floorIndex)
        : await TowerProgressService.recordClear(
            floorIndex: floor.floorIndex,
            now: DateTime.now(),
          );
  } catch (_) {
    // Isar 未初始化（test env）→ 视为重打非首通
    clearResult = (isFirstClear: false, highestAfter: 0);
  }

  // ── drops（isFirstClear 控发奖；重打不发奖 CLAUDE §5.1 防刷）──
  DropResult drops = const DropResult(equipments: [], items: []);
  if (clearResult.isFirstClear && GameRepository.isLoaded) {
    drops = DropService(
      equipmentDefLookup: GameRepository.instance.getEquipment,
      defaultObtainedFrom: UiStrings.towerDropSource,
    ).rollTowerRewards(floor, DefaultRng());
    await _persistDrops(drops);
  }

  if (context.mounted) ref.invalidate(towerProgressProvider);

  // ── victory dialog ──
  if (context.mounted) {
    await _showVictoryDialog(
      context: context,
      floor: floor,
      isFirstClear: clearResult.isFirstClear,
      drops: drops,
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

/// Isar 持久化爬塔掉落（Isar.getInstance 为 null 时短路，测试安全）。
Future<void> _persistDrops(DropResult drops) async {
  if (drops.isEmpty) return;
  final isar = Isar.getInstance();
  if (isar == null) return;
  final now = DateTime.now();
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
            ..itemType = _itemTypeOf(item.defId)
            ..quantity = item.quantity
            ..firstObtainedAt = now
            ..lastObtainedAt = now,
        );
      }
    }
  });
}

/// 根据已知 item defId 推断 [ItemType]；未知 id 兜底 [ItemType.miscMaterial]。
ItemType _itemTypeOf(String defId) {
  if (defId == 'item_mojianshi') return ItemType.moJianShi;
  if (defId == 'item_xinxuejiejing') return ItemType.xinXueJieJing;
  return ItemType.miscMaterial;
}

/// 胜利奖励弹窗：首通显示掉落清单，重打显示「重打不发奖」。
Future<void> _showVictoryDialog({
  required BuildContext context,
  required TowerFloorDef floor,
  required bool isFirstClear,
  required DropResult drops,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(UiStrings.towerFloorLabel(floor.floorIndex)),
      content: isFirstClear
          ? _FirstClearContent(drops: drops)
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
            await StageBattleSetup.buildTeamsForTower(widget.floor);
        if (!mounted) return;
        ref.read(battleNotifierProvider.notifier).startBattle(left, right);
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
class _FirstClearContent extends StatelessWidget {
  const _FirstClearContent({required this.drops});

  final DropResult drops;

  @override
  Widget build(BuildContext context) {
    if (drops.isEmpty) {
      return const Text(UiStrings.towerFirstClearNoReward);
    }
    final lines = <String>[
      for (final eq in drops.equipments)
        GameRepository.isLoaded
            ? GameRepository.instance.getEquipment(eq.defId).name
            : eq.defId,
      for (final item in drops.items) '${item.defId} ×${item.quantity}',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(UiStrings.towerFirstClearLabel),
        const SizedBox(height: 4),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('· $line'),
          ),
      ],
    );
  }
}
