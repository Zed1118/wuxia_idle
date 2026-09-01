import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/posture.dart';

typedef SingleAttackWeaponCandidate = ({
  double range,
  double halfArcRadians,
  double cooldownSeconds,
  int resolvedDamage,
  int posturePowerMultiplier,
  int maxTargets,
  double attackDisplacement,
  String presentationCue,
});

enum CandidateScenario { clear, elite, boss }

typedef CandidateMetrics = ({
  bool victory,
  double seconds,
  int attacks,
  int hits,
  int defeats,
  int postureWindows,
  int maxHitsPerTick,
  int finalQi,
});

const _fixedDeltaSeconds = 0.1;
const _basicPosturePowerMultiplier = 500;

const _candidates = <WeaponArchetype, SingleAttackWeaponCandidate>{
  WeaponArchetype.sword: (
    range: 170,
    halfArcRadians: 0.32,
    cooldownSeconds: 0.5,
    resolvedDamage: 30,
    posturePowerMultiplier: 500,
    maxTargets: 1,
    attackDisplacement: 0,
    presentationCue: 'straight_balanced_ink_wave',
  ),
  WeaponArchetype.heavy: (
    range: 130,
    halfArcRadians: 0.85,
    cooldownSeconds: 0.8,
    resolvedDamage: 42,
    posturePowerMultiplier: 900,
    maxTargets: 1,
    attackDisplacement: 0,
    presentationCue: 'broad_weighted_ink_wave',
  ),
  WeaponArchetype.flexible: (
    range: 210,
    halfArcRadians: 0.65,
    cooldownSeconds: 0.6,
    resolvedDamage: 27,
    posturePowerMultiplier: 650,
    maxTargets: 1,
    attackDisplacement: 0,
    presentationCue: 'long_curved_ink_ribbon',
  ),
  WeaponArchetype.dual: (
    range: 120,
    halfArcRadians: 0.5,
    cooldownSeconds: 0.4,
    resolvedDamage: 20,
    posturePowerMultiplier: 350,
    maxTargets: 1,
    attackDisplacement: 0,
    presentationCue: 'paired_short_ink_wave',
  ),
  WeaponArchetype.hidden: (
    range: 260,
    halfArcRadians: 0.22,
    cooldownSeconds: 0.6,
    resolvedDamage: 33,
    posturePowerMultiplier: 450,
    maxTargets: 1,
    attackDisplacement: 0,
    presentationCue: 'thin_fast_ink_projectile',
  ),
};

final class _CandidateDamageResolver implements Phase0aDamageResolver {
  const _CandidateDamageResolver(this.damage);

  final int damage;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1.0,
  }) => Phase0aResolvedHit(
    isHit: true,
    isCritical: false,
    damage: kind == Phase0aDamageKind.basic ? damage : 0,
  );
}

Phase0aPlayerInputAdapter _adapter(
  WeaponArchetype archetype,
  SingleAttackWeaponCandidate candidate,
) => Phase0aPlayerInputAdapter(
  playerId: 'player',
  weaponArchetype: archetype,
  attackRange: candidate.range,
  attackHalfArcRadians: candidate.halfArcRadians,
  attackCooldownSeconds: candidate.cooldownSeconds,
  attackQiDelta: 1,
  postureBasicPowerMultiplier: _basicPosturePowerMultiplier,
  attackPowerMultiplier: candidate.posturePowerMultiplier,
  gatherPowerMultiplier: 1,
  clearPowerMultiplier: 1,
  gatherSlot: 'candidate_gather',
  gatherRingRadius: 1,
  gatherEffectRadius: 1,
  gatherQiCost: 0,
  gatherCooldownSeconds: 1,
  clearSlot: 'candidate_clear',
  clearEffectRadius: 1,
  clearQiCost: 0,
  clearCooldownSeconds: 1,
);

Phase0aActor _player() => const Phase0aActor(
  id: 'player',
  side: Phase0aSide.player,
  position: ArenaVector.zero,
  facing: ArenaVector(1, 0),
  maxHealth: 1000,
  currentHealth: 1000,
  moveSpeed: 100,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aActor _enemy({
  required String id,
  required ArenaVector position,
  required int health,
  required Phase0aDefeatKind defeatKind,
  required bool isBoss,
  double? postureCapacity,
}) => Phase0aActor(
  id: id,
  side: Phase0aSide.enemy,
  position: position,
  facing: const ArenaVector(-1, 0),
  maxHealth: health,
  currentHealth: health,
  moveSpeed: 0,
  qiCurrent: 0,
  qiMax: 0,
  attackCooldownRemaining: 0,
  defeatKind: defeatKind,
  isBoss: isBoss,
  posture: postureCapacity == null
      ? null
      : PostureState.initial(
          PostureConfig(
            capacity: postureCapacity,
            vulnerabilityTicks: 3,
            recoveryPolicy: PostureRecoveryPolicy.reset,
            postVulnerabilityAccumulated: 0,
            bossControlConversionFactor: 3,
          ),
        ),
);

List<Phase0aActor> _scenarioEnemies(CandidateScenario scenario) =>
    switch (scenario) {
      CandidateScenario.clear => [
        _enemy(
          id: 'clear_1',
          position: const ArenaVector(80, 0),
          health: 60,
          defeatKind: Phase0aDefeatKind.normal,
          isBoss: false,
        ),
        _enemy(
          id: 'clear_2',
          position: const ArenaVector(85, 25),
          health: 60,
          defeatKind: Phase0aDefeatKind.normal,
          isBoss: false,
        ),
        _enemy(
          id: 'clear_3',
          position: const ArenaVector(85, -25),
          health: 60,
          defeatKind: Phase0aDefeatKind.normal,
          isBoss: false,
        ),
        _enemy(
          id: 'clear_4',
          position: const ArenaVector(95, 45),
          health: 60,
          defeatKind: Phase0aDefeatKind.normal,
          isBoss: false,
        ),
        _enemy(
          id: 'clear_5',
          position: const ArenaVector(95, -45),
          health: 60,
          defeatKind: Phase0aDefeatKind.normal,
          isBoss: false,
        ),
        _enemy(
          id: 'clear_6',
          position: const ArenaVector(110, 0),
          health: 60,
          defeatKind: Phase0aDefeatKind.normal,
          isBoss: false,
        ),
      ],
      CandidateScenario.elite => [
        _enemy(
          id: 'elite',
          position: const ArenaVector(100, 0),
          health: 300,
          defeatKind: Phase0aDefeatKind.elite,
          isBoss: false,
          postureCapacity: 6,
        ),
      ],
      CandidateScenario.boss => [
        _enemy(
          id: 'boss',
          position: const ArenaVector(100, 0),
          health: 900,
          defeatKind: Phase0aDefeatKind.elite,
          isBoss: true,
          postureCapacity: 10,
        ),
      ],
    };

CandidateMetrics _simulate(
  WeaponArchetype archetype,
  CandidateScenario scenario,
) {
  final candidate = _candidates[archetype]!;
  final adapter = _adapter(archetype, candidate);
  var state = Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: _player(),
    enemies: _scenarioEnemies(scenario),
    skillSlots: const [],
  );
  var attacks = 0;
  var hits = 0;
  var defeats = 0;
  var postureWindows = 0;
  var maxHitsPerTick = 0;

  for (var step = 0; step < 400 && state.enemies.isNotEmpty; step++) {
    final target = state.enemies.first;
    final aim = (target.position - state.player.position).normalized();
    final intents = adapter.intentsFor(
      state: state,
      command: Phase0aPlayerCommand(
        attack: true,
        attackAimDirection: aim,
        attackTargetId: target.id,
      ),
    );
    final result = reducePhase0aTick(
      state: state,
      intents: intents,
      deltaSeconds: _fixedDeltaSeconds,
      damageResolver: _CandidateDamageResolver(candidate.resolvedDamage),
    );
    final started = result.events.whereType<Phase0aAttackStarted>().toList();
    final landed = result.events.whereType<Phase0aHitLanded>().toList();
    attacks += started.length;
    hits += landed.length;
    defeats += result.events.whereType<Phase0aEnemyDefeated>().length;
    postureWindows += result.events
        .whereType<Phase0aPostureChanged>()
        .where(
          (event) => event.eventType == PostureEventType.vulnerabilityEntered,
        )
        .length;
    maxHitsPerTick = math.max(maxHitsPerTick, landed.length);
    expect(
      started.every((event) => event.basicAttackSegment == null),
      isTrue,
      reason: '${archetype.name}/${scenario.name} 不得恢复链段身份',
    );
    expect(
      landed.every((event) => event.basicAttackSegment == null),
      isTrue,
      reason: '${archetype.name}/${scenario.name} 命中不得来自三段链',
    );
    state = result.state;
  }

  return (
    victory: state.enemies.isEmpty,
    seconds: state.tick * _fixedDeltaSeconds,
    attacks: attacks,
    hits: hits,
    defeats: defeats,
    postureWindows: postureWindows,
    maxHitsPerTick: maxHitsPerTick,
    finalQi: state.player.qiCurrent,
  );
}

void main() {
  test(
    'M3-CANDIDATE-01 covers five explicit and materially distinct profiles',
    () {
      expect(_candidates.keys.toSet(), WeaponArchetype.values.toSet());
      expect(
        _candidates.values.map((profile) => profile.range).toSet(),
        hasLength(5),
      );
      expect(
        _candidates.values.map((profile) => profile.cooldownSeconds).toSet(),
        hasLength(greaterThanOrEqualTo(4)),
      );
      expect(
        _candidates.values.map((profile) => profile.presentationCue).toSet(),
        hasLength(5),
      );
      expect(
        _candidates.values.every((profile) => profile.maxTargets == 1),
        isTrue,
      );
      expect(
        _candidates.values.every((profile) => profile.attackDisplacement == 0),
        isTrue,
      );
    },
  );

  test('M3-CANDIDATE-02 runs the 5 x 3 matrix through adapter and reducer', () {
    final matrix =
        <WeaponArchetype, Map<CandidateScenario, CandidateMetrics>>{};
    for (final archetype in WeaponArchetype.values) {
      matrix[archetype] = {
        for (final scenario in CandidateScenario.values)
          scenario: _simulate(archetype, scenario),
      };
    }

    expect(matrix, hasLength(5));
    expect(matrix.values.expand((row) => row.values), hasLength(15));
    for (final entry in matrix.entries) {
      final archetype = entry.key;
      for (final cell in entry.value.entries) {
        final scenario = cell.key;
        final metrics = cell.value;
        debugPrint(
          'M3_SINGLE ${archetype.name}/${scenario.name} '
          'victory=${metrics.victory} '
          'seconds=${metrics.seconds.toStringAsFixed(1)} '
          'attacks=${metrics.attacks} hits=${metrics.hits} '
          'defeats=${metrics.defeats} '
          'postureWindows=${metrics.postureWindows} '
          'maxHitsPerTick=${metrics.maxHitsPerTick} finalQi=${metrics.finalQi}',
        );
        expect(metrics.victory, isTrue);
        expect(metrics.attacks, metrics.hits);
        expect(metrics.finalQi, metrics.attacks);
        expect(metrics.maxHitsPerTick, 1);
        expect(metrics.defeats, scenario == CandidateScenario.clear ? 6 : 1);
        expect(
          metrics.seconds,
          lessThanOrEqualTo(switch (scenario) {
            CandidateScenario.clear => 12,
            CandidateScenario.elite => 10,
            CandidateScenario.boss => 25,
          }),
        );
      }
    }
  });
}
