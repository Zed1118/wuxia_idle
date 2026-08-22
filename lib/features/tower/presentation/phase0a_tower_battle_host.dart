import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/tower_floor_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/math_random.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_settlement_adapter.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../../battle/presentation/phase0a/phase0a_battle_controller.dart';
import '../../battle/presentation/phase0a/phase0a_battle_screen.dart';
import '../../battle/presentation/phase0a/phase0a_visual_roster.dart';
import '../application/tower_providers.dart';

/// Phase 0A 塔层单角色战斗宿主。
///
/// 胜利只回调，外层塔流程在战斗画面上完成仪式后统一 pop；战败回调后自
/// pop。系统返回不触发回调，由入口 completer 按中途退出处理，零结算污染。
class Phase0aTowerBattleHost extends ConsumerStatefulWidget {
  const Phase0aTowerBattleHost({
    super.key,
    required this.floor,
    required this.onVictory,
    required this.onDefeat,
    this.playerSnapshotForTest,
    this.cycleIndexForTest,
    this.seedForTest,
  });

  final TowerFloorDef floor;
  final ValueChanged<CombatSettlementSnapshot> onVictory;
  final ValueChanged<CombatSettlementSnapshot> onDefeat;

  @visibleForTesting
  final CombatantSnapshot? playerSnapshotForTest;

  @visibleForTesting
  final int? cycleIndexForTest;

  @visibleForTesting
  final int? seedForTest;

  @override
  ConsumerState<Phase0aTowerBattleHost> createState() =>
      _Phase0aTowerBattleHostState();
}

class _Phase0aTowerBattleHostState
    extends ConsumerState<Phase0aTowerBattleHost> {
  String? _setupError;
  Phase0aBattleController? _controller;
  Phase0aStageMapping? _mapping;
  bool _exitNotified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final playerSnapshot =
            widget.playerSnapshotForTest ?? await _buildPlayerSnapshot();
        final cycleIndex =
            widget.cycleIndexForTest ??
            (await ref.read(towerProgressProvider.future)).currentCycleIndex;
        if (!mounted) return;
        final numbers = GameRepository.instance.numbers;
        final mapping = Phase0aStageContentMapper.mapTower(
          floor: widget.floor,
          playerSnapshot: playerSnapshot,
          numbers: numbers,
          cycleIndex: cycleIndex,
        );
        final roster = Phase0aVisualRoster.fromMapping(mapping);
        for (final combatant in mapping.combatants) {
          roster.visualFor(combatant.actorId);
        }
        final rng = widget.seedForTest == null
            ? ref.read(mathRandomProvider)
            : newMathRandom(seed: widget.seedForTest);
        final flow = Phase0aProductionFlowAssembler.assemble(
          initialState: mapping.initialState,
          waves: mapping.waves,
          combatants: mapping.combatants,
          moveBindings: mapping.moveBindings,
          numbers: numbers,
          rng: rng,
          playerAdapter: mapping.playerAdapter,
          enemyAiAdapter: mapping.enemyAiAdapter,
        );
        if (!mounted) return;
        final controller = Phase0aBattleController(
          flow: flow,
          roster: roster,
          fixedDeltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        );
        controller.addListener(_onControllerChanged);
        setState(() {
          _mapping = mapping;
          _controller = controller;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _setupError = e.toString());
      }
    });
  }

  Future<CombatantSnapshot> _buildPlayerSnapshot() async {
    final isar = IsarSetup.instance;
    final save = await isar.saveDatas.get(0);
    var playerId = save?.founderCharacterId;
    if (playerId == null) {
      final fallback = await isar.characters.where().findFirst();
      if (fallback == null) {
        throw StateError('Phase0a 塔宿主: Isar 没有任何 Character');
      }
      playerId = fallback.id;
    }
    final team = await PlayerCombatantSnapshotAssembler(
      isar: isar,
    ).loadExactRoster([playerId]);
    if (team.isEmpty) {
      throw StateError('Phase0a 塔宿主: 玩家队伍装配为空');
    }
    return team.first;
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null || _exitNotified) return;
    final outcome = controller.outcome;
    if (outcome == Phase0aBattleOutcome.ongoing) return;
    final mapping = _mapping;
    if (mapping == null) return;
    _exitNotified = true;
    final settlement = Phase0aSettlementAdapter.fromMapping(
      mapping: mapping,
      outcome: outcome,
      finalState: controller.state,
      events: controller.events,
    );
    if (outcome == Phase0aBattleOutcome.victory) {
      widget.onVictory(settlement);
    } else {
      widget.onDefeat(settlement);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Phase0aBattleScreen(
      controller: controller,
      numericSkillBindings: _mapping!.playerAdapter.numericSkillBindings,
    );
  }
}
