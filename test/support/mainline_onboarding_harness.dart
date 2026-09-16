import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/action_timeline.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_list_screen.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/features/onboarding/domain/founder_creation_selection.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/utils/math_random.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/shared/utils/rng_provider.dart';

import 'isar_test_support.dart';
import 'test_data.dart';

const onboardingFounderSeed = 20260820;
const onboardingCombatSeed = 20260906;
const onboardingTickLimit = 2400;

enum OnboardingPolicy {
  baseline,
  coarse,
  slow,
  stationary,
  // E deliberately reruns C's existing kite decisions every third tick.
  kiteSlow,
  kiteNoDodge,
}

Future<void> onboardingWaitFor(
  WidgetTester tester,
  bool Function() ready, {
  String reason = 'production navigation did not become ready',
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 25));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(
    ready(),
    isTrue,
    reason:
        '$reason; visible text: ${tester.allWidgets.whereType<Text>().map((t) => t.data).join('|')}',
  );
}

Future<void> emitOnboardingRow(
  WidgetTester tester,
  String stream,
  Map<String, Object?> row,
) async {
  final encoded = jsonEncode(row);
  debugPrintSynchronously('ONBOARDING_${stream.toUpperCase()} $encoded');
  final directory = Platform.environment['P2_ONBOARDING_EVIDENCE_DIR'];
  if (directory != null) {
    await tester.runAsync(() async {
      await Directory(directory).create(recursive: true);
      await File(
        '$directory/$stream.jsonl',
      ).writeAsString('$encoded\n', mode: FileMode.append, flush: true);
    });
  }
}

Future<Directory> createOnboardingSave(
  WidgetTester tester, {
  String school = 'gang_meng',
  String origin = 'mountain_wanderer',
}) async {
  late Directory directory;
  debugPrintSynchronously('ONBOARDING_PHASE create_save_begin');
  await tester.runAsync(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
    debugPrintSynchronously('ONBOARDING_PHASE repository_loaded');
    directory = await Directory.systemTemp.createTemp('onboarding_chain_');
    await IsarSetup.init(directory: directory, inspector: false);
    debugPrintSynchronously('ONBOARDING_PHASE isar_initialized');
    final config = GameRepository.instance.founderCreation;
    expect(
      await OnboardingService(
        isar: IsarSetup.instance,
        rng: DefaultRng(seed: onboardingFounderSeed),
      ).createFoundingMaster(
        selection: FounderCreationSelection(
          school: config.schools.singleWhere((s) => s.id == school),
          origin: config.origins.singleWhere((s) => s.id == origin),
          fate: config.fatePool.singleWhere((s) => s.id == 'balanced_seed'),
        ),
      ),
      isTrue,
    );
  });
  debugPrintSynchronously('ONBOARDING_PHASE founder_created');
  return directory;
}

Future<void> closeOnboardingSave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.runAsync(() async {
    if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
    IsarSetup.resetForTest();
  });
}

Future<void> mountOnboardingMap(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  rootBundle.evict('data/narratives/chapters/chapter_01.yaml');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mathRandomProvider.overrideWithValue(Random(onboardingCombatSeed)),
        rngProvider.overrideWithValue(DefaultRng(seed: onboardingCombatSeed)),
      ],
      child: const MaterialApp(home: StageListScreen(chapterIndex: 1)),
    ),
  );
  await onboardingWaitFor(
    tester,
    () => find
        .text(GameRepository.instance.getStage('stage_01_01').name)
        .evaluate()
        .isNotEmpty,
  );
}

Future<Phase0aMainlineBattleHost> waitOnboardingHost(
  WidgetTester tester,
  String stageId,
) async {
  await onboardingWaitFor(tester, () {
    final hosts = find.byType(Phase0aMainlineBattleHost);
    return hosts.evaluate().length == 1 &&
        tester.widget<Phase0aMainlineBattleHost>(hosts).stage.id == stageId &&
        find.byType(Phase0aBattleScreen).evaluate().length == 1;
  }, reason: 'real Host for $stageId did not load');
  final host = tester.widget<Phase0aMainlineBattleHost>(
    find.byType(Phase0aMainlineBattleHost),
  );
  expect(host.controller, ActivityController.human);
  expect(host.playerSnapshotForTest, isNull);
  expect(host.seedForTest, isNull);
  expect(host.encounterHostFactory, isNull);
  return host;
}

Future<Map<String, Object?>> readOnboardingProgress() async {
  final isar = IsarSetup.instance;
  final characters = await isar.characters.where().findAll();
  final founder = characters.singleWhere((c) => c.isFounder);
  final equipment = await isar.equipments.where().findAll();
  final save = (await isar.saveDatas.where().findAll()).single;
  final progress = await isar.mainlineProgress.where().findAll();
  final journals = await isar.mainlineSettlementJournals.where().findAll();
  return {
    'characterId': founder.id,
    'experience': founder.experience,
    'realm': '${founder.realmTier.name}/${founder.realmLayer.name}',
    'internalForce': founder.internalForce,
    'injuryHours': founder.injuryHoursRemaining,
    'lightInjuryStacks': founder.lightInjuryStacks,
    'equippedIds': [
      founder.equippedWeaponId,
      founder.equippedArmorId,
      founder.equippedAccessoryId,
    ],
    'equipment': [
      for (final e in equipment)
        {
          'id': e.id,
          'defId': e.defId,
          'attack': e.baseAttack,
          'battles': e.battleCount,
        },
    ],
    'skills': founder.learnedSkillIds,
    'unlocks': [
      for (final s in save.skillUnlockProgress)
        {
          'skill': s.skillId,
          'unlocked': s.unlocked,
          'fragments': s.fragmentCount,
        },
    ],
    'tutorialStep': save.tutorialStep,
    'clearedStageIds': progress.isEmpty
        ? <String>[]
        : progress.single.clearedStageIds,
    'journals': [
      for (final j in journals)
        {
          'stage': j.stageId,
          'phase': j.phase.name,
          'runId': j.runId,
          'loadoutVersion': j.loadoutVersion,
          'loadoutSnapshotIds': j.loadoutSnapshotIds,
          'participantId': j.participantId,
        },
    ],
  };
}

Map<String, Object?> onboardingSnapshot(CombatantSnapshot s) => {
  'characterId': s.characterId,
  'realmTier': s.realmTier.name,
  'realmLayer': s.realmLayer.name,
  'school': s.school.name,
  'maxHp': s.maxHp,
  'currentHp': s.currentHp,
  'internalForce': s.internalForce,
  'maxQi': s.maxQi,
  'currentQi': s.currentQi,
  'autoUltimate': s.autoUltimate,
  'speed': s.speed,
  'criticalRate': s.criticalRate,
  'evasionRate': s.evasionRate,
  'defenseRate': s.defenseRate,
  'equipmentAttack': s.totalEquipmentAttack,
  'mainCultivationLayer': s.mainCultivationLayer.name,
  'weapon': s.weaponArchetype?.name,
  'skillLoadout': {
    'basic': s.skillLoadout.basicAttack?.id,
    'main1': s.skillLoadout.main1?.id,
    'main2': s.skillLoadout.main2?.id,
    'assist': s.skillLoadout.assist?.id,
    'resonance': s.skillLoadout.resonance?.id,
    'ultimate': s.skillLoadout.ultimate?.id,
    'encounter': s.skillLoadout.encounter?.id,
    'key': s.skillLoadout.key?.id,
  },
  'skills': [
    for (final skill in s.availableSkills)
      {'id': skill.id, 'powerMultiplier': skill.powerMultiplier},
  ],
  'skillUses': s.skillUses,
  'openingSkillCooldowns': s.openingSkillCooldowns,
  'activeBuffs': s.activeBuffs,
  'attackPowerMultiplier': s.attackPowerMultiplier,
  'outputMultiplier': s.outputMultiplier,
  'qiGainMultiplier': s.qiGainMultiplier,
  'qiCostReductionPct': s.qiCostReductionPct,
  'forgingPiercePct': s.forgingPiercePct,
  'forgingLifestealPct': s.forgingLifestealPct,
  'swordSongResonanceActive': s.swordSongResonanceActive,
  'schoolDamageTakenMult': {
    for (final entry in s.schoolDamageTakenMult.entries)
      entry.key.name: entry.value,
  },
  'lineageRole': s.lineageRole?.name,
  'guardianWardMult': s.guardianWardMult,
  'guardianDefIds': s.guardianDefIds,
  'vulnerabilityMult': s.vulnerabilityMult,
  'guardInterceptsInterrupt': s.guardInterceptsInterrupt,
};

Future<Map<String, Object?>> driveOnboardingBattle(
  WidgetTester tester,
  Phase0aMainlineBattleHost host, {
  OnboardingPolicy policy = OnboardingPolicy.baseline,
}) async {
  final screen = tester.widget<Phase0aBattleScreen>(
    find.byType(Phase0aBattleScreen),
  );
  final controller = screen.controller;
  final entryTick = controller.state.tick;
  expect(entryTick, 0, reason: 'each policy must start before the first tick');
  final held = <LogicalKeyboardKey>{};
  Future<void> keys(Set<LogicalKeyboardKey> desired) async {
    for (final key in held.difference(desired).toList()) {
      await tester.sendKeyUpEvent(key);
      held.remove(key);
    }
    for (final key in desired.difference(held).toList()) {
      await tester.sendKeyDownEvent(key);
      held.add(key);
    }
  }

  final hpCurve = <Map<String, Object?>>[];
  final aliveCurve = <Map<String, Object?>>[];
  final visibleCurve = <Map<String, Object?>>[];
  final actionTicks = <String, int>{};
  var peakAlive = 0;
  var peakVisibleAlive = 0;
  var previousVisibleTick = -1;
  var observedTicks = 0;
  var previousPosition = controller.state.player.position;
  var previousTick = -1;
  void observe() {
    final state = controller.state;
    if (state.tick == previousTick) return;
    previousTick = state.tick;
    final alive = state.enemies.where((e) => e.isAlive).length;
    peakAlive = max(peakAlive, alive);
    aliveCurve.add({'tick': state.tick, 'aliveEnemies': alive});
    if (state.tick % 10 == 0 ||
        controller.outcome != Phase0aBattleOutcome.ongoing) {
      hpCurve.add({
        'tick': state.tick,
        'hp': state.player.currentHealth,
        'aliveEnemies': alive,
      });
    }
    if (state.tick > 0) {
      final player = state.player;
      final category = player.dodgeTicksRemaining > 0
          ? 'dodge'
          : player.staggerTicksRemaining > 0
          ? 'stagger'
          : player.basicAction != null
          ? 'basic_${player.basicAction!.timeline.phase.name}'
          : player.position != previousPosition
          ? 'movement'
          : 'idle_or_instant_action';
      actionTicks.update(category, (value) => value + 1, ifAbsent: () => 1);
      observedTicks++;
    }
    previousPosition = state.player.position;
  }

  observe();
  void observeVisible() {
    final state = controller.state;
    if (state.tick == previousVisibleTick) return;
    previousVisibleTick = state.tick;
    // The production actor boundary is inside its camera-controlled Offstage.
    // Sample after pump, once this tick's render positions have been built.
    final visible = state.enemies.where((enemy) {
      return enemy.isAlive &&
          find
              .byKey(ValueKey('phase0a_actor_${enemy.id}'))
              .evaluate()
              .isNotEmpty;
    }).length;
    peakVisibleAlive = max(peakVisibleAlive, visible);
    visibleCurve.add({'tick': state.tick, 'visibleAliveEnemies': visible});
  }

  observeVisible();
  controller.addListener(observe);
  var nextClearAttempt = 0;
  var nextSkillAttempt = 5;
  var decisions = 0;
  var spaceKeyEvents = 0;
  final decisionInterval =
      policy == OnboardingPolicy.slow || policy == OnboardingPolicy.kiteSlow
      ? 3
      : 1;
  try {
    for (
      var tick = 0;
      tick < onboardingTickLimit &&
          controller.outcome == Phase0aBattleOutcome.ongoing;
      tick++
    ) {
      if (tick % decisionInterval == 0) {
        decisions++;
        final p = controller.state.player.position;
        final enemies =
            controller.state.enemies.where((e) => e.isAlive).toList()..sort(
              (a, b) => (a.position - p).lengthSquared.compareTo(
                (b.position - p).lengthSquared,
              ),
            );
        final desired = <LogicalKeyboardKey>{};
        final close =
            enemies.isNotEmpty && (enemies.first.position - p).length < 180;
        if (policy != OnboardingPolicy.coarse || close) {
          desired.add(LogicalKeyboardKey.keyJ);
        }
        if (policy != OnboardingPolicy.stationary && enemies.isNotEmpty) {
          var d = enemies.first.position - p;
          final distance = d.length;
          var move = distance > screen.basicAttackRange! * .85;
          if (policy != OnboardingPolicy.coarse) {
            final retreat =
                distance < 130 &&
                controller.state.player.attackCooldownRemaining > 0;
            if (retreat) d = d * -1;
            move = retreat || distance > screen.basicAttackRange! * .9;
            if (p.x.abs() > 570 || p.y.abs() > 220) {
              d = p * -1;
              move = true;
            }
          }
          if (move) {
            if (d.x.abs() > 10) {
              desired.add(
                d.x > 0 ? LogicalKeyboardKey.keyD : LogicalKeyboardKey.keyA,
              );
            }
            if (d.y.abs() > 10) {
              desired.add(
                d.y > 0 ? LogicalKeyboardKey.keyS : LogicalKeyboardKey.keyW,
              );
            }
          }
        } else if (policy != OnboardingPolicy.stationary &&
            controller.checkpointObjectiveProgress?.remainingEnemies == 0) {
          desired.add(LogicalKeyboardKey.keyD);
        }
        await keys(desired);
        if (policy == OnboardingPolicy.coarse) {
          if (tick % 30 == 0) {
            await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
            await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
          }
        } else if (policy != OnboardingPolicy.stationary) {
          final effectResolved =
              controller
                  .state
                  .player
                  .basicAction
                  ?.timeline
                  .firstEffectEmitted ==
              true;
          if (close && effectResolved) {
            if (tick >= nextClearAttempt) {
              await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
              nextClearAttempt = tick + 10;
            } else if (tick >= nextSkillAttempt) {
              await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
              nextSkillAttempt = tick + 10;
            }
          }
          if (policy != OnboardingPolicy.kiteNoDodge &&
              close &&
              controller.state.player.defenseCooldownRemaining == 0) {
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            spaceKeyEvents++;
          }
        }
      }
      await tester.pump(const Duration(milliseconds: 100));
      observeVisible();
    }
  } finally {
    await keys({});
    controller.removeListener(observe);
  }
  final playerId = controller.state.player.id;
  final hits = <Map<String, Object?>>[
    for (final e in controller.events)
      if (e is Phase0aHitLanded && e.target == playerId)
        {
          'tick': e.tick,
          'source': e.actor,
          'kind': 'hit',
          'damage': e.resolvedDamage,
          'remainingHp': e.remainingHealth,
        }
      else if (e is Phase0aStatusDamageApplied && e.target == playerId)
        {
          'tick': e.tick,
          'source': e.source,
          'kind': e.statusType.name,
          'damage': e.resolvedDamage,
          'remainingHp': e.remainingHealth,
        },
  ];
  final sourceTotals = <String, int>{};
  for (final hit in hits) {
    if (hit['damage'] == 0) continue;
    final source = '${hit['source']}:${hit['kind']}';
    sourceTotals.update(
      source,
      (value) => value + (hit['damage']! as int),
      ifAbsent: () => hit['damage']! as int,
    );
  }
  final ranked = sourceTotals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final recentTicks = (3 / controller.fixedDeltaSeconds).ceil();
  return {
    'stage': host.stage.id,
    'policy': policy.name,
    'founderSeed': onboardingFounderSeed,
    'combatSeed': onboardingCombatSeed,
    'maxHp': host.playerSnapshot!.maxHp,
    'equipmentAttack': host.playerSnapshot!.totalEquipmentAttack,
    'entrySnapshot': onboardingSnapshot(host.playerSnapshot!),
    'outcome': controller.outcome.name,
    'completed': true,
    'stopReason': controller.outcome == Phase0aBattleOutcome.ongoing
        ? 'tick_limit'
        : 'terminal_outcome',
    'entryTick': entryTick,
    'ticks': controller.state.tick,
    'deathSeconds': controller.outcome == Phase0aBattleOutcome.defeat
        ? controller.state.tick * controller.fixedDeltaSeconds
        : null,
    'remainingHp': controller.state.player.currentHealth,
    'kills': controller.events.whereType<Phase0aEnemyDefeated>().length,
    'playerHits': controller.events
        .whereType<Phase0aHitLanded>()
        .where((e) => e.actor == playerId)
        .length,
    'enemyAttacks': controller.events
        .whereType<Phase0aAttackStarted>()
        .where((e) => e.actor != playerId)
        .length,
    'enemySkills': controller.events
        .whereType<Phase0aEnemySkillStarted>()
        .length,
    'peakAliveEnemies': peakAlive,
    'peakVisibleAliveEnemies': peakVisibleAlive,
    'aliveCountDefinition':
        'active living roster; visible count additionally uses production camera Offstage after each rendered pump',
    'decisions': decisions,
    'decisionIntervalTicks': decisionInterval,
    'spaceKeyEvents': spaceKeyEvents,
    if (policy == OnboardingPolicy.kiteSlow)
      'equivalentExistingPolicy': OnboardingPolicy.slow.name,
    'firstEffects': controller.events
        .whereType<Phase0aActionTimelineChanged>()
        .where(
          (e) =>
              e.eventType == ActionTimelineEventType.firstEffect &&
              e.actor == playerId,
        )
        .length,
    'tickSeconds': controller.fixedDeltaSeconds,
    'tickLimit': onboardingTickLimit,
    'hpEvery10Ticks': hpCurve,
    'aliveEnemiesEveryTick': aliveCurve,
    'visibleAliveEnemiesEveryRenderedTick': visibleCurve,
    'damageSourcesTop3': [
      for (final e in ranked.take(3)) {'source': e.key, 'damage': e.value},
    ],
    'last3SecondsDamage': controller.outcome == Phase0aBattleOutcome.defeat
        ? hits
              .where(
                (hit) =>
                    (hit['tick']! as int) > controller.state.tick - recentTicks,
              )
              .toList()
        : <Map<String, Object?>>[],
    'playerActionTickShares': {
      for (final e in actionTicks.entries) e.key: e.value / observedTicks,
    },
    'actionShareDefinition':
        'mutually exclusive observed tick occupancy: dodge > stagger > basic timeline phase > movement > idle/instant action',
    'damageDefinition':
        'resolved event damage before HP clamping; includes lethal overkill; zero-damage contacts retained only in recent-hit records',
  };
}

/// Each policy reopens a separate byte-identical copy of the naturally prepared
/// save, then enters its uncleared stage through the real map. Battle controllers
/// and keyboard state are never shared between policies. All policies, including
/// A, restart the same RNG seed; a saved journal does not persist an RNG cursor.
Future<List<Map<String, Object?>>> runOnboardingTolerance(
  WidgetTester tester, {
  required File checkpoint,
  required String stageId,
  List<OnboardingPolicy> policies = const [
    OnboardingPolicy.baseline,
    OnboardingPolicy.coarse,
    OnboardingPolicy.slow,
    OnboardingPolicy.stationary,
  ],
}) async {
  expect(policies, isNotEmpty);
  final sealedBytes = (await tester.runAsync(checkpoint.readAsBytes))!;
  final records = <Map<String, Object?>>[];
  Map<String, Object?>? expectedProgress;
  Map<String, Object?>? expectedSnapshot;
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  try {
    for (final policy in policies) {
      late Directory directory;
      await tester.runAsync(() async {
        await initializeTestIsarCore();
        await loadTestGameRepository();
        directory = await Directory.systemTemp.createTemp('onboarding_policy_');
        final copied = await checkpoint.copy(
          '${directory.path}/wuxia_save_slot1.isar',
        );
        expect(listEquals(await copied.readAsBytes(), sealedBytes), isTrue);
        await IsarSetup.init(directory: directory, inspector: false);
      });
      try {
        await mountOnboardingMap(tester);
        final stage = find.text(GameRepository.instance.getStage(stageId).name);
        await tester.ensureVisible(stage);
        await tester.tap(stage);
        final host = await waitOnboardingHost(tester, stageId);
        final before = (await tester.runAsync(readOnboardingProgress))!;
        expect(before['clearedStageIds']! as List, isNot(contains(stageId)));
        final journal = (before['journals']! as List)
            .cast<Map<String, Object?>>()
            .singleWhere((j) => j['phase'] == 'prepared');
        expect(journal['stage'], stageId);
        expectedProgress ??= before;
        expectedSnapshot ??= onboardingSnapshot(host.playerSnapshot!);
        expect(
          before,
          expectedProgress,
          reason: 'policy entrance save differs',
        );
        expect(
          onboardingSnapshot(host.playerSnapshot!),
          expectedSnapshot,
          reason: 'policy entrance combat attributes differ',
        );
        final row = await driveOnboardingBattle(tester, host, policy: policy);
        row.addAll({
          'checkpoint': checkpoint.path,
          'checkpointByteLength': sealedBytes.length,
          'checkpointBytesEqual': true,
          'entryProgress': before,
          'referencePolicy': policies.first.name,
          'sameEntryAsReference': true,
          if (policies.first == OnboardingPolicy.baseline) 'sameEntryAsA': true,
          'rngScope':
              'fresh identical seed for every selected policy; original continuous-run RNG cursor is not restored',
        });
        expect(row['completed'], isTrue);
        expect(row['ticks']! as int, greaterThan(0));
        await emitOnboardingRow(tester, 'tolerance', row);
        records.add(row);
        if (row['outcome'] != 'ongoing') {
          final action = row['outcome'] == 'victory'
              ? UiStrings.stageVictoryReturnToMap
              : UiStrings.stageRetryBackAction;
          await onboardingWaitFor(
            tester,
            () => find.text(action).evaluate().isNotEmpty,
            reason: 'wait for real settlement before closing policy storage',
          );
          await tester.tap(find.text(action));
          await onboardingWaitFor(
            tester,
            () => find.byType(Phase0aMainlineBattleHost).evaluate().isEmpty,
            reason: 'completed battle must leave its real Host',
          );
          // Optional post-victory affairs may now be awaiting a player choice.
          // The independent disposable policy save ends at battle completion.
        }
      } finally {
        await closeOnboardingSave(tester);
        await tester.runAsync(() => directory.delete(recursive: true));
      }
    }
    expect(records, hasLength(policies.length));
    expect(
      listEquals((await tester.runAsync(checkpoint.readAsBytes))!, sealedBytes),
      isTrue,
      reason: 'the sealed checkpoint must remain unchanged',
    );
    return records;
  } finally {
    await tester.binding.setSurfaceSize(null);
  }
}

/// Exercises normal first-clear navigation and persists only naturally earned
/// progress. A defeat ends the diagnostic; it never fabricates the next entry.
Future<List<Map<String, Object?>>> runOnboardingChain(
  WidgetTester tester, {
  int throughStage = 5,
  int requireVictoriesThrough = 0,
  Directory? checkpoints,
  String school = 'gang_meng',
  String origin = 'mountain_wanderer',
}) async {
  final directory = await createOnboardingSave(
    tester,
    school: school,
    origin: origin,
  );
  final records = <Map<String, Object?>>[];
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  try {
    await mountOnboardingMap(tester);
    debugPrintSynchronously('ONBOARDING_PHASE map_ready');
    await tester.tap(
      find.text(GameRepository.instance.getStage('stage_01_01').name),
    );
    int? participant;
    String? runId;
    for (var index = 1; index <= throughStage; index++) {
      final stageId = 'stage_01_0$index';
      final host = await waitOnboardingHost(tester, stageId);
      participant ??= host.playerSnapshot!.characterId;
      expect(host.playerSnapshot!.characterId, participant);
      debugPrintSynchronously('ONBOARDING_PHASE host_ready $stageId');
      final before = (await tester.runAsync(readOnboardingProgress))!;
      expect(before['clearedStageIds'], [
        for (var n = 1; n < index; n++) 'stage_01_0$n',
      ]);
      final journals = (before['journals']! as List)
          .cast<Map<String, Object?>>();
      final prepared = journals.singleWhere((j) => j['phase'] == 'prepared');
      expect(prepared['stage'], stageId);
      expect(prepared['loadoutVersion'], index);
      expect(prepared['participantId'], participant);
      expect(prepared['loadoutSnapshotIds'], hasLength(index));
      runId ??= prepared['runId']! as String;
      expect(prepared['runId'], runId);

      String? checkpoint;
      if (checkpoints != null) {
        checkpoint = '${checkpoints.path}/$stageId.isar';
        await tester.runAsync(() async {
          await checkpoints.create(recursive: true);
          expect(await File(checkpoint!).exists(), isFalse);
          await IsarSetup.instance.copyToFile(checkpoint);
        });
      }
      debugPrintSynchronously('ONBOARDING_PHASE checkpoint_ready $stageId');
      final row = await driveOnboardingBattle(tester, host);
      row.addAll({
        'school': school,
        'origin': origin,
        'fate': 'balanced_seed',
        'entryProgress': before,
        'checkpoint': checkpoint,
        'streamScope': 'same legal fresh-save continuous first-clear run',
      });
      records.add(row);
      if (row['outcome'] != 'victory') {
        await emitOnboardingRow(tester, 'chain', row);
        expect(
          index,
          greaterThan(requireVictoriesThrough),
          reason: jsonEncode(row),
        );
        break;
      }
      final action = index == 5
          ? UiStrings.stageVictoryReturnToMap
          : UiStrings.stageVictoryEnterNextStage;
      await onboardingWaitFor(
        tester,
        () => find.text(action).evaluate().isNotEmpty,
        reason: 'victory settlement for $stageId did not expose $action',
      );
      await tester.tap(find.text(action));
      if (index < 5) {
        await waitOnboardingHost(tester, 'stage_01_0${index + 1}');
      } else {
        await onboardingWaitFor(
          tester,
          () => find.byType(Phase0aMainlineBattleHost).evaluate().isEmpty,
        );
      }
      final after = (await tester.runAsync(readOnboardingProgress))!;
      row['settledProgress'] = after;
      expect(after['clearedStageIds'], [
        for (var n = 1; n <= index; n++) 'stage_01_0$n',
      ]);
      expect(after['characterId'], participant);
      final afterJournals = (after['journals']! as List)
          .cast<Map<String, Object?>>();
      expect(
        afterJournals.singleWhere((j) => j['stage'] == stageId)['phase'],
        'closed',
      );
      if (index < 5) {
        final next = afterJournals.singleWhere((j) => j['phase'] == 'prepared');
        expect(next['stage'], 'stage_01_0${index + 1}');
        expect(next['loadoutVersion'], index + 1);
        expect(next['runId'], runId);
        expect(next['participantId'], participant);
      }
      // Preserve actual growth and equipment. No reward, attribute, progress or
      // loadout field is written by this test.
      expect(
        after['realm'] != before['realm'] ||
            (after['experience']! as int) > (before['experience']! as int),
        isTrue,
        reason: 'real victory must retain earned growth',
      );
      final oldEquipment = (before['equipment']! as List)
          .cast<Map<String, Object?>>();
      final newEquipment = (after['equipment']! as List)
          .cast<Map<String, Object?>>();
      expect(
        newEquipment.map((e) => e['id']),
        containsAll(oldEquipment.map((e) => e['id'])),
      );
      for (final id in before['equippedIds']! as List) {
        if (id == null) continue;
        final old = oldEquipment.singleWhere((e) => e['id'] == id);
        final current = newEquipment.singleWhere((e) => e['id'] == id);
        expect(current['battles'], greaterThan(old['battles']! as int));
      }
      expect(after['skills']! as List, containsAll(before['skills']! as List));
      expect(after['tutorialStep']! as int, index);
      final oldUnlocks = (before['unlocks']! as List)
          .cast<Map<String, Object?>>()
          .where((s) => s['unlocked'] == true);
      final newUnlocks = (after['unlocks']! as List)
          .cast<Map<String, Object?>>()
          .where((s) => s['unlocked'] == true);
      expect(
        newUnlocks.map((s) => s['skill']),
        containsAll(oldUnlocks.map((s) => s['skill'])),
      );
      await emitOnboardingRow(tester, 'chain', row);
    }
    expect(records, isNotEmpty);
    expect(
      records.where((r) => r['outcome'] == 'victory').length,
      greaterThanOrEqualTo(requireVictoriesThrough),
    );
    return records;
  } finally {
    await closeOnboardingSave(tester);
    await tester.binding.setSurfaceSize(null);
    await tester.runAsync(() => directory.delete(recursive: true));
  }
}
