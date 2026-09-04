import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/defs/tower_floor_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/math_random.dart';
import '../../battle/application/phase0a/combat_content_ref.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../../battle/presentation/phase0a/phase0a_battle_controller.dart';
import '../../battle/presentation/phase0a/phase0a_battle_screen.dart';
import '../../battle/presentation/phase0a/phase0a_visual_roster.dart';
import '../application/phase0a_tower_encounter_host.dart';
import '../application/tower_providers.dart';

/// Phase 0A 塔层单角色战斗宿主。
///
/// 胜利只回调，外层塔流程在战斗画面上完成仪式后统一 pop；战败回调后自
/// pop。系统返回不触发回调，由入口 completer 按中途退出处理，零结算污染。
class Phase0aTowerBattleHost extends ConsumerStatefulWidget {
  const Phase0aTowerBattleHost({
    super.key,
    required this.floor,
    required this.participantId,
    required this.onVictory,
    required this.onDefeat,
    this.playerSnapshotForTest,
    this.cycleIndexForTest,
    this.seedForTest,
  });

  final TowerFloorDef floor;
  final int participantId;
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
  Phase0aTowerCombatSession? _session;
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
        final rng = widget.seedForTest == null
            ? ref.read(mathRandomProvider)
            : newMathRandom(seed: widget.seedForTest);
        final session =
            await ref.read(phase0aTowerCombatSessionFactoryProvider)(
              Phase0aTowerCombatSessionBuildRequest(
                contentRef: CombatContentRef.tower(
                  'tower_${widget.floor.floorIndex}',
                ),
                floor: widget.floor,
                playerSnapshot: playerSnapshot,
                numbers: numbers,
                cycleIndex: cycleIndex,
                rng: rng,
              ),
            );
        final roster = Phase0aVisualRoster.fromCombatants(
          playerId: session.flow.state.player.id,
          combatants: session.combatants,
        );
        for (final combatant in session.combatants) {
          roster.visualFor(combatant.actorId);
        }
        if (!mounted) return;
        final controller = Phase0aBattleController(
          flow: session.flow,
          roster: roster,
          fixedDeltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        );
        controller.addListener(_onControllerChanged);
        setState(() {
          _session = session;
          _controller = controller;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _setupError = e.toString());
      }
    });
  }

  Future<CombatantSnapshot> _buildPlayerSnapshot() =>
      resolveTowerParticipantSnapshot(
        isar: IsarSetup.instance,
        requestedParticipantId: widget.participantId,
      );

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null || _exitNotified) return;
    final outcome = controller.outcome;
    if (outcome == Phase0aBattleOutcome.ongoing) return;
    final session = _session;
    if (session == null) return;
    _exitNotified = true;
    final settlement = session.settle(
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
      numericSkillBindings: _session!.playerAdapter.numericSkillBindings,
      basicAttackRange: _session!.playerAdapter.attackRange,
    );
  }
}
