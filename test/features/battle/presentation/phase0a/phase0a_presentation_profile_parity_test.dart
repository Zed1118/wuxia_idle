import 'dart:async';
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
import 'package:wuxia_idle/data/defs/boss_gauntlet_config.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_event_order.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/phase0a_gauntlet_battle_host.dart';
import 'package:wuxia_idle/features/debug/application/battle_frame_profile.dart';
import 'package:wuxia_idle/features/debug/application/production_battle_frame_profile.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_providers.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';
import 'package:wuxia_idle/features/expedition/presentation/phase0a_expedition_milestone_battle_host.dart';
import 'package:wuxia_idle/features/settings/application/gameplay_settings_provider.dart';
import 'package:wuxia_idle/features/settings/application/gameplay_settings_service.dart';
import 'package:wuxia_idle/features/settings/domain/gameplay_settings.dart';
import 'package:wuxia_idle/features/tower/presentation/phase0a_tower_battle_host.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/utils/math_random.dart';
import 'package:wuxia_idle/shared/theme/wuxia_app_theme.dart';

import '../../../../support/isar_test_support.dart';
import '../../../../support/phase0a_ch1_founder_profile.dart';
import '../../../../support/phase0a_production_headless_benchmark.dart';

const _seed = 20260820;
const _settings = [
  GameplaySettings(),
  GameplaySettings(showBackgroundCrowds: false),
  GameplaySettings(reduceEffects: true),
  GameplaySettings(reduceEffects: true, showBackgroundCrowds: false),
  GameplaySettings(reduceFlashing: true),
  GameplaySettings(reduceFlashing: true, showBackgroundCrowds: false),
  GameplaySettings(reduceEffects: true, reduceFlashing: true),
  GameplaySettings(
    reduceEffects: true,
    reduceFlashing: true,
    showBackgroundCrowds: false,
  ),
];
const _crowdLayerKey = ValueKey('phase0a_background_crowds');

/// A read-only observer around the independent production headless flow. No
/// copied reducer, event normalization, rounded state or fabricated terminal.
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
    final emitted = delegate.advance(
      deltaSeconds: deltaSeconds,
      command: command,
    );
    states.add(delegate.state);
    eventsByTick.add(List.unmodifiable(emitted));
    recordsByTick.add(List.unmodifiable(delegate.lastOrderedEventRecords));
    return emitted;
  }
}

/// Only the admission/transaction seam is a fixture. The host still assembles
/// the real configured enemies, founder snapshot, RNG, flow and settlement.
/// This does not grant a ticket, edit a run, or claim gauntlet entry was legal.
class _GauntletPlanFixture extends GauntletService {
  _GauntletPlanFixture(this.plan) : super(IsarSetup.instance);
  final Phase0aGauntletStagePlan plan;
  @override
  Future<Phase0aGauntletStagePlan> preparePhase0aStage({
    required BossGauntletConfig config,
  }) async => plan;
}

/// The first-milestone plan and final transaction observer are UI coordination
/// fixtures, not a forged pending milestone or a persisted manual clear.
class _MilestonePlanFixture extends ExpeditionService {
  _MilestonePlanFixture(this.plan, this.onSettlement)
    : super(IsarSetup.instance);
  final ExpeditionManualMilestonePlan plan;
  final ValueChanged<CombatSettlementSnapshot> onSettlement;
  @override
  Future<ExpeditionManualMilestonePlan> prepareManualMilestone({
    required ActivityParticipationRequest request,
  }) async {
    expect(request.contentId, '${plan.routeId}:${plan.milestoneId}');
    expect(request.characterId, plan.playerSnapshot.characterId);
    return plan;
  }

  @override
  Future<bool> completeManualMilestone({
    required ExpeditionManualMilestonePlan plan,
    required CombatSettlementSnapshot settlement,
    DateTime? now,
    Future<void> Function()? afterRewardsInTxnForTest,
  }) async {
    expect(identical(plan, this.plan), isTrue);
    onSettlement(settlement);
    return false; // Observed only: no reward, record, unlock or save write.
  }
}

/// Delays real SharedPreferences reads; the returned values are still loaded
/// by GameplaySettingsService rather than an injected AsyncData shortcut.
class _DelayedSettingsService extends GameplaySettingsService {
  final loads = <Completer<void>>[];
  @override
  Future<GameplaySettings> load() async {
    final gate = Completer<void>();
    loads.add(gate);
    await gate.future;
    return super.load();
  }
}

enum _Route {
  mainline('stage_01_01', 'typed_encounter'),
  lightFoot('stage_light_foot_01', 'legacy_waves'),
  massBattle('stage_mass_battle_01', 'legacy_waves'),
  towerTyped('tower_1', 'typed_encounter'),
  towerLegacy('tower_8', 'legacy_waves'),
  gauntlet('gauntlet_1', 'legacy_waves'),
  milestone('baicao_expedition:baicao_elite_fog_pass', 'legacy_waves');

  const _Route(this.contentId, this.runtimeKind);
  final String contentId;
  final String runtimeKind;

  HeadlessBenchmarkContent? get benchmarkContent => switch (this) {
    mainline => HeadlessBenchmarkContent.mainline(contentId),
    lightFoot => HeadlessBenchmarkContent.lightFoot(contentId),
    massBattle => HeadlessBenchmarkContent.massBattle(
      contentId,
      formation: Formation.yanXing,
    ),
    towerTyped || towerLegacy => HeadlessBenchmarkContent.tower(contentId),
    gauntlet || milestone => null,
  };
}

Future<ProductionHeadlessSession> _headlessSession({
  required _Route route,
  required GameRepository repository,
  required CombatantSnapshot player,
}) async {
  final content = route.benchmarkContent;
  if (content != null) {
    return createProductionHeadlessSession(
      repository: repository,
      content: content,
      player: player,
      seed: _seed,
    );
  }
  final config = repository.bossGauntletConfig!;
  final mapping = Phase0aStageContentMapper.mapExpedition(
    contentId: route.contentId,
    enemyTeam: route == _Route.gauntlet
        ? config.enemiesForTeam(config.stages.first.enemyTeamId)
        : repository.expeditionConfig!.enemiesForNode(
            nodeIndex: 5,
            nodeSeed: _seed,
            elite: true,
          ),
    playerSnapshot: player,
    numbers: repository.numbers,
    cycleIndex: 1,
  );
  final flow = Phase0aProductionFlowAssembler.assemble(
    initialState: mapping.initialState,
    waves: mapping.waves,
    combatants: mapping.combatants,
    moveBindings: mapping.moveBindings,
    numbers: repository.numbers,
    rng: newMathRandom(seed: _seed),
    playerAdapter: mapping.playerAdapter,
    enemyAiAdapter: mapping.enemyAiAdapter,
  );
  return ProductionHeadlessSession(
    route.runtimeKind,
    flow,
    Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
    ({required outcome, required finalState, required events}) =>
        Phase0aSettlementAdapter.fromMapping(
          mapping: mapping,
          outcome: outcome,
          finalState: finalState,
          events: events,
        ),
    mapping.combatants,
  );
}

Widget _profileHost({
  required _Route route,
  required GameRepository repository,
  required CombatantSnapshot player,
  required ValueChanged<CombatSettlementSnapshot> complete,
  required VoidCallback milestoneCompleted,
}) {
  final milestonePlan = ExpeditionManualMilestonePlan(
    recordKey: 'ui-only-unpersisted-plan',
    routeId: ExpeditionService.contentId,
    milestoneId: repository.expeditionConfig!
        .teamForNode(nodeSeed: _seed, elite: true)
        .id,
    nodeIndex: 5,
    nodeSeed: _seed,
    cycleIndex: 1,
    member: ActivityMemberSnapshot()..characterId = player.characterId,
    playerSnapshot: player,
  );
  final gauntletConfig = repository.bossGauntletConfig!;
  return switch (route) {
    _Route.mainline ||
    _Route.lightFoot ||
    _Route.massBattle => Phase0aMainlineBattleHost(
      stage: repository.getStage(route.contentId),
      seedForTest: _seed,
      controller: ActivityController.playerBot,
      massBattleFormation: route == _Route.massBattle
          ? Formation.yanXing
          : null,
      onVictory: complete,
      onDefeat: complete,
    ),
    _Route.towerTyped || _Route.towerLegacy => Phase0aTowerBattleHost(
      floor: repository.getTowerFloor(route == _Route.towerTyped ? 1 : 8),
      participantId: player.characterId,
      cycleIndexForTest: 1,
      seedForTest: _seed,
      onVictory: complete,
      onDefeat: complete,
    ),
    _Route.gauntlet => ProviderScope(
      overrides: [
        gauntletServiceProvider.overrideWithValue(
          _GauntletPlanFixture((
            playerSnapshot: player,
            enemyDefs: gauntletConfig.enemiesForTeam(
              gauntletConfig.stages.first.enemyTeamId,
            ),
            seed: _seed,
            isBoss: gauntletConfig.stages.first.role == 'boss',
            cycleIndex: 1,
            stage: 1,
          )),
        ),
      ],
      child: Phase0aGauntletBattleHost(
        config: gauntletConfig,
        onCompleted: (value) => complete(value.settlement.combatSettlement),
      ),
    ),
    _Route.milestone => ProviderScope(
      overrides: [
        expeditionServiceProvider.overrideWithValue(
          _MilestonePlanFixture(milestonePlan, complete),
        ),
      ],
      child: Phase0aExpeditionMilestoneBattleHost(
        request: ExpeditionService.manualMilestoneRequestFor(
          milestoneId: milestonePlan.milestoneId,
          characterId: player.characterId,
        ),
        onCompleted: (completed) {
          expect(completed, isFalse);
          milestoneCompleted();
        },
      ),
    ),
  };
}

void main() {
  late GameRepository repository;
  late Directory directory;
  late CombatantSnapshot player;

  setUpAll(() async {
    final visualFont = Platform.environment['WUXIA_CROWD_VISUAL_FONT'];
    if (visualFont != null) {
      final bytes = ByteData.sublistView(await File(visualFont).readAsBytes());
      for (final family in ['Roboto', 'Ahem', 'sans-serif']) {
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
    }
    await initializeTestIsarCore();
    repository = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    directory = await Directory.systemTemp.createTemp('effects_host_parity_');
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
    // Failed asset futures are scoped to the originating test zone. Do not
    // reuse a cached missing flat-path lookup in the next widget test.
    rootBundle.clear();
    BattleFrameProfileProbe.configureFromArgs([]);
  });
  tearDownAll(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  for (final route in _Route.values) {
    testWidgets(
      '${route.name} initial settings wait and refresh retain the same battle',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final service = _DelayedSettingsService();
        const initial = GameplaySettings(reduceEffects: true);
        const updated = GameplaySettings(reduceFlashing: true);
        await service.save(initial);
        final scope = ProviderContainer(
          overrides: [
            gameplaySettingsServiceProvider.overrideWithValue(service),
          ],
        );
        final output = '${directory.path}/delayed-settings-${route.name}';
        BattleFrameProfileProbe.configureFromArgs([
          '--battle-profile-scope=production',
          '--battle-profile-content-id=${route.contentId}',
          '--battle-profile-run-id=delayed-settings-${route.name}',
          '--battle-profile-output=$output',
          '--battle-profile-sample-seconds=60',
          '--battle-profile-viewport=1280x720',
        ]);
        BattleFrameProfileProbe.recordEntryOrigin(visual: false);
        addTearDown(() => BattleFrameProfileProbe.configureFromArgs([]));
        try {
          await tester.runAsync(() async {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: scope,
                child: MaterialApp(
                  home: _profileHost(
                    route: route,
                    repository: repository,
                    player: player,
                    complete: (_) =>
                        fail('Battle must not advance while settings load'),
                    milestoneCompleted: () =>
                        fail('Battle must not complete while settings load'),
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
          expect(service.loads, hasLength(1));
          expect(scope.read(gameplaySettingsProvider).isLoading, isTrue);
          expect(find.byType(Phase0aBattleScreen), findsNothing);
          expect(find.byType(ProductionBattleFrameProfile), findsNothing);
          // Time really advances in the widget binding while preference I/O is
          // pending. No ticker, domain step, or capture may begin in this window.
          await tester.pump(const Duration(seconds: 2));
          expect(find.byType(Phase0aBattleScreen), findsNothing);
          expect(find.byType(ProductionBattleFrameProfile), findsNothing);

          await tester.runAsync(() async {
            service.loads.single.complete();
            await scope.read(gameplaySettingsProvider.future);
            await Future<void>.delayed(Duration.zero);
            await tester.pump();
          });
          var screen = tester.widget<Phase0aBattleScreen>(
            find.byType(Phase0aBattleScreen),
          );
          final controller = screen.controller;
          final initialState = controller.state;
          expect(controller.state.tick, 0);
          expect(screen.reduceEffects, initial.reduceEffects);
          expect(screen.reduceFlashing, initial.reduceFlashing);
          expect(screen.showBackgroundCrowds, route == _Route.massBattle);
          expect(find.byType(ProductionBattleFrameProfile), findsOneWidget);
          expect(controller.events, isEmpty);
          final initialProbe = tester.widget<ProductionBattleFrameProfile>(
            find.byType(ProductionBattleFrameProfile),
          );
          expect(
            initialProbe.scene['configuration'],
            containsPair('reduce_effects', initial.reduceEffects),
          );
          expect(
            initialProbe.scene['configuration'],
            containsPair('reduce_flashing', initial.reduceFlashing),
          );

          await tester.runAsync(() async {
            await service.save(updated);
            scope.invalidate(gameplaySettingsProvider);
            await tester.pump();
            await Future<void>.delayed(Duration.zero);
            await tester.pump();
          });
          expect(service.loads, hasLength(2));
          expect(scope.read(gameplaySettingsProvider).isLoading, isTrue);
          screen = tester.widget<Phase0aBattleScreen>(
            find.byType(Phase0aBattleScreen),
          );
          expect(screen.controller, same(controller));
          expect(screen.reduceEffects, initial.reduceEffects);
          expect(screen.reduceFlashing, initial.reduceFlashing);
          expect(screen.showBackgroundCrowds, route == _Route.massBattle);
          expect(
            find.byKey(_crowdLayerKey),
            route == _Route.massBattle ? findsOneWidget : findsNothing,
          );
          expect(controller.state, initialState);
          expect(controller.events, isEmpty);

          await tester.runAsync(() async {
            service.loads.last.complete();
            await scope.read(gameplaySettingsProvider.future);
            await Future<void>.delayed(Duration.zero);
            await tester.pump();
          });
          screen = tester.widget<Phase0aBattleScreen>(
            find.byType(Phase0aBattleScreen),
          );
          expect(screen.controller, same(controller));
          expect(screen.reduceEffects, updated.reduceEffects);
          expect(screen.reduceFlashing, updated.reduceFlashing);
          expect(screen.showBackgroundCrowds, route == _Route.massBattle);
          expect(
            find.byKey(_crowdLayerKey),
            route == _Route.massBattle ? findsOneWidget : findsNothing,
          );
          expect(controller.state, initialState);
          expect(controller.events, isEmpty);
          final probe = tester.widget<ProductionBattleFrameProfile>(
            find.byType(ProductionBattleFrameProfile),
          );
          expect(
            probe.scene['configuration'],
            containsPair('reduce_effects', false),
          );
          expect(
            probe.scene['configuration'],
            containsPair('reduce_flashing', true),
          );
          expect(tester.takeException(), isNull);
        } finally {
          await tester.runAsync(() async {
            await tester.pumpWidget(const SizedBox.shrink());
            await ProductionBattleFrameProfile.flushPendingEvidence();
          });
          scope.dispose();
        }
        final evidence =
            jsonDecode(File('$output/summary.json').readAsStringSync()) as Map;
        expect(evidence['sampling_status'], 'INCOMPLETE');
        expect(
          evidence['invalid_reasons'],
          contains('scene_configuration_changed'),
        );
        expect(evidence['composite_gate'], isFalse);
      },
    );
  }

  for (final automaticRetry in [false, true]) {
    testWidgets(
      'settings read failure retains fallback battle (automaticRetry=$automaticRetry)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final retry = Completer<GameplaySettings>();
        var reads = 0;
        final scope = ProviderContainer(
          overrides: [
            gameplaySettingsProvider.overrideWith(
              (ref) => reads++ == 0
                  ? Future<GameplaySettings>.error(
                      automaticRetry
                          ? Exception('local settings fixture')
                          : StateError('local settings fixture'),
                    )
                  : retry.future,
            ),
          ],
        );
        try {
          await tester.runAsync(() async {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: scope,
                child: MaterialApp(
                  home: Phase0aMainlineBattleHost(
                    stage: repository.getStage('stage_01_01'),
                    seedForTest: _seed,
                    onVictory: (_) => fail('No battle time has elapsed'),
                    onDefeat: (_) => fail('No battle time has elapsed'),
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
          var screen = tester.widget<Phase0aBattleScreen>(
            find.byType(Phase0aBattleScreen),
          );
          expect(scope.read(gameplaySettingsProvider).hasError, isTrue);
          expect(
            scope.read(gameplaySettingsProvider).isLoading,
            automaticRetry,
          );
          expect(screen.reduceEffects, isFalse);
          expect(screen.reduceFlashing, isTrue);
          expect(screen.showBackgroundCrowds, isFalse);
          expect(find.byKey(_crowdLayerKey), findsNothing);
          expect(screen.controller.state.tick, 0);
          expect(find.byType(SelectableText), findsNothing);
          final controller = screen.controller;
          final screenState = tester.state(find.byType(Phase0aBattleScreen));
          await tester.runAsync(() async {
            if (automaticRetry) {
              // Let Riverpod's real default retry timer run. The second read stays
              // pending until completed below; the live screen must survive it.
              for (var attempt = 0; attempt < 100 && reads < 2; attempt++) {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                await tester.pump();
              }
            } else {
              scope.invalidate(gameplaySettingsProvider);
            }
            await tester.pump();
            await Future<void>.delayed(Duration.zero);
            await tester.pump();
          });
          expect(reads, 2);
          expect(scope.read(gameplaySettingsProvider).isLoading, isTrue);
          expect(scope.read(gameplaySettingsProvider).hasValue, isFalse);
          screen = tester.widget<Phase0aBattleScreen>(
            find.byType(Phase0aBattleScreen),
          );
          expect(screen.controller, same(controller));
          expect(
            tester.state(find.byType(Phase0aBattleScreen)),
            same(screenState),
          );
          expect(screen.reduceFlashing, isTrue);
          await tester.runAsync(() async {
            retry.complete(const GameplaySettings());
            await scope.read(gameplaySettingsProvider.future);
            await Future<void>.delayed(Duration.zero);
            await tester.pump();
          });
          screen = tester.widget<Phase0aBattleScreen>(
            find.byType(Phase0aBattleScreen),
          );
          expect(screen.controller, same(controller));
          expect(
            tester.state(find.byType(Phase0aBattleScreen)),
            same(screenState),
          );
          expect(screen.reduceFlashing, isFalse);
          expect(controller.state.tick, 0);
          expect(controller.events, isEmpty);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.runAsync(
            () => tester.pumpWidget(const SizedBox.shrink()),
          );
          scope.dispose();
        }
      },
    );
  }

  testWidgets('mass battle crowd on off on invalidates the real profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final service = GameplaySettingsService();
    const initial = GameplaySettings();
    await service.save(initial);
    final scope = ProviderContainer();
    await scope.read(gameplaySettingsProvider.future);
    final output = '${directory.path}/crowd-profile-switch';
    BattleFrameProfileProbe.configureFromArgs([
      '--battle-profile-scope=production',
      '--battle-profile-content-id=stage_mass_battle_01',
      '--battle-profile-run-id=crowd-profile-switch',
      '--battle-profile-output=$output',
      '--battle-profile-sample-seconds=60',
      '--battle-profile-viewport=1280x720',
    ]);
    BattleFrameProfileProbe.recordEntryOrigin(visual: false);
    addTearDown(() => BattleFrameProfileProbe.configureFromArgs([]));
    try {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: scope,
            child: MaterialApp(
              home: Phase0aMainlineBattleHost(
                stage: repository.getStage('stage_mass_battle_01'),
                seedForTest: _seed,
                controller: ActivityController.playerBot,
                massBattleFormation: Formation.yanXing,
                onVictory: (_) =>
                    fail('This profile probe stops before terminal'),
                onDefeat: (_) =>
                    fail('This profile probe stops before terminal'),
              ),
            ),
          ),
        );
        for (
          var attempt = 0;
          attempt < 100 && find.byType(Phase0aBattleScreen).evaluate().isEmpty;
          attempt++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
      });
      var screen = tester.widget<Phase0aBattleScreen>(
        find.byType(Phase0aBattleScreen),
      );
      final controller = screen.controller;
      expect(controller.state.tick, 0);
      expect(screen.showBackgroundCrowds, isTrue);
      expect(find.byKey(_crowdLayerKey), findsOneWidget);
      final firstProbe = tester.widget<ProductionBattleFrameProfile>(
        find.byType(ProductionBattleFrameProfile),
      );
      expect(
        firstProbe.scene['configuration'],
        containsPair('background_crowds_enabled', true),
      );
      expect(
        firstProbe.scene['configuration'],
        containsPair('background_crowd_figure_budget', 32),
      );
      controller.step(screen.botCommandBuilder!(controller.state));
      expect(controller.state.tick, 1);
      expect(controller.events, isNotEmpty);
      final before = controller.state;
      final events = controller.events.toList();
      final records = controller.lastEventRecords.toList();

      for (final visible in [false, true]) {
        await tester.runAsync(() async {
          await service.save(initial.copyWith(showBackgroundCrowds: visible));
          scope.invalidate(gameplaySettingsProvider);
          await scope.read(gameplaySettingsProvider.future);
          await Future<void>.delayed(Duration.zero);
          await tester.pump();
        });
        screen = tester.widget<Phase0aBattleScreen>(
          find.byType(Phase0aBattleScreen),
        );
        expect(screen.controller, same(controller));
        expect(screen.showBackgroundCrowds, visible);
        expect(
          find.byKey(_crowdLayerKey),
          visible ? findsOneWidget : findsNothing,
        );
        expect(screen.reduceEffects, isFalse);
        expect(screen.reduceFlashing, isFalse);
        expect(controller.state, before);
        expect(controller.events, events);
        expect(controller.lastEventRecords, records);
        final probe = tester.widget<ProductionBattleFrameProfile>(
          find.byType(ProductionBattleFrameProfile),
        );
        expect(
          probe.scene['configuration'],
          containsPair('background_crowds_enabled', visible),
        );
        expect(
          probe.scene['configuration'],
          containsPair('background_crowd_figure_budget', visible ? 32 : 0),
        );
      }
      expect(controller.outcome, Phase0aBattleOutcome.ongoing);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await ProductionBattleFrameProfile.flushPendingEvidence();
      });
      scope.dispose();
    }
    final evidence =
        jsonDecode(File('$output/summary.json').readAsStringSync()) as Map;
    expect(evidence['sampling_status'], 'INCOMPLETE');
    expect(
      evidence['invalid_reasons'],
      contains('scene_configuration_changed'),
    );
    expect(evidence['composite_gate'], isFalse);
    // The scene ends in its original on state: a final-value-only comparison
    // would miss the intervening off profile and incorrectly certify the run.
    expect(
      (evidence['scene'] as Map)['configuration'],
      containsPair('background_crowds_enabled', true),
    );
    expect(
      (evidence['scene_at_capture_end'] as Map)['configuration'],
      containsPair('background_crowds_enabled', true),
    );
    debugPrint(jsonEncode({'crowd_profile_switch_evidence': evidence}));
  });

  for (final route in _Route.values) {
    for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
      testWidgets('${route.name} ${size.width.toInt()}x${size.height.toInt()} '
          'persisted profiles and live switches preserve full headless trace', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        addTearDown(() => BattleFrameProfileProbe.configureFromArgs([]));
        final reference = (await tester.runAsync(
          () => _headlessSession(
            route: route,
            repository: repository,
            player: player,
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

        // Eight persisted crowd/effects/flashing combinations plus one full
        // run changing all combinations in place. Every path reaches the
        // genuine terminal; only massBattle may render a crowd layer.
        for (var variant = 0; variant <= _settings.length; variant++) {
          SharedPreferences.setMockInitialValues({});
          final settingsService = GameplaySettingsService();
          final initial = _settings[variant % _settings.length];
          await settingsService.save(initial);
          final scope = ProviderContainer();
          await scope.read(gameplaySettingsProvider.future);
          CombatSettlementSnapshot? terminal;
          var terminalCalls = 0;
          var milestoneCallbacks = 0;
          final milestoneCompletion = Completer<void>();
          void complete(CombatSettlementSnapshot value) {
            terminal = value;
            terminalCalls++;
          }

          final host = _profileHost(
            route: route,
            repository: repository,
            player: player,
            complete: complete,
            milestoneCompleted: () {
              milestoneCallbacks++;
              milestoneCompletion.complete();
            },
          );
          final runId = '${route.name}-${size.width.toInt()}-$variant';
          final capture = GlobalKey();
          try {
            await tester.runAsync(() async {
              await tester.pumpWidget(
                RepaintBoundary(
                  key: capture,
                  child: UncontrolledProviderScope(
                    container: scope,
                    child: MaterialApp(theme: wuxiaAppTheme(), home: host),
                  ),
                ),
              );
              await tester.pump();
            });
            final finder = find.byType(Phase0aBattleScreen);
            for (
              var attempt = 0;
              attempt < 100 && finder.evaluate().isEmpty;
              attempt++
            ) {
              await tester.runAsync(() async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                await tester.pump();
              });
            }
            expect(finder, findsOneWidget);
            var screen = tester.widget<Phase0aBattleScreen>(finder);
            final controller = screen.controller;
            expect(controller.state, recorded.states.first);
            expect(controller.state.tick, 0);

            void checkPreference(GameplaySettings preference) {
              screen = tester.widget<Phase0aBattleScreen>(finder);
              expect(screen.controller, same(controller));
              expect(screen.reduceEffects, preference.reduceEffects);
              expect(screen.reduceFlashing, preference.reduceFlashing);
              final crowdVisible =
                  route == _Route.massBattle && preference.showBackgroundCrowds;
              expect(screen.showBackgroundCrowds, crowdVisible);
              expect(
                find.byKey(_crowdLayerKey),
                crowdVisible ? findsOneWidget : findsNothing,
              );
            }

            checkPreference(initial);
            if (route == _Route.massBattle && variant < 2) {
              await _captureCrowdViewport(
                tester,
                capture,
                '${size.width.toInt()}-crowds-${initial.showBackgroundCrowds ? 'on' : 'off'}',
              );
              expect(controller.state, recorded.states.first);
            }
            var currentPreference = initial;
            final rawRecords = <CombatEventRecord>[];
            final switchAt = {
              for (var index = 0; index < _settings.length; index++)
                (headless.ticks - 1) * (index + 1) ~/ (_settings.length + 1):
                    _settings[index],
            };
            expect(switchAt, hasLength(_settings.length));
            for (var tick = 0; tick < headless.ticks; tick++) {
              if (variant == _settings.length && switchAt.containsKey(tick)) {
                final preference = switchAt[tick]!;
                final stateBefore = controller.state;
                final eventsBefore = controller.events.toList();
                await tester.runAsync(() async {
                  await settingsService.save(preference);
                  scope.invalidate(gameplaySettingsProvider);
                  await scope.read(gameplaySettingsProvider.future);
                  await Future<void>.delayed(Duration.zero);
                  await tester.pump();
                });
                checkPreference(preference);
                currentPreference = preference;
                expect(controller.state, stateBefore);
                expect(controller.events, eventsBefore);
              }
              final emitted = controller.step(
                reference.bot.commandFor(controller.state),
              );
              expect(
                controller.state,
                recorded.states[tick + 1],
                reason: '$runId full state at tick ${tick + 1}',
              );
              expect(
                emitted,
                recorded.eventsByTick[tick],
                reason: '$runId complete event stream at tick ${tick + 1}',
              );
              expect(
                controller.lastEventRecords,
                recorded.recordsByTick[tick],
                reason: '$runId raw event records at tick ${tick + 1}',
              );
              rawRecords.addAll(controller.lastEventRecords);
              // Let the real screen rebuild and paint repeatedly while the
              // fixed-step combat clock remains explicitly controlled.
              if (tick % 60 == 0) {
                await tester.pump();
                checkPreference(currentPreference);
              }
            }
            if (route == _Route.milestone) {
              await tester.runAsync(() => milestoneCompletion.future);
            }
            await tester.pump();
            checkPreference(currentPreference);
            expect(controller.outcome, headless.outcome);
            expect(controller.events, headless.events);
            expect(rawRecords, headless.eventRecords);
            expect(terminalCalls, 1);
            expect(headlessSettlementFacts(terminal!), expectedSettlement);
            expect(milestoneCallbacks, route == _Route.milestone ? 1 : 0);
            expect(controller.step(), isEmpty);
            expect(controller.state, headless.finalState);
            expect(terminalCalls, 1);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.runAsync(() async {
              await tester.pumpWidget(const SizedBox.shrink());
            });
            scope.dispose();
          }
        }
        // Test evidence only: logical ticks and widget paint are not native
        // frame performance, physical playtest or activity admission proof.
        debugPrint(
          jsonEncode({
            'host_profile_parity': route.contentId,
            'seed': _seed,
            'viewport': '${size.width.toInt()}x${size.height.toInt()}',
            'profiles': _settings.length + 1,
            'crowd_effects_flashing_combinations': _settings.length,
            'ticks_per_profile': headless.ticks,
            'events_per_profile': headless.events.length,
            'raw_records_per_profile': headless.eventRecords.length,
            'outcome': headless.outcome.name,
            'settlement': expectedSettlement,
          }),
        );
      });
    }
  }
}

Future<void> _captureCrowdViewport(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final directory = Platform.environment['WUXIA_CROWD_VISUAL_OUTPUT'];
  if (directory == null) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
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
