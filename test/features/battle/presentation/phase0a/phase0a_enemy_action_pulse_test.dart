import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

void main() {
  late GameRepository repository;

  setUpAll(() async => repository = await loadTestGameRepository());

  setUp(() {
    rootBundle.evict('data/narratives/phase0a_mouse_attack.yaml');
  });

  for (final skill in [false, true]) {
    testWidgets(
      'production enemy ${skill ? 'skill' : 'basic attack'} visibly pulses then returns to idle',
      (tester) async {
        final stageId = skill ? 'stage_01_05' : 'stage_01_04';
        final player = Phase0aStageContentMapper.mapPlayerOnly(
          contentId: stageId,
          // Observation fixture; the player sends no attacks and therefore
          // cannot create a hit reaction on the Boss that masks this check.
          playerSnapshot: testCombatantSnapshot(
            maxHp: 20000,
            currentHp: 20000,
            maxQi: 100,
            currentQi: 100,
            includeProductionBasicAttack: true,
          ),
          numbers: repository.numbers,
        );
        final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
          loader:
              ({
                required String stageId,
                required String encounterId,
                required int cycleIndex,
              }) => buildPhase0aMainlineRuntimeBindingBundleFromRepository(
                stageId: stageId,
                encounterId: encounterId,
                cycleIndex: cycleIndex,
                repository: repository,
              ),
        );
        final host = (await createFreshPhase0aMainlineEncounter(
          Phase0aMainlineEncounterHostBuildRequest(
            stage: repository.getStage(stageId),
            playerMapping: player,
            numbers: repository.numbers,
            cycleIndex: 1,
            rng: Random(20260905),
            runtimeBindingSource: source,
            catalogOverride: repository.combatCatalog,
          ),
        ))!;
        final mapping = host.mapping!;
        final bossId = mapping.combatants
            .singleWhere((input) => input.snapshot.isBoss)
            .actorId;
        final controller = Phase0aBattleController(
          flow: host.flow,
          roster: Phase0aVisualRoster.fromCombatants(
            playerId: mapping.initialState.player.id,
            combatants: mapping.combatants,
            assetPathByActorId: host.visualAssetPathByActorId,
          ),
          fixedDeltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
        );
        addTearDown(controller.dispose);
        await tester.binding.setSurfaceSize(const Size(1280, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: Phase0aBattleScreen(
              controller: controller,
              autoStep: false,
              basicAttackRange: mapping.playerAdapter.attackRange,
            ),
          ),
        );
        await tester.pump();

        bool isExpectedAction(Phase0aEvent event) => skill
            ? event is Phase0aEnemySkillStarted && event.actor == bossId
            : event is Phase0aAttackStarted && event.actor == bossId;
        var observed = false;
        for (var tick = 0; tick < 100; tick++) {
          final events = controller.step();
          if (events.any(isExpectedAction)) {
            observed = true;
            break;
          }
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          observed,
          isTrue,
          reason: 'must receive a real production enemy action',
        );
        await tester.pump();
        final action = find.byKey(ValueKey('phase0a_action_$bossId'));
        final scale = find.byKey(ValueKey('phase0a_actor_scale_$bossId'));
        final slide = find.byKey(ValueKey('phase0a_actor_slide_$bossId'));
        expect(action, findsOneWidget);
        expect(
          tester.widget<AnimatedScale>(scale).scale,
          Phase0aPresentationTokens.actorActionScale,
        );
        expect(tester.widget<AnimatedSlide>(slide).offset, isNot(Offset.zero));
        expect(find.byKey(ValueKey('phase0a_impact_$bossId')), findsNothing);
        expect(
          find.byKey(ValueKey('phase0a_action_${controller.state.player.id}')),
          findsNothing,
        );

        // Advance only presentation time: another simulation attack must not
        // refresh the pulse and hide a timer that never clears.
        final eventTick = controller.state.tick;
        await tester.pump(
          Duration(
            microseconds:
                ((Phase0aPresentationTokens.actorActionPulseSeconds +
                            Phase0aPresentationTokens.actorMotionTweenSeconds) *
                        Duration.microsecondsPerSecond)
                    .ceil(),
          ),
        );
        expect(controller.state.tick, eventTick);
        expect(action, findsNothing);
        expect(tester.widget<AnimatedScale>(scale).scale, 1.0);
        expect(tester.widget<AnimatedSlide>(slide).offset, Offset.zero);
      },
    );
  }
}
