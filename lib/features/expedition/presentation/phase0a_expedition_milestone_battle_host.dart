import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/math_random.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_settlement_adapter.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../../battle/presentation/phase0a/phase0a_battle_controller.dart';
import '../../battle/presentation/phase0a/phase0a_battle_screen.dart';
import '../../battle/presentation/phase0a/phase0a_visual_roster.dart';
import '../application/expedition_providers.dart';
import '../application/expedition_service.dart';

/// 百草岭首次险关的可见真人战斗宿主。
///
/// 这里只装配既有 Phase 0A 生产 flow；待办、奖励、防重和自动化解锁仍由
/// [ExpeditionService] 的同一事务 owner 提交。
final class Phase0aExpeditionMilestoneBattleHost
    extends ConsumerStatefulWidget {
  const Phase0aExpeditionMilestoneBattleHost({
    super.key,
    required this.request,
    required this.onCompleted,
  });

  final ActivityParticipationRequest request;
  final ValueChanged<bool> onCompleted;

  @override
  ConsumerState<Phase0aExpeditionMilestoneBattleHost> createState() =>
      _Phase0aExpeditionMilestoneBattleHostState();
}

final class _Phase0aExpeditionMilestoneBattleHostState
    extends ConsumerState<Phase0aExpeditionMilestoneBattleHost> {
  String? _setupError;
  Phase0aBattleController? _controller;
  Phase0aStageMapping? _mapping;
  ExpeditionManualMilestonePlan? _plan;
  bool _settling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final service = ref.read(expeditionServiceProvider);
        final config = ref.read(expeditionConfigProvider);
        if (service == null || config == null) {
          throw StateError(UiStrings.expeditionManualMilestoneUnavailable);
        }
        final plan = await service.prepareManualMilestone(
          request: widget.request,
        );
        final numbers = GameRepository.instance.numbers;
        final mapping = Phase0aStageContentMapper.mapExpedition(
          contentId: '${plan.routeId}:${plan.milestoneId}',
          enemyTeam: config.enemiesForNode(
            nodeIndex: plan.nodeIndex,
            nodeSeed: plan.nodeSeed,
            elite: true,
          ),
          playerSnapshot: plan.playerSnapshot,
          numbers: numbers,
          cycleIndex: plan.cycleIndex,
        );
        final roster = Phase0aVisualRoster.fromMapping(mapping);
        for (final combatant in mapping.combatants) {
          roster.visualFor(combatant.actorId);
        }
        final flow = Phase0aProductionFlowAssembler.assemble(
          initialState: mapping.initialState,
          waves: mapping.waves,
          combatants: mapping.combatants,
          moveBindings: mapping.moveBindings,
          numbers: numbers,
          rng: newMathRandom(seed: plan.nodeSeed),
          playerAdapter: mapping.playerAdapter,
          enemyAiAdapter: mapping.enemyAiAdapter,
        );
        if (!mounted) return;
        final controller = Phase0aBattleController(
          flow: flow,
          roster: roster,
          fixedDeltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        );
        controller.addListener(_onChanged);
        setState(() {
          _plan = plan;
          _mapping = mapping;
          _controller = controller;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() => _setupError = error.toString());
      }
    });
  }

  Future<void> _onChanged() async {
    final controller = _controller;
    final mapping = _mapping;
    final plan = _plan;
    if (controller == null ||
        mapping == null ||
        plan == null ||
        _settling ||
        controller.outcome == Phase0aBattleOutcome.ongoing) {
      return;
    }
    _settling = true;
    try {
      final service = ref.read(expeditionServiceProvider);
      if (service == null) {
        throw StateError(UiStrings.expeditionManualMilestoneUnavailable);
      }
      final completed = await service.completeManualMilestone(
        plan: plan,
        settlement: Phase0aSettlementAdapter.fromMapping(
          mapping: mapping,
          outcome: controller.outcome,
          finalState: controller.state,
          events: controller.events,
        ),
      );
      widget.onCompleted(completed);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _setupError = error.toString());
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
        appBar: AppBar(title: const Text(UiStrings.expeditionBaicaoName)),
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
      basicAttackRange: _mapping!.playerAdapter.attackRange,
    );
  }
}
