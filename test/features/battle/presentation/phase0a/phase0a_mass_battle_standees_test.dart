import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/debug/application/battle_frame_profile.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';
import 'package:wuxia_idle/features/settings/application/gameplay_settings_provider.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/theme/wuxia_app_theme.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

import '../../../../support/isar_test_support.dart';
import '../../../../support/phase0a_ch1_founder_profile.dart';
import '../../../../support/phase0a_production_headless_benchmark.dart';

const _seed = 20260820;
const _massBattleStageIds = [
  'stage_mass_battle_01',
  'stage_mass_battle_02',
  'stage_mass_battle_03',
  'stage_mass_battle_04',
  'stage_mass_battle_05',
];
const _lightFootStageIds = [
  'stage_light_foot_01',
  'stage_light_foot_02',
  'stage_light_foot_03',
  'stage_light_foot_04',
  'stage_light_foot_05',
];

// Independent, explicit asset expectations: deriving a battle_ filename from
// the same production algorithm would fail to catch a wrong template binding.
const _massBattleStandeeByPortrait = {
  'assets/enemies/massbattle_cunfei_a.png':
      WuxiaUi.battleVillageBanditLeaderStandee,
  'assets/enemies/massbattle_cunfei_b.png':
      WuxiaUi.battleVillageBanditArcherStandee,
  'assets/enemies/massbattle_cunfei_c.png':
      WuxiaUi.battleVillageBanditSaberStandee,
  'assets/enemies/massbattle_zhenkou_a.png':
      WuxiaUi.battleTownBanditLeaderStandee,
  'assets/enemies/massbattle_zhenkou_b.png':
      WuxiaUi.battleTownBanditWandererStandee,
  'assets/enemies/massbattle_zhenkou_c.png':
      WuxiaUi.battleTownBanditAssassinStandee,
  'assets/enemies/massbattle_xianjie_a.png':
      WuxiaUi.battleRivalSectMasterStandee,
  'assets/enemies/massbattle_xianjie_b.png':
      WuxiaUi.battleRivalSectProtectorStandee,
  'assets/enemies/massbattle_xianjie_c.png':
      WuxiaUi.battleRivalSectDiscipleStandee,
  'assets/enemies/massbattle_guanqi_a.png':
      WuxiaUi.battleFrontierCommanderStandee,
  'assets/enemies/massbattle_guanqi_b.png':
      WuxiaUi.battleFrontierOutriderStandee,
  'assets/enemies/massbattle_guanqi_c.png':
      WuxiaUi.battleFrontierIronGuardStandee,
  'assets/enemies/massbattle_canbu_a.png':
      WuxiaUi.battleWesternRemnantGeneralStandee,
  'assets/enemies/massbattle_canbu_b.png':
      WuxiaUi.battleWesternFrenziedRiderStandee,
  'assets/enemies/massbattle_canbu_c.png':
      WuxiaUi.battleWesternRemnantAssassinStandee,
};
const _lightFootStandeeByPortrait = {
  'assets/enemies/lightfoot_shuikou_a.png': WuxiaUi.battleFerryBanditStandee,
  'assets/enemies/lightfoot_shuikou_b.png': WuxiaUi.battleFerryBoatmanStandee,
  'assets/enemies/lightfoot_shuikou_c.png': WuxiaUi.battleFerrySaberStandee,
  'assets/enemies/lightfoot_yexun_a.png': WuxiaUi.battleNightPatrolStandee,
  'assets/enemies/lightfoot_yexun_b.png': WuxiaUi.battleRooftopConstableStandee,
  'assets/enemies/lightfoot_yexun_c.png': WuxiaUi.battleRooftopAssassinStandee,
  'assets/enemies/lightfoot_zhuke_a.png':
      WuxiaUi.battleJiangnanSwordsmanStandee,
  'assets/enemies/lightfoot_zhuke_b.png': WuxiaUi.battleBambooSaberStandee,
  'assets/enemies/lightfoot_zhuke_c.png': WuxiaUi.battleBambooWandererStandee,
  'assets/enemies/lightfoot_pubu_a.png':
      WuxiaUi.battleMountainStreamSwordStandee,
  'assets/enemies/lightfoot_pubu_b.png': WuxiaUi.battleWaterfallSaberStandee,
  'assets/enemies/lightfoot_pubu_c.png': WuxiaUi.battleCliffWandererStandee,
  'assets/enemies/lightfoot_changfeng_a.png':
      WuxiaUi.battleGateCommanderStandee,
  'assets/enemies/lightfoot_changfeng_b.png':
      WuxiaUi.battleLongWindSwordStandee,
  'assets/enemies/lightfoot_changfeng_c.png':
      WuxiaUi.battleLongRoadSaberStandee,
};

/// Observe the independently assembled production flow without replacing any
/// reducer, command, RNG, event ordering or terminal rule.
final class _RecordedFlow implements Phase0aBattleFlow {
  _RecordedFlow(this.delegate) : states = [delegate.state];
  final Phase0aBattleFlow delegate;
  final List<Phase0aArenaState> states;
  final List<List<Phase0aEvent>> eventsByTick = [];
  final List<List<CombatEventRecord>> recordsByTick = [];
  @override
  Phase0aArenaState get state => delegate.state;
  @override
  Phase0aBattleOutcome get outcome => delegate.outcome;
  @override
  List<CombatEventRecord> get lastOrderedEventRecords =>
      delegate.lastOrderedEventRecords;
  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    final events = delegate.advance(
      deltaSeconds: deltaSeconds,
      command: command,
    );
    states.add(delegate.state);
    eventsByTick.add(List.unmodifiable(events));
    recordsByTick.add(List.unmodifiable(delegate.lastOrderedEventRecords));
    return events;
  }
}

String _assetName(ImageProvider provider) {
  if (provider is ResizeImage) return _assetName(provider.imageProvider);
  expect(provider, isA<AssetImage>());
  return (provider as AssetImage).assetName;
}

void main() {
  late GameRepository repository;
  late Directory directory;
  late CombatantSnapshot player;
  setUpAll(() async {
    final font = Platform.environment['WUXIA_STANDEE_VISUAL_FONT'];
    if (font != null) {
      final bytes = ByteData.sublistView(await File(font).readAsBytes());
      for (final family in ['Roboto', 'Ahem', 'sans-serif']) {
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
    }
    await initializeTestIsarCore();
    repository = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    directory = await Directory.systemTemp.createTemp('mass_standee_host_');
    await IsarSetup.init(directory: directory, inspector: false);
    player = (await seedPhase0aCh1FounderProfile(
      isar: IsarSetup.instance,
      schoolId: 'gang_meng',
      originId: 'mountain_wanderer',
      fateId: 'balanced_seed',
      rngSeed: _seed,
    )).snapshot;
  });
  setUp(() {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
    BattleFrameProfileProbe.configureFromArgs([]);
  });
  tearDownAll(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  test(
    'all five mass battle rosters retain every template in all formations',
    () {
      final seenPortraits = <String>{};
      var checkedEnemies = 0;
      for (final stageId in _massBattleStageIds) {
        final stage = repository.getStage(stageId);
        for (final formation in Formation.values) {
          final mapping = Phase0aStageContentMapper.mapMassBattle(
            stage: stage,
            playerSnapshot: player,
            numbers: repository.numbers,
            formation: formation,
            cycleIndex: 1,
          );
          final roster = Phase0aVisualRoster.fromMassBattleMapping(mapping);
          final playerId = mapping.initialState.player.id;
          expect(
            roster.visualFor(playerId).assetPath,
            WuxiaUi.battleFounderFallback,
          );
          final enemies = mapping.combatants
              .where((combatant) => combatant.actorId != playerId)
              .toList();
          expect(
            enemies,
            hasLength(
              stage.massBattleEnemyCounts!.reduce(
                (count, waveCount) => count + waveCount,
              ),
            ),
          );
          for (final combatant in enemies) {
            final portrait = combatant.snapshot.iconPath!;
            seenPortraits.add(portrait);
            final expected = _massBattleStandeeByPortrait[portrait];
            expect(expected, isNotNull, reason: 'Unmapped $portrait');
            final visual = roster.visualFor(combatant.actorId);
            expect(
              visual.assetPath,
              expected,
              reason: '$stageId ${formation.name} ${combatant.actorId}',
            );
            expect(visual.name, combatant.snapshot.name);
            expect(visual.isElite, combatant.snapshot.isBoss);
            checkedEnemies++;
          }
        }
      }
      expect(seenPortraits, _massBattleStandeeByPortrait.keys.toSet());
      expect(seenPortraits, hasLength(15));
      expect(checkedEnemies, 288);
      debugPrint(
        jsonEncode({
          'mass_battle_standee_static': 'five_stages_all_formations',
          'stages': _massBattleStageIds.length,
          'formations': Formation.values
              .map((formation) => formation.name)
              .toList(),
          'enemy_instances': checkedEnemies,
          'templates': seenPortraits.length,
        }),
      );
    },
  );

  test(
    'all five light foot rosters retain every template and terrain mapping',
    () {
      final seenPortraits = <String>{};
      final seenTerrains = <String>{};
      var checkedEnemies = 0;
      for (final stageId in _lightFootStageIds) {
        final stage = repository.getStage(stageId);
        final mapping = Phase0aStageContentMapper.mapLightFoot(
          stage: stage,
          playerSnapshot: player,
          numbers: repository.numbers,
          cycleIndex: 1,
        );
        seenTerrains.add(stage.terrainBiome!.name);
        final beforeState = mapping.initialState;
        final beforeSnapshots = [
          for (final combatant in mapping.combatants) combatant.snapshot,
        ];
        final roster = Phase0aVisualRoster.fromLightFootMapping(mapping);
        expect(mapping.initialState, beforeState);
        expect([
          for (final combatant in mapping.combatants) combatant.snapshot,
        ], beforeSnapshots);
        expect(
          roster.visualFor(mapping.initialState.player.id).assetPath,
          WuxiaUi.battleFounderFallback,
        );
        final enemies = mapping.combatants.where(
          (combatant) => combatant.actorId != mapping.initialState.player.id,
        );
        expect(enemies, hasLength(stage.enemyTeam.length));
        for (final combatant in enemies) {
          final portrait = combatant.snapshot.iconPath!;
          seenPortraits.add(portrait);
          final expected = _lightFootStandeeByPortrait[portrait];
          expect(expected, isNotNull, reason: 'Unmapped $portrait');
          final visual = roster.visualFor(combatant.actorId);
          expect(
            visual.assetPath,
            expected,
            reason: '$stageId ${combatant.actorId}',
          );
          expect(visual.name, combatant.snapshot.name);
          expect(visual.isElite, combatant.snapshot.isBoss);
          checkedEnemies++;
        }
      }
      expect(seenPortraits, _lightFootStandeeByPortrait.keys.toSet());
      expect(seenPortraits, hasLength(15));
      expect(checkedEnemies, 15);
      expect(seenTerrains, {'water', 'rooftop', 'bamboo'});
      debugPrint(
        jsonEncode({
          'light_foot_standee_static': 'five_stages_all_templates',
          'stages': _lightFootStageIds.length,
          'enemy_instances': checkedEnemies,
          'templates': seenPortraits.length,
          'terrain_biomes': seenTerrains.toList()..sort(),
        }),
      );
    },
  );

  for (final stageId in [..._massBattleStageIds, ..._lightFootStageIds]) {
    for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
      final viewport = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$stageId $viewport binds full standees and preserves '
          'the complete production headless terminal', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final stage = repository.getStage(stageId);
        final isMassBattle = stage.stageType == StageType.massBattle;
        final standeeByPortrait = isMassBattle
            ? _massBattleStandeeByPortrait
            : _lightFootStandeeByPortrait;
        if (!isMassBattle) {
          expect(stage.stageType, StageType.lightFoot);
          expect(stage.terrainBiome, isNotNull);
          expect(
            repository.numbers.lightFoot.terrainModifiers[stage.terrainBiome],
            isNotNull,
          );
        }
        final reference = (await tester.runAsync(
          () => createProductionHeadlessSession(
            repository: repository,
            content: isMassBattle
                ? HeadlessBenchmarkContent.massBattle(
                    stageId,
                    formation: Formation.yanXing,
                  )
                : HeadlessBenchmarkContent.lightFoot(stageId),
            player: player,
            seed: _seed,
          ),
        ))!;
        final recorded = _RecordedFlow(reference.flow);
        final headless = Phase0aHeadlessRunner.runToEnd(
          flow: recorded,
          bot: reference.bot,
          deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
          maxTicks: repository.numbers.phase0aArena.maxSimulationTicks,
        );
        expect(headless.timedOut, isFalse);
        expect(headless.events, isNotEmpty);
        final expectedSettlement = headlessSettlementFacts(
          reference.settle(
            outcome: headless.outcome,
            finalState: headless.finalState,
            events: headless.events,
          ),
        );
        final scope = ProviderContainer();
        await scope.read(gameplaySettingsProvider.future);
        final capture = GlobalKey();
        CombatSettlementSnapshot? terminal;
        var terminalCalls = 0;
        void complete(CombatSettlementSnapshot value) {
          terminal = value;
          terminalCalls++;
        }

        try {
          // Direct Host mounting is UI coordination, not an unlock or entry
          // grant. The Host reads the legal founder from isolated test Isar.
          await tester.runAsync(() async {
            await tester.pumpWidget(
              RepaintBoundary(
                key: capture,
                child: UncontrolledProviderScope(
                  container: scope,
                  child: MaterialApp(
                    theme: wuxiaAppTheme(),
                    home: Phase0aMainlineBattleHost(
                      stage: stage,
                      seedForTest: _seed,
                      controller: ActivityController.playerBot,
                      massBattleFormation: isMassBattle
                          ? Formation.yanXing
                          : null,
                      onVictory: complete,
                      onDefeat: complete,
                    ),
                  ),
                ),
              ),
            );
            for (
              var attempt = 0;
              attempt < 100 &&
                  find.byType(Phase0aBattleScreen).evaluate().isEmpty;
              attempt++
            ) {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              await tester.pump();
            }
          });
          final finder = find.byType(Phase0aBattleScreen);
          expect(finder, findsOneWidget);
          final screen = tester.widget<Phase0aBattleScreen>(finder);
          final controller = screen.controller;
          expect(controller.state, recorded.states.first);
          expect(controller.state.tick, 0);
          expect(screen.showBackgroundCrowds, isMassBattle);
          expect(
            find.byKey(const ValueKey('phase0a_background_crowds')),
            isMassBattle ? findsOneWidget : findsNothing,
          );
          final expectedAssets = <String, String>{};
          final enemyPortraits = <String>{};
          for (final combatant in reference.combatants) {
            final isPlayer = combatant.actorId == controller.state.player.id;
            final portrait = combatant.snapshot.iconPath;
            if (!isPlayer) enemyPortraits.add(portrait!);
            final expected = isPlayer
                ? WuxiaUi.battleFounderFallback
                : standeeByPortrait[portrait];
            expect(expected, isNotNull, reason: 'Unmapped $portrait');
            expectedAssets[combatant.actorId] = expected!;
            final visual = controller.roster.visualFor(combatant.actorId);
            expect(
              visual.assetPath,
              expected,
              reason: '$stageId full roster actor ${combatant.actorId}',
            );
            expect(visual.name, combatant.snapshot.name);
            expect(visual.isElite, combatant.snapshot.isBoss);
          }
          expect(
            enemyPortraits,
            stage.enemyTeam.map((enemy) => enemy.iconPath).toSet(),
          );
          expect(enemyPortraits, hasLength(3));
          final enemyCount = isMassBattle
              ? stage.massBattleEnemyCounts!.reduce((a, b) => a + b)
              : stage.enemyTeam.length;
          expect(reference.combatants, hasLength(enemyCount + 1));
          expect(
            enemyCount,
            isMassBattle
                ? greaterThan(controller.state.enemies.length)
                : controller.state.enemies.length,
          );

          final residentImageActorIds = <String>{};
          final nonOffstageImageActorIds = <String>{};
          void checkScreenImages() {
            expect(
              tester.widget<Phase0aBattleScreen>(finder).controller,
              same(controller),
            );
            for (final actor in [
              controller.state.player,
              ...controller.state.enemies,
            ]) {
              final visual = find.byKey(
                ValueKey('phase0a_actor_visual_${actor.id}'),
                skipOffstage: false,
              );
              expect(visual, findsOneWidget);
              final images = find.descendant(
                of: visual,
                matching: find.byType(Image, skipOffstage: false),
                skipOffstage: false,
              );
              expect(images, findsOneWidget);
              expect(
                _assetName(tester.widget<Image>(images).image),
                expectedAssets[actor.id],
                reason: '${actor.id} actual Image',
              );
              residentImageActorIds.add(actor.id);
              if (find
                  .byKey(ValueKey('phase0a_actor_visual_${actor.id}'))
                  .evaluate()
                  .isNotEmpty) {
                nonOffstageImageActorIds.add(actor.id);
              }
            }
          }

          checkScreenImages();
          await _captureViewport(tester, capture, '$stageId-$viewport');
          expect(controller.state, recorded.states.first);
          final rawRecords = <CombatEventRecord>[];
          for (var tick = 0; tick < headless.ticks; tick++) {
            final emitted = controller.step(
              screen.botCommandBuilder!(controller.state),
            );
            expect(
              controller.state,
              recorded.states[tick + 1],
              reason: '$stageId complete state tick ${tick + 1}',
            );
            expect(
              emitted,
              recorded.eventsByTick[tick],
              reason: '$stageId full events tick ${tick + 1}',
            );
            expect(
              controller.lastEventRecords,
              recorded.recordsByTick[tick],
              reason: '$stageId raw records tick ${tick + 1}',
            );
            rawRecords.addAll(controller.lastEventRecords);
            await tester.pump();
            checkScreenImages();
          }
          expect(controller.outcome, headless.outcome);
          expect(controller.events, headless.events);
          expect(rawRecords, headless.eventRecords);
          expect(terminalCalls, 1);
          expect(headlessSettlementFacts(terminal!), expectedSettlement);
          expect(controller.step(), isEmpty);
          expect(controller.state, headless.finalState);
          expect(terminalCalls, 1);
          expect(tester.takeException(), isNull);
          debugPrint(
            jsonEncode({
              (isMassBattle
                      ? 'mass_battle_standee_host'
                      : 'light_foot_standee_host'):
                  stageId,
              'seed': _seed,
              'formation': isMassBattle ? Formation.yanXing.name : null,
              'terrain_biome': stage.terrainBiome?.name,
              if (!isMassBattle)
                'terrain_adjusted_combatants': {
                  for (final combatant in reference.combatants)
                    combatant.actorId: {
                      'critical_rate': combatant.snapshot.criticalRate,
                      'evasion_rate': combatant.snapshot.evasionRate,
                      'defense_rate': combatant.snapshot.defenseRate,
                      'attack_power_multiplier':
                          combatant.snapshot.attackPowerMultiplier,
                    },
                },
              'viewport': viewport,
              'roster_enemy_count': enemyCount,
              'portrait_templates': enemyPortraits.toList()..sort(),
              'standee_assets': expectedAssets,
              'configured_wave_counts': stage.massBattleEnemyCounts,
              'wave_started_events': [
                for (final event
                    in controller.events.whereType<Phase0aWaveStarted>())
                  {'tick': event.tick, 'wave': event.waveIndex},
              ],
              'wave_cleared_events': [
                for (final event
                    in controller.events.whereType<Phase0aWaveCleared>())
                  {'tick': event.tick, 'wave': event.waveIndex},
              ],
              'resident_image_actor_ids': residentImageActorIds.toList()
                ..sort(),
              'non_offstage_image_actor_ids': nonOffstageImageActorIds.toList()
                ..sort(),
              'ticks': headless.ticks,
              'events': headless.events.length,
              'raw_records': headless.eventRecords.length,
              'outcome': headless.outcome.name,
              'settlement': expectedSettlement,
            }),
          );
        } finally {
          await tester.runAsync(
            () => tester.pumpWidget(const SizedBox.shrink()),
          );
          scope.dispose();
        }
      });
    }
  }
}

Future<void> _captureViewport(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final directory = Platform.environment['WUXIA_STANDEE_VISUAL_OUTPUT'];
  if (directory == null) return;
  final context = key.currentContext!;
  // Resolve the actual rendered providers before the optional visual artifact.
  // This only waits for image IO: no combat clock or frame duration advances.
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      Object? imageError;
      await precacheImage(
        image.image,
        context,
        onError: (error, _) => imageError = error,
      );
      expect(imageError, isNull);
    }
    await tester.pump();
    final boundary = context.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$directory/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
