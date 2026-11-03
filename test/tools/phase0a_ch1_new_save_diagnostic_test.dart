// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_host.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

import '../support/isar_test_support.dart';
import '../support/phase0a_ch1_founder_profile.dart';
import '../support/test_data.dart';

const _stages = ['stage_01_01', 'stage_01_02', 'stage_01_03'];
const _schools = ['gang_meng', 'ling_qiao', 'yin_rou'];
const _tactics = [
  Phase0aBotTactic.seekGap,
  Phase0aBotTactic.assault,
  Phase0aBotTactic.steadyGuard,
];
const _seedCount = 3;

void main() {
  late GameRepository repository;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
  });

  test(
    'legal new save vs migrated Ch1 production encounters',
    () async {
      final arena = repository.numbers.phase0aArena;
      final delta = arena.fixedDeltaSeconds;
      final maxTicks = arena.maxSimulationTicks;
      print(
        'readable_first_clear=${Platform.environment['READABLE_FIRST_CLEAR'] == '1'}',
      );
      print(
        'school,stage,tactic,seed,outcome,ticks,hp_start,hp_end,defeated,max_active',
      );
      for (final school in _schools) {
        final dir = await Directory.systemTemp.createTemp('ch1_new_save_');
        try {
          await IsarSetup.init(directory: dir, inspector: false);
          final seeded = await seedPhase0aCh1FounderProfile(
            isar: IsarSetup.instance,
            schoolId: school,
            originId: 'mountain_wanderer',
            fateId: 'balanced_seed',
            rngSeed: 20260820,
          );
          final snapshot = seeded.snapshot;
          for (final stageId in _stages) {
            final stage = repository.getStage(stageId);
            final mapping = Phase0aStageContentMapper.mapPlayerOnly(
              contentId: stageId,
              playerSnapshot: snapshot,
              numbers: repository.numbers,
            );
            for (final tactic in _tactics) {
              for (var seed = 0; seed < _seedCount; seed++) {
                final host = await _fresh(
                  repository: repository,
                  stage: stage,
                  mapping: mapping,
                  seed: seed,
                );
                final result = host.runHeadless(
                  bot: Phase0aPlayerBotAdapter(
                    playerAdapter: host.mapping!.playerAdapter,
                    policy: Phase0aBotTacticPolicy.forTactic(tactic),
                    objectiveContinuationCommandBuilder:
                        host.objectiveContinuationCommandBuilder,
                  ),
                  deltaSeconds: delta,
                  maxTicks: maxTicks,
                );
                final defeated = result.events
                    .whereType<Phase0aEnemyDefeated>()
                    .length;
                print(
                  '$school,$stageId,${tactic.name},$seed,${result.outcome.name},'
                  '${result.ticks},${result.finalState.player.maxHealth},'
                  '${result.finalState.player.currentHealth},$defeated,'
                  '${result.finalState.enemies.length}',
                );
              }
            }
            for (var seed = 0; seed < _seedCount; seed++) {
              final host = await _fresh(
                repository: repository,
                stage: stage,
                mapping: mapping,
                seed: seed,
              );
              final events = <Phase0aEvent>[];
              var ticks = 0;
              var maxActive = 0;
              while (host.flow.outcome == Phase0aBattleOutcome.ongoing &&
                  ticks < maxTicks) {
                events.addAll(
                  host.advanceManual(
                    deltaSeconds: delta,
                    command: _kiteCommand(
                      host.flow.state,
                      host.mapping!.playerAdapter.attackRange,
                      continuation: host.objectiveContinuationCommandBuilder,
                    ),
                  ),
                );
                maxActive = max(maxActive, host.flow.state.enemies.length);
                ticks += 1;
              }
              final defeated = events.whereType<Phase0aEnemyDefeated>().length;
              final finalState = host.flow.state;
              print(
                '$school,$stageId,kite,$seed,${host.flow.outcome.name},'
                '$ticks,${finalState.player.maxHealth},'
                '${finalState.player.currentHealth},$defeated,$maxActive',
              );
            }
          }
        } finally {
          await IsarSetup.close();
          IsarSetup.resetForTest();
          await dir.delete(recursive: true);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

Phase0aPlayerCommand _kiteCommand(
  Phase0aArenaState state,
  double attackRange, {
  Phase0aObjectiveContinuationCommandBuilder? continuation,
}) {
  final player = state.player;
  final enemies = state.enemies.where((enemy) => enemy.isAlive).toList();
  if (enemies.isEmpty) {
    return continuation?.call(state) ?? const Phase0aPlayerCommand();
  }
  var target = enemies.first;
  var best = (target.position - player.position).length;
  for (final enemy in enemies.skip(1)) {
    final distance = (enemy.position - player.position).length;
    if (distance < best) {
      best = distance;
      target = enemy;
    }
  }
  final delta = target.position - player.position;
  final distance = delta.length;
  final aim = distance > 0 ? delta.normalized() : player.facing;
  final away = distance > 0 ? ArenaVector(-aim.x, -aim.y) : player.facing;
  final retreat = distance < 130;
  final approach = distance > attackRange * 0.80;
  final dodge =
      (target.chargingCast != null ||
          player.currentHealth < player.maxHealth * 0.35) &&
      player.defenseCooldownRemaining <= 0;
  return Phase0aPlayerCommand(
    left: retreat ? away.x < 0 : (approach ? aim.x < 0 : false),
    right: retreat ? away.x > 0 : (approach ? aim.x > 0 : false),
    up: retreat ? away.y < 0 : (approach ? aim.y < 0 : false),
    down: retreat ? away.y > 0 : (approach ? aim.y > 0 : false),
    attack: true,
    attackAimDirection: aim,
    defenseAction: dodge ? Phase0aDefenseAction.dodge : null,
    defenseDirection: away,
  );
}

Future<Phase0aEncounterHost> _fresh({
  required GameRepository repository,
  required StageDef stage,
  required Phase0aPlayerRuntimeMapping mapping,
  required int seed,
}) async {
  final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
    loader:
        ({
          required String stageId,
          required String encounterId,
          required int cycleIndex,
        }) async => buildPhase0aMainlineRuntimeBindingBundleFromRepository(
          stageId: stageId,
          encounterId: encounterId,
          cycleIndex: cycleIndex,
          repository: repository,
        ),
    readableFirstClearLoader:
        ({
          required String stageId,
          required String encounterId,
          required int cycleIndex,
        }) async => buildPhase0aMainlineRuntimeBindingBundleFromRepository(
          stageId: stageId,
          encounterId: encounterId,
          cycleIndex: cycleIndex,
          repository: repository,
          readableFirstClearTuning: true,
        ),
  );
  final host = await createFreshPhase0aMainlineEncounter(
    Phase0aMainlineEncounterHostBuildRequest(
      stage: stage,
      playerMapping: mapping,
      numbers: repository.numbers,
      cycleIndex: 1,
      rng: Random(seed),
      runtimeBindingSource: source,
      catalogOverride: repository.combatCatalog,
      readableFirstClearTuning:
          Platform.environment['READABLE_FIRST_CLEAR'] == '1',
    ),
  );
  if (host == null) {
    throw StateError('failed to create production host for ${stage.id}');
  }
  return host;
}
