import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/basic_attack_chain.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/posture.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/isar_test_support.dart';
import '../../../../support/phase0a_ch1_founder_profile.dart';
import '../../../../support/phase0a_production_headless_benchmark.dart';
import '../../../../support/test_data.dart';

// 更新命令：flutter test --no-pub --dart-define=REGEN_PHASE0A_REDUCER_GOLDENS=true
// test/features/battle/domain/phase0a/reducer_event_stream_golden_test.dart
// 默认只读已提交基准；重新生成也必须先通过场景与机制断言。
const _regenerate = bool.fromEnvironment('REGEN_PHASE0A_REDUCER_GOLDENS');
const _fixtureDirectory = 'test/fixtures/golden/phase0a_reducer';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameRepository repository;
  late CombatantSnapshot founder;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
    final directory = await Directory.systemTemp.createTemp(
      'reducer_golden_founder_',
    );
    try {
      await IsarSetup.init(directory: directory, inspector: false);
      final profile = await seedPhase0aCh1FounderProfile(
        isar: IsarSetup.instance,
        schoolId: 'gang_meng',
        originId: 'mountain_wanderer',
        fateId: 'balanced_seed',
        rngSeed: 20260820,
      );
      founder = profile.snapshot;
      expect(founder.skillLoadout.basicAttack, isNotNull);
      expect(founder.skillLoadout.main1, isNotNull);
      expect(founder.totalEquipmentAttack, greaterThan(0));
    } finally {
      await IsarSetup.close();
      IsarSetup.resetForTest();
      await directory.delete(recursive: true);
    }
  });

  test('主线首关生产目录装配的四百拍完整事件流保持不变', () async {
    await _verifyGolden(
      repository: repository,
      content: const HeadlessBenchmarkContent.mainline('stage_01_01'),
      player: founder,
      profileId: 'gang_meng/mountain_wanderer/balanced_seed/20260820',
      seed: 73,
      steps: 400,
      expectedRoute: 'typed_mainline',
      expectedOutcome: Phase0aBattleOutcome.defeat,
      fixtureName: 'mainline_stage_01_01',
    );
  });

  test('九霄塔第一层生产装配的四百拍完整事件流保持不变', () async {
    await _verifyGolden(
      repository: repository,
      content: const HeadlessBenchmarkContent.tower('tower_1'),
      player: founder,
      profileId: 'gang_meng/mountain_wanderer/balanced_seed/20260820',
      seed: 73,
      steps: 400,
      expectedRoute: 'typed_tower',
      expectedOutcome: Phase0aBattleOutcome.victory,
      fixtureName: 'tower_01',
    );
  });

  test('九霄塔第三十二层破姿态、窗口伤害与恢复的完整事件流保持不变', () async {
    // 复用已有耐久输入夹具，经生产映射装配竞技场，不改敌人、技能或结算规则。
    final player = testCombatantSnapshot(
      realmTier: RealmTier.wuSheng,
      maxHp: 20000,
      defenseRate: 0.9,
      includeProductionBasicAttack: true,
    );
    await _verifyGolden(
      repository: repository,
      content: const HeadlessBenchmarkContent.tower('tower_32'),
      player: player,
      profileId: 'wuSheng_endurance_production_basic',
      seed: 20260912,
      steps: 1200,
      expectedRoute: 'legacy_tower',
      expectedOutcome: Phase0aBattleOutcome.defeat,
      fixtureName: 'tower_32_vulnerability',
      exerciseVulnerability: true,
    );
  });
}

Future<void> _verifyGolden({
  required GameRepository repository,
  required HeadlessBenchmarkContent content,
  required CombatantSnapshot player,
  required String profileId,
  required int seed,
  required int steps,
  required String expectedRoute,
  required Phase0aBattleOutcome expectedOutcome,
  required String fixtureName,
  bool exerciseVulnerability = false,
}) async {
  final session = await createProductionHeadlessSession(
    repository: repository,
    content: content,
    player: player,
    seed: seed,
  );
  expect(session.route, expectedRoute);
  final flow = session.flow;
  final bossId = exerciseVulnerability
      ? flow.state.enemies.firstWhere((enemy) => enemy.isBoss).id
      : null;
  if (bossId != null) {
    final bossSnapshot = session.combatants
        .firstWhere((entry) => entry.actorId == bossId)
        .snapshot;
    expect(bossSnapshot.vulnerabilityMult, isNotNull);
    expect(bossSnapshot.vulnerabilityMult, lessThan(1));
  }

  final frames = <Map<String, Object?>>[];
  final allEvents = <Phase0aEvent>[];
  final windowDamageTicks = <int>[];
  var sawGuardedHit = false;
  var sawWindowHit = false;
  var terminalEmptyFrames = 0;
  for (var step = 1; step <= steps; step++) {
    final before = flow.state;
    final terminalBefore = flow.outcome != Phase0aBattleOutcome.ongoing;
    final Phase0aPlayerCommand command;
    var vulnerableBefore = false;
    var vulnerabilityTicksBefore = 0;
    if (bossId == null) {
      command = session.bot.commandFor(before);
    } else {
      final boss = before.enemies.firstWhere((enemy) => enemy.id == bossId);
      vulnerableBefore = boss.posture?.isVulnerable ?? false;
      vulnerabilityTicksBefore = boss.posture?.vulnerabilityTicksRemaining ?? 0;
      final offset = boss.position - before.player.position;
      final aim = offset.length > 0
          ? offset.normalized()
          : before.player.facing;
      // 只用正常输入追击首领；窗口开启才释放清场，命中后停手观察窗口到期。
      command = sawWindowHit
          ? const Phase0aPlayerCommand()
          : Phase0aPlayerCommand(
              moveDirection:
                  offset.length > session.bot.playerAdapter.attackRange
                  ? aim
                  : null,
              attack: !vulnerableBefore,
              attackAimDirection: aim,
              attackTargetId: bossId,
              clear: vulnerableBefore,
            );
    }
    final emitted = flow.advance(
      deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
      command: command,
    );
    allEvents.addAll(emitted);
    if (terminalBefore) {
      expect(emitted, isEmpty, reason: '终局后的固定采样拍仍须保留，且不能重复发事件');
      terminalEmptyFrames++;
    }
    if (bossId != null) {
      sawGuardedHit |=
          !vulnerableBefore &&
          emitted.whereType<Phase0aHitLanded>().any(
            (event) => event.target == bossId && event.resolvedDamage > 0,
          );
      final windowHit =
          vulnerableBefore &&
          vulnerabilityTicksBefore > 1 &&
          emitted.whereType<Phase0aClearApplied>().any(
            (event) => event.outcomes.any(
              (outcome) =>
                  outcome.target == bossId && outcome.resolvedDamage > 0,
            ),
          );
      if (windowHit) windowDamageTicks.add(flow.state.tick);
      sawWindowHit |= windowHit;
    }
    frames.add({
      'step': step,
      'tickBefore': before.tick,
      'tickAfter': flow.state.tick,
      'outcome': flow.outcome.name,
      'events': [
        for (var index = 0; index < emitted.length; index++)
          _eventFacts(emitted[index], index),
      ],
    });
  }

  expect(frames, hasLength(steps));
  expect(allEvents, isNotEmpty);
  expect(allEvents.whereType<Phase0aHitLanded>(), isNotEmpty);
  expect(flow.outcome, expectedOutcome);
  expect(terminalEmptyFrames, greaterThan(0));
  switch (expectedOutcome) {
    case Phase0aBattleOutcome.victory:
      expect(allEvents.whereType<Phase0aBattleVictory>(), hasLength(1));
      expect(allEvents.whereType<Phase0aBattleDefeat>(), isEmpty);
    case Phase0aBattleOutcome.defeat:
      expect(allEvents.whereType<Phase0aBattleDefeat>(), hasLength(1));
      expect(allEvents.whereType<Phase0aBattleVictory>(), isEmpty);
    case Phase0aBattleOutcome.ongoing:
      fail('固定场景应在采样结束前进入终局');
  }
  final mechanism = <String, Object?>{};
  if (bossId != null) {
    final postureEvents = allEvents.whereType<Phase0aPostureChanged>().where(
      (event) => event.target == bossId,
    );
    final entered = postureEvents
        .where(
          (event) => event.eventType == PostureEventType.vulnerabilityEntered,
        )
        .toList();
    final ended = postureEvents
        .where(
          (event) => event.eventType == PostureEventType.vulnerabilityEnded,
        )
        .toList();
    expect(entered, isNotEmpty);
    expect(sawGuardedHit, isTrue);
    expect(sawWindowHit, isTrue, reason: '窗口必须消费真实有伤害的清场动作');
    expect(ended, isNotEmpty, reason: '必须记录实际窗口恢复事件');
    expect(entered.first.tick, lessThanOrEqualTo(windowDamageTicks.first));
    expect(windowDamageTicks.first, lessThan(ended.first.tick));
    final boss = flow.state.enemies.firstWhere((enemy) => enemy.id == bossId);
    expect(boss.isAlive, isTrue);
    expect(boss.posture!.isVulnerable, isFalse);
    mechanism.addAll({
      'bossId': bossId,
      'vulnerabilityEnteredTicks': entered.map((event) => event.tick).toList(),
      'windowDamageTicks': windowDamageTicks,
      'vulnerabilityEndedTicks': ended.map((event) => event.tick).toList(),
    });
  }

  final actual = <String, Object?>{
    'contentId': content.contentId,
    'route': session.route,
    'profileId': profileId,
    'seed': seed,
    'fixedDeltaSeconds': repository.numbers.phase0aArena.fixedDeltaSeconds,
    'sampledSteps': steps,
    'finalSimulationTick': flow.state.tick,
    'finalOutcome': flow.outcome.name,
    'eventCount': allEvents.length,
    'terminalEmptyFrames': terminalEmptyFrames,
    'mechanism': mechanism,
    'frames': frames,
  };
  final fixture = File('$_fixtureDirectory/$fixtureName.json');
  if (_regenerate) {
    await fixture.parent.create(recursive: true);
    await fixture.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(actual)}\n',
    );
  } else {
    expect(fixture.existsSync(), isTrue, reason: '缺少已提交的事件流基准：${fixture.path}');
    expect(actual, equals(jsonDecode(await fixture.readAsString())));
  }
  debugPrint(
    '${content.contentId}：采样 $steps 拍，模拟到 ${flow.state.tick} 拍，'
    '${allEvents.length} 个事件，终局空拍 $terminalEmptyFrames，'
    '机制 ${jsonEncode(mechanism)}，基准 ${await fixture.length()} 字节',
  );
}

Map<String, Object?>? _vectorFacts(ArenaVector? value) =>
    value == null ? null : {'x': value.x, 'y': value.y};

Map<String, Object?>? _basicAttackSegmentFacts(BasicAttackSegment? value) =>
    value == null
    ? null
    : {
        'id': value.id,
        'geometryRef': value.geometryRef,
        'timelineRef': value.timelineRef,
        'effectRefs': value.effectRefs,
      };

Map<String, Object?> _skillOutcomeFacts(Phase0aSkillOutcome value) => {
  'target': value.target,
  'resolvedDamage': value.resolvedDamage,
  'isCritical': value.isCritical,
  'defeated': value.defeated,
  'statusApplied': value.statusApplied.name,
  'sourcePosition': _vectorFacts(value.sourcePosition),
  'targetPosition': _vectorFacts(value.targetPosition),
};

// 穷尽所有事件子类，保留原始顺序、序号、坐标与数值，不筛选或舍入字段。
Map<String, Object?> _eventFacts(Phase0aEvent event, int indexInTick) => {
  'indexInTick': indexInTick,
  'seq': event.seq,
  'tick': event.tick,
  ...switch (event) {
    Phase0aActionTimelineChanged() => {
      'type': 'Phase0aActionTimelineChanged',
      'actor': event.actor,
      'actionId': event.actionId,
      'eventType': event.eventType.name,
      'phase': event.phase.name,
      'actionTick': event.actionTick,
    },
    Phase0aQiChanged() => {
      'type': 'Phase0aQiChanged',
      'actor': event.actor,
      'actionId': event.actionId,
      'reason': event.reason.name,
      'applied': event.applied,
      'overflow': event.overflow,
      'current': event.current,
      'windowId': event.windowId,
    },
    Phase0aAttackStarted() => {
      'type': 'Phase0aAttackStarted',
      'actor': event.actor,
      'moveKind': event.moveKind.name,
      'basicAttackSegment': _basicAttackSegmentFacts(event.basicAttackSegment),
      'weaponArchetype': event.weaponArchetype?.name,
      'visualSchool': event.visualSchool?.name,
    },
    Phase0aHitLanded() => {
      'type': 'Phase0aHitLanded',
      'actor': event.actor,
      'target': event.target,
      'moveKind': event.moveKind.name,
      'isCritical': event.isCritical,
      'isUltimate': event.isUltimate,
      'resolvedDamage': event.resolvedDamage,
      'remainingHealth': event.remainingHealth,
      'actorPosition': _vectorFacts(event.actorPosition),
      'targetPosition': _vectorFacts(event.targetPosition),
      'basicAttackSegment': _basicAttackSegmentFacts(event.basicAttackSegment),
      'weaponArchetype': event.weaponArchetype?.name,
      'visualSchool': event.visualSchool?.name,
    },
    Phase0aDefendedEntityHit() => {
      'type': 'Phase0aDefendedEntityHit',
      'actor': event.actor,
      'target': event.target,
      'resolvedDamage': event.resolvedDamage,
      'remainingDurability': event.remainingDurability,
      'actorPosition': _vectorFacts(event.actorPosition),
      'targetPosition': _vectorFacts(event.targetPosition),
    },
    Phase0aDefendedEntityDestroyed() => {
      'type': 'Phase0aDefendedEntityDestroyed',
      'target': event.target,
      'targetPosition': _vectorFacts(event.targetPosition),
    },
    Phase0aStatusDamageApplied() => {
      'type': 'Phase0aStatusDamageApplied',
      'source': event.source,
      'target': event.target,
      'statusType': event.statusType.name,
      'resolvedDamage': event.resolvedDamage,
      'remainingHealth': event.remainingHealth,
      'targetPosition': _vectorFacts(event.targetPosition),
    },
    Phase0aEnemyDefeated() => {
      'type': 'Phase0aEnemyDefeated',
      'target': event.target,
      'defeatKind': event.defeatKind.name,
      'targetPosition': _vectorFacts(event.targetPosition),
    },
    Phase0aBossPhaseChanged() => {
      'type': 'Phase0aBossPhaseChanged',
      'actor': event.actor,
      'phaseIndex': event.phaseIndex,
      'unlockedSkillIds': event.unlockedSkillIds,
    },
    Phase0aBossChargeStarted() => {
      'type': 'Phase0aBossChargeStarted',
      'actor': event.actor,
      'skillId': event.skillId,
      'chargeTicks': event.chargeTicks,
    },
    Phase0aGuardianCoopStrike() => {
      'type': 'Phase0aGuardianCoopStrike',
      'mainGuardian': event.mainGuardian,
      'partner': event.partner,
      'boss': event.boss,
      'target': event.target,
      'mainGuardianDamage': event.mainGuardianDamage,
      'mainGuardianCritical': event.mainGuardianCritical,
      'totalDamage': event.totalDamage,
      'mainGuardianPosition': _vectorFacts(event.mainGuardianPosition),
      'partnerPosition': _vectorFacts(event.partnerPosition),
      'bossPosition': _vectorFacts(event.bossPosition),
      'targetPosition': _vectorFacts(event.targetPosition),
    },
    Phase0aGuardIntercepted() => {
      'type': 'Phase0aGuardIntercepted',
      'actor': event.actor,
      'boss': event.boss,
      'guardian': event.guardian,
      'skillId': event.skillId,
      'resolvedDamage': event.resolvedDamage,
      'bossPosition': _vectorFacts(event.bossPosition),
      'guardianPosition': _vectorFacts(event.guardianPosition),
    },
    Phase0aPostureChanged() => {
      'type': 'Phase0aPostureChanged',
      'actor': event.actor,
      'target': event.target,
      'eventType': event.eventType.name,
      'amount': event.amount,
      'accumulated': event.accumulated,
      'capacity': event.capacity,
      'vulnerabilityTicksRemaining': event.vulnerabilityTicksRemaining,
      'hitKind': event.hitKind?.name,
      'targetPosition': _vectorFacts(event.targetPosition),
    },
    Phase0aEnemySkillStarted() => {
      'type': 'Phase0aEnemySkillStarted',
      'actor': event.actor,
      'skillId': event.skillId,
    },
    Phase0aGatherStarted() => {
      'type': 'Phase0aGatherStarted',
      'actor': event.actor,
      'skillId': event.skillId,
      'actorPosition': _vectorFacts(event.actorPosition),
      'centerPosition': _vectorFacts(event.centerPosition),
    },
    Phase0aGatherApplied() => {
      'type': 'Phase0aGatherApplied',
      'actor': event.actor,
      'outcomes': event.outcomes.map(_skillOutcomeFacts).toList(),
    },
    Phase0aClearStarted() => {
      'type': 'Phase0aClearStarted',
      'actor': event.actor,
      'skillId': event.skillId,
      'actorPosition': _vectorFacts(event.actorPosition),
    },
    Phase0aClearApplied() => {
      'type': 'Phase0aClearApplied',
      'actor': event.actor,
      'outcomes': event.outcomes.map(_skillOutcomeFacts).toList(),
    },
    Phase0aSkillStarted() => {
      'type': 'Phase0aSkillStarted',
      'actor': event.actor,
      'hotkey': event.hotkey,
      'skillId': event.skillId,
    },
    Phase0aSkillApplied() => {
      'type': 'Phase0aSkillApplied',
      'actor': event.actor,
      'hotkey': event.hotkey,
      'skillId': event.skillId,
      'outcomes': event.outcomes.map(_skillOutcomeFacts).toList(),
    },
    Phase0aSkillAvailabilityChanged() => {
      'type': 'Phase0aSkillAvailabilityChanged',
      'slot': event.slot,
      'availability': event.availability.name,
      'cooldownRemaining': event.cooldownRemaining,
      'qiCurrent': event.qiCurrent,
      'qiRequired': event.qiRequired,
    },
    Phase0aWaveStarted() => {
      'type': 'Phase0aWaveStarted',
      'waveIndex': event.waveIndex,
      'waveTotal': event.waveTotal,
    },
    Phase0aWaveCleared() => {
      'type': 'Phase0aWaveCleared',
      'waveIndex': event.waveIndex,
    },
    Phase0aSpawnWarningStarted() => {
      'type': 'Phase0aSpawnWarningStarted',
      'entryId': event.entryId,
      'enemyId': event.enemyId,
      'entryPosition': _vectorFacts(event.entryPosition),
    },
    Phase0aEnemyEntered() => {
      'type': 'Phase0aEnemyEntered',
      'entryId': event.entryId,
      'enemyId': event.enemyId,
      'entryPosition': _vectorFacts(event.entryPosition),
    },
    Phase0aSpawnGraceExpired() => {
      'type': 'Phase0aSpawnGraceExpired',
      'entryId': event.entryId,
      'enemyId': event.enemyId,
      'entryPosition': _vectorFacts(event.entryPosition),
    },
    Phase0aBattleVictory() => {'type': 'Phase0aBattleVictory'},
    Phase0aBattleDefeat() => {'type': 'Phase0aBattleDefeat'},
    Phase0aDefenseStarted() => {
      'type': 'Phase0aDefenseStarted',
      'actor': event.actor,
      'action': event.action.name,
      'fromPosition': _vectorFacts(event.fromPosition),
      'toPosition': _vectorFacts(event.toPosition),
      'windowTicks': event.windowTicks,
      'shieldAbsorption': event.shieldAbsorption,
    },
    Phase0aDefenseResolved() => {
      'type': 'Phase0aDefenseResolved',
      'attackId': event.attackId,
      'attacker': event.attacker,
      'target': event.target,
      'branch': event.branch.name,
      'incomingDamage': event.incomingDamage,
      'counterDamage': event.counterDamage,
      'shieldRemaining': event.shieldRemaining,
      'nonRecursive': event.nonRecursive,
      'targetPosition': _vectorFacts(event.targetPosition),
    },
  },
};
