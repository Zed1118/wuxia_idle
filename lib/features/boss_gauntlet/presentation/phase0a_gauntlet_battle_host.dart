import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/defs/boss_gauntlet_config.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/math_random.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../../battle/presentation/phase0a/phase0a_battle_controller.dart';
import '../../battle/presentation/phase0a/phase0a_battle_screen.dart';
import '../../battle/presentation/phase0a/phase0a_visual_roster.dart';
import '../application/gauntlet_providers.dart';
import '../application/phase0a_gauntlet_stage_runner.dart';

/// 断魂庄单角色 Phase 0A live 宿主；终态只回调，外层 flow 原子落会话后统一出栈。
final class Phase0aGauntletBattleHost extends ConsumerStatefulWidget {
  const Phase0aGauntletBattleHost({
    super.key,
    required this.config,
    required this.onCompleted,
  });

  final BossGauntletConfig config;
  final ValueChanged<Phase0aGauntletStageResult> onCompleted;

  @override
  ConsumerState<Phase0aGauntletBattleHost> createState() =>
      _Phase0aGauntletBattleHostState();
}

final class _Phase0aGauntletBattleHostState
    extends ConsumerState<Phase0aGauntletBattleHost> {
  String? _setupError;
  Phase0aBattleController? _controller;
  Phase0aStageMapping? _mapping;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final service = ref.read(gauntletServiceProvider);
        if (service == null) {
          throw StateError(UiStrings.gauntletSessionNotReady);
        }
        final plan = await service.preparePhase0aStage(config: widget.config);
        final numbers = GameRepository.instance.numbers;
        final mapping = Phase0aStageContentMapper.mapExpedition(
          contentId: 'gauntlet_${plan.stage}',
          enemyTeam: plan.enemyDefs,
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
          rng: newMathRandom(seed: plan.seed),
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
          _mapping = mapping;
          _controller = controller;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() => _setupError = error.toString());
      }
    });
  }

  void _onChanged() {
    final controller = _controller;
    final mapping = _mapping;
    if (controller == null || mapping == null || _notified) return;
    if (controller.outcome == Phase0aBattleOutcome.ongoing) return;
    _notified = true;
    widget.onCompleted(
      Phase0aGauntletStageResult(
        outcome: controller.outcome,
        finalState: controller.state,
        mapping: mapping,
        events: controller.events,
      ),
    );
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
        appBar: AppBar(title: const Text(UiStrings.gauntletName)),
        body: Center(
          child: SelectableText(UiStrings.battleSetupFailed(_setupError!)),
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
