import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_checkpoint_guidance.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  late Phase0aCheckpointGuidanceCopy copy;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    if (Platform.environment['WUXIA_CAPTURE_DIR'] != null && Platform.isMacOS) {
      final font = await File(
        '/System/Library/Fonts/STHeiti Medium.ttc',
      ).readAsBytes();
      await (FontLoader(
        'PlaytestCapture',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
    copy = Phase0aCheckpointGuidanceCopy.fromNarrative(
      await NarrativeLoader.load(
        'stage_01_01_exit_guidance',
        loader: loadTestAsset,
      ),
    )!;
  });

  testWidgets('production clear road needs a visible exit, not a silent timer', (
    tester,
  ) async {
    // A mechanical fixture tests objective wiring, not opening difficulty.
    final mapping = Phase0aStageContentMapper.mapPlayerOnly(
      contentId: 'stage_01_01',
      playerSnapshot: testCombatantSnapshot(
        maxHp: 20000,
        currentHp: 20000,
        internalForce: 15000,
        maxQi: 15000,
        currentQi: 15000,
        defenseRate: repository.numbers.cycleEvolution.defenseRateCap,
        totalEquipmentAttack: 2000,
        includeProductionBasicAttack: true,
      ),
      numbers: repository.numbers,
    );
    final host = (await createFreshPhase0aMainlineEncounter(
      Phase0aMainlineEncounterHostBuildRequest(
        stage: repository.getStage('stage_01_01'),
        playerMapping: mapping,
        numbers: repository.numbers,
        cycleIndex: 1,
        rng: Random(20260905),
        catalogOverride: repository.combatCatalog,
        runtimeBindingSource:
            Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
              loader:
                  ({
                    required stageId,
                    required encounterId,
                    required cycleIndex,
                  }) async =>
                      buildPhase0aMainlineRuntimeBindingBundleFromRepository(
                        stageId: stageId,
                        encounterId: encounterId,
                        cycleIndex: cycleIndex,
                        repository: repository,
                      ),
            ),
      ),
    ))!;
    final controller = Phase0aBattleController(
      flow: host.flow,
      roster: Phase0aVisualRoster.fromCombatants(
        playerId: host.flow.state.player.id,
        combatants: host.mapping!.combatants,
        assetPathByActorId: host.visualAssetPathByActorId,
      ),
      fixedDeltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
    );
    addTearDown(controller.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    expect(controller.checkpointObjectiveProgress!.remainingEnemies, 25);
    expect(controller.checkpointObjectiveProgress!.reached, isFalse);
    expect(host.checkpointXById.values.single, 520);

    for (
      var tick = 0;
      tick < repository.numbers.phase0aArena.maxSimulationTicks;
      tick++
    ) {
      if (controller.checkpointObjectiveProgress!.remainingEnemies == 0) break;
      final targets =
          controller.state.enemies.where((enemy) => enemy.isAlive).toList()
            ..sort(
              (a, b) => (a.position - controller.state.player.position)
                  .lengthSquared
                  .compareTo(
                    (b.position - controller.state.player.position)
                        .lengthSquared,
                  ),
            );
      controller.step(
        Phase0aPlayerCommand(
          attack: true,
          clear: true,
          attackAimDirection: targets.isEmpty
              ? null
              : targets.first.position - controller.state.player.position,
        ),
      );
      if (controller.outcome != Phase0aBattleOutcome.ongoing) break;
    }
    expect(controller.checkpointObjectiveProgress!.remainingEnemies, 0);
    expect(controller.outcome, Phase0aBattleOutcome.ongoing);
    final clearedTick = controller.state.tick;
    for (var tick = 0; tick < 200; tick++) {
      controller.step();
    }
    expect(controller.state.tick, clearedTick + 200);
    expect(
      controller.outcome,
      Phase0aBattleOutcome.ongoing,
      reason: 'Waiting 20 seconds does not substitute for reaching the exit',
    );

    for (final viewport in const [Size(1280, 720), Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(viewport);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: Platform.environment['WUXIA_CAPTURE_DIR'] == null
                  ? null
                  : 'PlaytestCapture',
            ),
            home: Phase0aBattleScreen(
              controller: controller,
              autoStep: false,
              checkpointXById: host.checkpointXById,
              checkpointGuidanceCopy: copy,
              numericSkillBindings: mapping.playerAdapter.numericSkillBindings,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(copy.roadCleared), findsOneWidget);
      expect(
        find.byKey(const ValueKey('phase0a_checkpoint_exit_marker')),
        findsOneWidget,
      );
      final banner = tester.getRect(
        find.byKey(const ValueKey('phase0a_checkpoint_condition_banner')),
      );
      expect(banner.left, greaterThanOrEqualTo(0));
      expect(banner.right, lessThanOrEqualTo(viewport.width));

      // Shared production movement reaches the bottom but stays above the HUD.
      for (var tick = 0; tick < 100; tick++) {
        controller.step(const Phase0aPlayerCommand(down: true));
      }
      await tester.pump(const Duration(milliseconds: 200));
      final player = tester.getRect(
        find.byKey(const ValueKey('phase0a_actor_player')),
      );
      final hud = tester.getRect(
        find.byKey(const ValueKey('phase0a_player_hud')),
      );
      expect(player.bottom, lessThan(hud.top), reason: '$viewport');
      expect(tester.takeException(), isNull);
      final captureDir = Platform.environment['WUXIA_CAPTURE_DIR'];
      if (captureDir != null) {
        final providers = tester
            .widgetList<Image>(find.byType(Image))
            .map((widget) => widget.image)
            .toList();
        await tester.runAsync(() async {
          await Future.wait(
            providers.map(
              (provider) =>
                  precacheImage(provider, boundaryKey.currentContext!),
            ),
          );
        });
        await tester.pump();
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '$captureDir/first-stage-exit-${viewport.width.toInt()}x${viewport.height.toInt()}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
    for (
      var tick = 0;
      tick < 100 && controller.outcome == Phase0aBattleOutcome.ongoing;
      tick++
    ) {
      controller.step(const Phase0aPlayerCommand(right: true));
    }
    expect(controller.checkpointObjectiveProgress!.reached, isTrue);
    expect(controller.outcome, Phase0aBattleOutcome.victory);
    expect(
      host
          .settle(
            outcome: controller.outcome,
            finalState: controller.state,
            events: controller.events,
          )
          .canAdmitNextStage,
      isTrue,
    );
  });
}
