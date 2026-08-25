import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/tower/presentation/phase0a_tower_battle_host.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../support/test_data.dart';
import '../../../support/combatant_snapshot_fixture.dart';

CombatantSnapshot _player(NumbersConfig numbers) => testCombatantSnapshot(
  characterId: 1,
  name: '塔纵切玩家',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.qiMeng,
  school: TechniqueSchool.gangMeng,
  maxHp: 15000,
  currentHp: 15000,
  internalForce: 600,
  maxQi: 100,
  currentQi: 100,
  speed: 100,
  criticalRate: numbers.combat.critical.baseRate,
  evasionRate: 0,
  defenseRate: numbers.defenseRateByTier[RealmTier.xueTu] ?? 0,
  totalEquipmentAttack: 130,
  mainCultivationLayer: CultivationLayer.chuKui,
  includeProductionBasicAttack: true,
  availableSkills: const [],
  openingSkillCooldowns: const {},
  activeBuffs: const [],
);

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  testWidgets('塔 Boss 宿主在 1280×720 / 1440×900 无布局异常', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final viewport in const [Size(1280, 720), Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(viewport);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Phase0aTowerBattleHost(
              floor: repo.getTowerFloor(10),
              participantId: 1,
              playerSnapshotForTest: _player(repo.numbers),
              cycleIndexForTest: 1,
              seedForTest: 20260822,
              onVictory: (_) {},
              onDefeat: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Phase0aBattleScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$viewport');
    }
  });

  testWidgets('塔一层固定 seed → 键鼠战斗回调 0A settlement', (tester) async {
    CombatSettlementSnapshot? victory;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Phase0aTowerBattleHost(
            floor: repo.getTowerFloor(1),
            participantId: 1,
            playerSnapshotForTest: _player(repo.numbers),
            cycleIndexForTest: 1,
            seedForTest: 20260822,
            onVictory: (settlement) => victory = settlement,
            onDefeat: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    var simulatedSeconds = 0;
    while (victory == null && simulatedSeconds < 180) {
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump(const Duration(seconds: 1));
      simulatedSeconds++;
    }

    expect(victory, isNotNull);
    expect(victory!.result, BattleResult.leftWin);
    expect(victory!.totalDamage, greaterThan(0));
    expect(victory!.participantFor(1)!.currentHp, greaterThan(0));
  });

  test('代表塔层同 seed: live controller 与 headless 末态一致', () {
    final numbers = repo.numbers;
    for (final case_ in const [
      (floor: 1, cycle: 1),
      (floor: 5, cycle: 1),
      (floor: 10, cycle: 1),
      (floor: 32, cycle: 1),
      (floor: 32, cycle: 2),
      (floor: 49, cycle: 1),
    ]) {
      final floor = repo.getTowerFloor(case_.floor);
      final seed = 20260822 + case_.floor + case_.cycle;

      Phase0aStageMapping mapping() => Phase0aStageContentMapper.mapTower(
        floor: floor,
        playerSnapshot: _player(numbers),
        numbers: numbers,
        cycleIndex: case_.cycle,
      );

      final headlessMapping = mapping();
      final headless = Phase0aHeadlessRunner.runToEnd(
        flow: Phase0aProductionFlowAssembler.assemble(
          initialState: headlessMapping.initialState,
          waves: headlessMapping.waves,
          combatants: headlessMapping.combatants,
          moveBindings: headlessMapping.moveBindings,
          numbers: numbers,
          rng: Random(seed),
          playerAdapter: headlessMapping.playerAdapter,
          enemyAiAdapter: headlessMapping.enemyAiAdapter,
        ),
        bot: Phase0aPlayerBotAdapter(
          playerAdapter: headlessMapping.playerAdapter,
        ),
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: numbers.phase0aArena.maxSimulationTicks,
      );

      final liveMapping = mapping();
      final controller = Phase0aBattleController(
        flow: Phase0aProductionFlowAssembler.assemble(
          initialState: liveMapping.initialState,
          waves: liveMapping.waves,
          combatants: liveMapping.combatants,
          moveBindings: liveMapping.moveBindings,
          numbers: numbers,
          rng: Random(seed),
          playerAdapter: liveMapping.playerAdapter,
          enemyAiAdapter: liveMapping.enemyAiAdapter,
        ),
        roster: Phase0aVisualRoster.fromMapping(liveMapping),
        fixedDeltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
      );
      final bot = Phase0aPlayerBotAdapter(
        playerAdapter: liveMapping.playerAdapter,
      );
      var ticks = 0;
      while (controller.outcome == Phase0aBattleOutcome.ongoing &&
          ticks < numbers.phase0aArena.maxSimulationTicks) {
        controller.step(bot.commandFor(controller.state));
        ticks++;
      }

      expect(controller.outcome, headless.outcome, reason: '$case_');
      expect(controller.state, headless.finalState, reason: '$case_');
      expect(controller.events, headless.events, reason: '$case_');
      controller.dispose();
    }
  });
}
