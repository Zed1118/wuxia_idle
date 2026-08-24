import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/math_random.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_encounter_host.dart';
import '../../battle/application/phase0a/phase0a_player_input_adapter.dart';
import '../../battle/application/phase0a/phase0a_settlement_adapter.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../application/phase0a_mainline_encounter_host.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../../battle/presentation/phase0a/phase0a_battle_controller.dart';
import '../../battle/presentation/phase0a/phase0a_battle_screen.dart';
import '../../battle/presentation/phase0a/phase0a_visual_roster.dart';

/// Phase 1 纵切实机接线(拍板 α 灰度门)的主线 0A 战斗宿主。
///
/// 主线唯一战斗宿主，终局语义保持既有主线流程:
/// - victory:只回调不 pop —— runStageFlow 胜利段收尾时统一 pop;
/// - defeat:回调 + 自 pop(外层进战败重试/剧情分支);
/// - 系统返回致 pop 未触发回调 → _runPhase0aBattle 的 completer 兜底
///   记 (won:false, surrendered:false),与旧宿主同口径(零存档污染)。
///
/// 重试语义走 runStageFlow 循环头(新 host 新装配新 seed),故屏内
/// retryFlowBuilder 传 null(终局不出现「再战」,避免双轨重试)。
///
/// [playerSnapshotForTest] / [seedForTest] 仅供 widget test 注入,
/// 生产端勿传(沿 stage_entry_flow DI 体例)。
class Phase0aMainlineBattleHost extends ConsumerStatefulWidget {
  const Phase0aMainlineBattleHost({
    super.key,
    required this.stage,
    required this.onVictory,
    required this.onDefeat,
    this.cycleIndex = 1,
    this.playerSnapshotForTest,
    this.seedForTest,
    this.massBattleFormation,
    this.encounterHostFactory,
  });

  final StageDef stage;
  final ValueChanged<CombatSettlementSnapshot> onVictory;
  final ValueChanged<CombatSettlementSnapshot> onDefeat;
  final int cycleIndex;
  final Formation? massBattleFormation;

  @visibleForTesting
  final Phase0aMainlineEncounterHostFactory? encounterHostFactory;

  @visibleForTesting
  final CombatantSnapshot? playerSnapshotForTest;

  @visibleForTesting
  final int? seedForTest;

  @override
  ConsumerState<Phase0aMainlineBattleHost> createState() =>
      _Phase0aMainlineBattleHostState();
}

class _Phase0aMainlineBattleHostState
    extends ConsumerState<Phase0aMainlineBattleHost> {
  String? _setupError;
  Phase0aBattleController? _controller;
  Phase0aStageMapping? _mapping;
  Phase0aEncounterHost? _encounterHost;
  Phase0aVisualRoster? _visualRoster;
  Phase0aPlayerInputAdapter? _playerAdapter;
  bool _exitNotified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final playerSnapshot =
            widget.playerSnapshotForTest ?? await _buildPlayerSnapshot();
        if (!mounted) return;
        final numbers = GameRepository.instance.numbers;
        final playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
          contentId: widget.stage.id,
          playerSnapshot: playerSnapshot,
          numbers: numbers,
        );
        final rng = widget.seedForTest == null
            ? ref.read(mathRandomProvider)
            : newMathRandom(seed: widget.seedForTest);
        final Phase0aMainlineEncounterHostFactory factory =
            widget.encounterHostFactory ??
            ref.read(phase0aMainlineEncounterHostFactoryProvider);
        final runtimeBindingSource = ref.read(
          phase0aMainlineEncounterRuntimeBindingSourceProvider,
        );
        final routeAuthority = ref.read(
          phase0aMainlineEncounterRouteAuthorityProvider,
        );
        final encounterHost = await factory(
          Phase0aMainlineEncounterHostBuildRequest(
            stage: widget.stage,
            playerMapping: playerMapping,
            numbers: numbers,
            cycleIndex: widget.cycleIndex,
            rng: rng,
            runtimeBindingSource: runtimeBindingSource,
            routeAuthority: routeAuthority,
          ),
        );
        final mapping = encounterHost == null
            ? switch (widget.stage.stageType) {
                StageType.innerDemon => Phase0aStageContentMapper.mapInnerDemon(
                  stage: widget.stage,
                  playerSnapshot: playerSnapshot,
                  numbers: numbers,
                  cycleIndex: widget.cycleIndex,
                ),
                StageType.lightFoot => Phase0aStageContentMapper.mapLightFoot(
                  stage: widget.stage,
                  playerSnapshot: playerSnapshot,
                  numbers: numbers,
                  cycleIndex: widget.cycleIndex,
                ),
                StageType.massBattle => Phase0aStageContentMapper.mapMassBattle(
                  stage: widget.stage,
                  playerSnapshot: playerSnapshot,
                  numbers: numbers,
                  cycleIndex: widget.cycleIndex,
                  formation: widget.massBattleFormation,
                ),
                _ => Phase0aStageContentMapper.map(
                  stage: widget.stage,
                  playerSnapshot: playerSnapshot,
                  numbers: numbers,
                  cycleIndex: widget.cycleIndex,
                ),
              }
            : null;
        final selectedMapping = encounterHost?.mapping;
        if (encounterHost != null && selectedMapping == null) {
          throw StateError('migrated encounter host must expose a mapping');
        }
        final roster = encounterHost == null
            ? Phase0aVisualRoster.fromMapping(mapping!)
            : Phase0aVisualRoster.fromCombatants(
                playerId: selectedMapping!.initialState.player.id,
                combatants: selectedMapping.combatants,
                assetPathByActorId: encounterHost.visualAssetPathByActorId,
              );
        final selectedPlayerAdapter =
            selectedMapping?.playerAdapter ?? mapping!.playerAdapter;
        for (final combatant
            in selectedMapping?.combatants ?? mapping!.combatants) {
          roster.visualFor(combatant.actorId);
        }
        final flow =
            encounterHost?.flow ??
            Phase0aProductionFlowAssembler.assemble(
              initialState: mapping!.initialState,
              waves: mapping.waves,
              combatants: mapping.combatants,
              moveBindings: mapping.moveBindings,
              numbers: numbers,
              rng: rng,
              playerAdapter: mapping.playerAdapter,
              enemyAiAdapter: mapping.enemyAiAdapter,
              waveTransitionPolicy: mapping.waveTransitionPolicy,
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
          _encounterHost = encounterHost;
          _visualRoster = roster;
          _playerAdapter = selectedPlayerAdapter;
          _controller = controller;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _setupError = e.toString());
      }
    });
  }

  /// 生产路径:单主角续传(D3=α)= 祖师一人出战。
  ///
  /// 走 [PlayerCombatantSnapshotAssembler.loadExactRoster] 复用生产装配全套
  /// 口径(autoFill/祖师 buff/伤势/装备),零数值分叉。
  Future<CombatantSnapshot> _buildPlayerSnapshot() async {
    final isar = IsarSetup.instance;
    final save = await isar.saveDatas.get(0);
    final playerId = await CurrentLeaderResolver.resolve(
      save: save,
      characterExists: (characterId) async =>
          await isar.characters.get(characterId) != null,
    );
    final team = await PlayerCombatantSnapshotAssembler(
      isar: isar,
    ).loadExactRoster([playerId]);
    if (team.isEmpty) {
      throw StateError('Phase0a 主线宿主: 玩家队伍装配为空');
    }
    return team.first;
  }

  /// 终局一次性通知:victory 不 pop(外层胜利段收尾 pop),defeat 自 pop。
  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null || _exitNotified) return;
    final outcome = controller.outcome;
    if (outcome == Phase0aBattleOutcome.ongoing) return;
    final mapping = _mapping;
    final encounterHost = _encounterHost;
    if (mapping == null && encounterHost == null) return;
    _exitNotified = true;
    final settlement = encounterHost == null
        ? Phase0aSettlementAdapter.fromMapping(
            mapping: mapping!,
            outcome: outcome,
            finalState: controller.state,
            events: controller.events,
          )
        : encounterHost
              .settle(
                outcome: outcome,
                finalState: controller.state,
                events: controller.events,
              )
              .snapshot;
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
        appBar: AppBar(title: Text(widget.stage.name)),
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
    final visualRoster = _visualRoster;
    final playerAdapter = _playerAdapter;
    if (visualRoster == null || playerAdapter == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Phase0aBattleScreen(
      controller: controller,
      numericSkillBindings: playerAdapter.numericSkillBindings,
    );
  }
}
