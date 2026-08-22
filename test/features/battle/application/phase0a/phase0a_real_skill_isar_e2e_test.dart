import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/shared/battle_shared/player_combatant_snapshot_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

import '../../../../support/isar_test_support.dart';
import '../../../../support/test_data.dart';

void main() {
  late Directory tempDir;
  late GameRepository repo;

  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase0a_real_skill_isar_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test(
    '真实 Isar loadout → 1–6 binding → bot → settlement skill id 全链',
    () async {
      await Phase2SeedService(isar: IsarSetup.instance).seedP3();
      final player = (await PlayerCombatantSnapshotAssembler(
        isar: IsarSetup.instance,
      ).loadExactRoster(const [1])).single;
      final numbers = repo.numbers;
      final mapping = Phase0aStageContentMapper.map(
        stage: repo.getStage('stage_01_01'),
        playerSnapshot: player,
        numbers: numbers,
      );
      expect(mapping.numericSkillBindings.equipped, isNotEmpty);

      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: numbers,
        rng: Random(20260820),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
      );
      final result = Phase0aHeadlessRunner.runToEnd(
        flow: flow,
        bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: numbers.phase0aArena.maxSimulationTicks,
      );
      expect(result.outcome, Phase0aBattleOutcome.victory);

      final settlement = Phase0aSettlementAdapter.fromMapping(
        mapping: mapping,
        outcome: result.outcome,
        finalState: result.finalState,
        events: result.events,
      );
      final equippedIds = {
        ...player.skillLoadout.ids,
        ?player.skillLoadout.basicAttack?.id,
      };
      final tacticalIds = {
        mapping.playerAdapter.gatherSkillBinding!.skill.id,
        mapping.playerAdapter.clearSkillBinding!.skill.id,
      };
      expect(settlement.skillCasts, isNotEmpty);
      expect(
        settlement.skillCasts.every(
          (cast) =>
              equippedIds.contains(cast.skillId) ||
              tacticalIds.contains(cast.skillId),
        ),
        isTrue,
        reason: '内部 hotkey/kind 不得进入熟练度账本，真实 Q/R id 允许记账',
      );
    },
  );
}
