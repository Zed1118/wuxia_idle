import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/phase0a_skill_behavior.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_mapping.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';

import '../../../../support/combatant_snapshot_fixture.dart';

const _basicSkill = SkillDef(
  id: 'r17_basic',
  name: 'r17_basic',
  description: 'r17_basic',
  type: SkillType.normalAttack,
  powerMultiplier: 100,
  qiDelta: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: '',
);

const _numericSkill = SkillDef(
  id: 'r17_numeric',
  name: 'r17_numeric',
  description: 'r17_numeric',
  type: SkillType.powerSkill,
  powerMultiplier: 100,
  qiDelta: -1,
  cooldownTurns: 1,
  requiresManualTrigger: true,
  visualEffect: '',
);

SkillDef _tacticalSkill(String id, Phase0aSkillEffectType effect) => SkillDef(
  id: id,
  name: id,
  description: id,
  type: SkillType.powerSkill,
  powerMultiplier: 100,
  qiDelta: -1,
  cooldownSeconds: 1,
  cooldownTurns: 1,
  requiresManualTrigger: true,
  visualEffect: '',
  source: SkillSource.special,
  targetType: TargetType.aoe,
  phase0aBehavior: Phase0aSkillBehavior(
    geometry: const Phase0aSkillGeometry(
      shape: Phase0aSkillGeometryShape.radial,
      anchor: Phase0aSkillGeometryAnchor.caster,
      radius: 10,
    ),
    effects: [Phase0aSkillEffect(type: effect)],
  ),
);

final _gatherSkill = _tacticalSkill(
  'r17_gather',
  Phase0aSkillEffectType.damage,
);
final _clearSkill = _tacticalSkill('r17_clear', Phase0aSkillEffectType.stagger);

const _playerAdapter = Phase0aPlayerInputAdapter(
  playerId: 'player',
  attackRange: 1,
  attackHalfArcRadians: 1,
  attackCooldownSeconds: 1,
  attackQiDelta: 0,
  gatherSlot: 'gather',
  gatherRingRadius: 1,
  gatherEffectRadius: 1,
  gatherQiCost: 0,
  gatherCooldownSeconds: 1,
  clearSlot: 'clear',
  clearEffectRadius: 1,
  clearQiCost: 0,
  clearCooldownSeconds: 1,
);

const _enemyAdapter = Phase0aEnemyAiAdapter(
  attackRange: 1,
  attackHalfArcRadians: 1,
  attackCooldownSeconds: 1,
);

Phase0aActor _actor({
  required String id,
  required Phase0aSide side,
  int currentHealth = 100,
}) => Phase0aActor(
  id: id,
  side: side,
  position: ArenaVector.zero,
  facing: side == Phase0aSide.player
      ? const ArenaVector(1, 0)
      : const ArenaVector(-1, 0),
  maxHealth: 100,
  currentHealth: currentHealth,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aArenaState _initialState() => Phase0aArenaState(
  tick: 0,
  nextSeq: 1,
  player: _actor(id: 'player', side: Phase0aSide.player),
  enemies: const [],
  skillSlots: const [],
);

Phase0aArenaState _finalState({Phase0aActor? player}) => Phase0aArenaState(
  tick: 12,
  nextSeq: 20,
  player:
      player ??
      _actor(id: 'player', side: Phase0aSide.player, currentHealth: 80),
  enemies: [
    _actor(id: 'enemy_active', side: Phase0aSide.enemy, currentHealth: 35),
  ],
  skillSlots: const [],
);

List<Phase0aCombatantInput> _combatants() => [
  Phase0aCombatantInput(
    actorId: 'player',
    snapshot: testCombatantSnapshot(
      characterId: 1,
      maxHp: 100,
      skillLoadout: const CombatantSkillLoadout(
        basicAttack: _basicSkill,
        main1: _numericSkill,
      ),
      availableSkills: const [_numericSkill],
    ),
  ),
  Phase0aCombatantInput(
    actorId: 'enemy_active',
    snapshot: testCombatantSnapshot(characterId: 2, maxHp: 100),
  ),
  Phase0aCombatantInput(
    actorId: 'enemy_exited',
    snapshot: testCombatantSnapshot(characterId: 3, maxHp: 100),
  ),
  Phase0aCombatantInput(
    actorId: 'enemy_reserve',
    snapshot: testCombatantSnapshot(characterId: 4, maxHp: 100),
  ),
];

Map<Phase0aDamageKind, SkillDef?> _moveBindings() => {
  Phase0aDamageKind.basic: _basicSkill,
  Phase0aDamageKind.gather: _gatherSkill,
  Phase0aDamageKind.clear: _clearSkill,
};

Phase0aStageMapping _legacyMapping({
  required List<Phase0aCombatantInput> combatants,
  required Map<Phase0aDamageKind, SkillDef?> moveBindings,
}) => Phase0aStageMapping(
  initialState: _initialState(),
  waves: [
    Phase0aWave(
      enemies: [
        _actor(id: 'enemy_active', side: Phase0aSide.enemy),
        _actor(id: 'enemy_exited', side: Phase0aSide.enemy),
        _actor(id: 'enemy_reserve', side: Phase0aSide.enemy),
      ],
    ),
  ],
  combatants: combatants,
  moveBindings: moveBindings,
  playerAdapter: _playerAdapter,
  enemyAiAdapter: _enemyAdapter,
);

Phase0aEncounterMapping _encounterMapping({
  required List<Phase0aCombatantInput> combatants,
  required Map<Phase0aDamageKind, SkillDef?> moveBindings,
}) {
  final director = SpawnDirector(
    config: SpawnDirectorConfig(
      activeLimit: 1,
      reinforcementThreshold: 0,
      entryWarningTicks: 0,
      attackGraceTicks: 0,
    ),
    entries: [
      SpawnEntry(entryId: 'active', enemyId: 'enemy_active'),
      SpawnEntry(entryId: 'exited', enemyId: 'enemy_exited'),
      SpawnEntry(entryId: 'reserve', enemyId: 'enemy_reserve'),
    ],
  );
  final roster = Phase0aEncounterRoster(
    director: director,
    playerId: 'player',
    bindings: [
      Phase0aEncounterRosterBinding(
        entryId: 'active',
        actor: _actor(id: 'enemy_active', side: Phase0aSide.enemy),
      ),
      Phase0aEncounterRosterBinding(
        entryId: 'exited',
        actor: _actor(id: 'enemy_exited', side: Phase0aSide.enemy),
      ),
      Phase0aEncounterRosterBinding(
        entryId: 'reserve',
        actor: _actor(id: 'enemy_reserve', side: Phase0aSide.enemy),
      ),
    ],
  );
  return Phase0aEncounterMapping(
    initialState: _initialState(),
    director: director,
    roster: roster,
    combatants: combatants,
    moveBindings: moveBindings,
    playerAdapter: _playerAdapter,
    enemyAiAdapter: _enemyAdapter,
  );
}

List<Phase0aEvent> _events() => List<Phase0aEvent>.of(const [
  Phase0aAttackStarted(
    seq: 1,
    tick: 1,
    actor: 'player',
    moveKind: Phase0aMoveKind.light,
  ),
  Phase0aHitLanded(
    seq: 2,
    tick: 1,
    actor: 'player',
    target: 'enemy_active',
    moveKind: Phase0aMoveKind.light,
    isCritical: false,
    isUltimate: false,
    resolvedDamage: 10,
    remainingHealth: 90,
  ),
  Phase0aGatherStarted(seq: 3, tick: 2, actor: 'player', skillId: 'r17_gather'),
  Phase0aGatherApplied(
    seq: 4,
    tick: 2,
    actor: 'player',
    outcomes: [
      Phase0aSkillOutcome(
        target: 'enemy_active',
        resolvedDamage: 5,
        isCritical: true,
        defeated: false,
        statusApplied: Phase0aSkillStatus.none,
      ),
    ],
  ),
  Phase0aClearStarted(seq: 5, tick: 3, actor: 'player', skillId: 'r17_clear'),
  Phase0aClearApplied(
    seq: 6,
    tick: 3,
    actor: 'player',
    outcomes: [
      Phase0aSkillOutcome(
        target: 'enemy_active',
        resolvedDamage: 7,
        isCritical: false,
        defeated: false,
        statusApplied: Phase0aSkillStatus.staggered,
      ),
    ],
  ),
  Phase0aSkillStarted(
    seq: 7,
    tick: 4,
    actor: 'player',
    hotkey: 1,
    skillId: 'r17_numeric',
  ),
  Phase0aSkillApplied(
    seq: 8,
    tick: 4,
    actor: 'player',
    hotkey: 1,
    skillId: 'r17_numeric',
    outcomes: [
      Phase0aSkillOutcome(
        target: 'enemy_active',
        resolvedDamage: 11,
        isCritical: true,
        defeated: false,
        statusApplied: Phase0aSkillStatus.none,
      ),
    ],
  ),
  Phase0aHitLanded(
    seq: 9,
    tick: 5,
    actor: 'enemy_active',
    target: 'player',
    moveKind: Phase0aMoveKind.light,
    isCritical: false,
    isUltimate: false,
    resolvedDamage: 13,
    remainingHealth: 87,
  ),
  Phase0aHitLanded(
    seq: 10,
    tick: 5,
    actor: 'unmapped_actor',
    target: 'player',
    moveKind: Phase0aMoveKind.light,
    isCritical: true,
    isUltimate: false,
    resolvedDamage: 17,
    remainingHealth: 70,
  ),
]);

List<(int, int, int)> _participants(CombatSettlementSnapshot snapshot) => [
  for (final participant in snapshot.participants)
    (participant.characterId, participant.currentHp, participant.maxHp),
];

List<(int, int, String)> _casts(CombatSettlementSnapshot snapshot) => [
  for (final cast in snapshot.skillCasts)
    (cast.tick, cast.characterId, cast.skillId),
];

void _expectSameSettlement(
  CombatSettlementSnapshot legacy,
  CombatSettlementSnapshot encounter,
) {
  expect(encounter.result, legacy.result);
  expect(encounter.totalTicks, legacy.totalTicks);
  expect(encounter.hadActions, legacy.hadActions);
  expect(_participants(encounter), _participants(legacy));
  expect(_casts(encounter), _casts(legacy));
  expect(encounter.totalDamage, legacy.totalDamage);
  expect(encounter.criticalCount, legacy.criticalCount);
  expect(encounter.damageByCharacterId, legacy.damageByCharacterId);
}

void main() {
  test('encounter and legacy mappings settle every field identically', () {
    final combatants = _combatants();
    final moveBindings = _moveBindings();
    final events = _events();
    final finalState = _finalState();

    final legacy = Phase0aSettlementAdapter.fromMapping(
      mapping: _legacyMapping(
        combatants: combatants,
        moveBindings: moveBindings,
      ),
      outcome: Phase0aBattleOutcome.victory,
      finalState: finalState,
      events: events,
    );
    final encounter = Phase0aSettlementAdapter.fromEncounterMapping(
      mapping: _encounterMapping(
        combatants: combatants,
        moveBindings: moveBindings,
      ),
      outcome: Phase0aBattleOutcome.victory,
      finalState: finalState,
      events: events,
    );

    _expectSameSettlement(legacy, encounter);
    expect(_participants(encounter), [
      (1, 80, 100),
      (2, 35, 100),
      (3, 0, 100),
      (4, 0, 100),
    ]);
    expect(_casts(encounter), [
      (1, 1, 'r17_basic'),
      (2, 1, 'r17_gather'),
      (3, 1, 'r17_clear'),
      (4, 1, 'r17_numeric'),
    ]);
    expect(encounter.totalDamage, 63);
    expect(encounter.criticalCount, 3);
    expect(encounter.damageByCharacterId, {1: 33, 2: 13});
  });

  test('shared core requires exactly one mapped player actor', () {
    final withoutPlayer = _combatants()
      ..removeWhere((combatant) => combatant.actorId == 'player');
    expect(
      () => Phase0aSettlementAdapter.fromEncounterMapping(
        mapping: _encounterMapping(
          combatants: withoutPlayer,
          moveBindings: _moveBindings(),
        ),
        outcome: Phase0aBattleOutcome.victory,
        finalState: _finalState(),
        events: const [],
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('exactly one mapped player actor'),
        ),
      ),
    );

    final duplicatePlayer = _combatants()..add(_combatants().first);
    expect(
      () => Phase0aSettlementAdapter.fromMapping(
        mapping: _legacyMapping(
          combatants: duplicatePlayer,
          moveBindings: _moveBindings(),
        ),
        outcome: Phase0aBattleOutcome.victory,
        finalState: _finalState(),
        events: const [],
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('exactly one mapped player actor'),
        ),
      ),
    );
  });

  test('encounter settlement rejects final player id or side mismatch', () {
    final mapping = _encounterMapping(
      combatants: _combatants(),
      moveBindings: _moveBindings(),
    );
    for (final player in [
      _actor(id: 'impostor', side: Phase0aSide.player),
      _actor(id: 'player', side: Phase0aSide.enemy),
    ]) {
      expect(
        () => Phase0aSettlementAdapter.fromEncounterMapping(
          mapping: mapping,
          outcome: Phase0aBattleOutcome.victory,
          finalState: _finalState(player: player),
          events: const [],
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('player actor mismatch'),
          ),
        ),
      );
    }
  });

  test('encounter settlement rejects an ongoing outcome', () {
    expect(
      () => Phase0aSettlementAdapter.fromEncounterMapping(
        mapping: _encounterMapping(
          combatants: _combatants(),
          moveBindings: _moveBindings(),
        ),
        outcome: Phase0aBattleOutcome.ongoing,
        finalState: _finalState(),
        events: const [],
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Cannot settle an ongoing Phase0a battle',
        ),
      ),
    );
  });

  test('caller collection mutation cannot pollute mapping or settlement', () {
    final callerCombatants = _combatants();
    final callerBindings = _moveBindings();
    final mapping = _encounterMapping(
      combatants: callerCombatants,
      moveBindings: callerBindings,
    );
    callerCombatants.clear();
    callerBindings.clear();

    final callerEvents = _events();
    final settlement = Phase0aSettlementAdapter.fromEncounterMapping(
      mapping: mapping,
      outcome: Phase0aBattleOutcome.victory,
      finalState: _finalState(),
      events: callerEvents,
    );
    callerEvents.clear();

    expect(mapping.combatants, hasLength(4));
    expect(mapping.moveBindings, hasLength(3));
    expect(settlement.totalDamage, 63);
    expect(_casts(settlement), hasLength(4));
    expect(() => mapping.combatants.clear(), throwsUnsupportedError);
    expect(() => mapping.moveBindings.clear(), throwsUnsupportedError);
    expect(() => settlement.participants.clear(), throwsUnsupportedError);
    expect(() => settlement.skillCasts.clear(), throwsUnsupportedError);
    expect(
      () => settlement.damageByCharacterId.clear(),
      throwsUnsupportedError,
    );
  });

  test(
    'adapter source keeps one core and no forbidden integration inference',
    () {
      const sourcePath =
          'lib/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
      final source = File(sourcePath).readAsStringSync();
      final imports = RegExp(
        r"^import '([^']+)';$",
        multiLine: true,
      ).allMatches(source).map((match) => match.group(1)).toList();

      expect(imports, [
        '../../../../data/defs/skill_def.dart',
        '../../../../shared/battle_shared/battle_result.dart',
        '../../../../shared/battle_shared/combat_settlement_snapshot.dart',
        '../../domain/phase0a/phase0a_combat_events.dart',
        '../../domain/phase0a/phase0a_combat_model.dart',
        '../../domain/phase0a/phase0a_combat_reducer.dart',
        '../../domain/phase0a/phase0a_wave.dart',
        'phase0a_battle_snapshot_factory.dart',
        'phase0a_encounter_mapping.dart',
        'phase0a_stage_content_mapper.dart',
      ]);
      for (final forbidden in [
        'route',
        'objective',
        'reward',
        'injury',
        'host',
        'persistence',
        'repository',
        'candidate',
        'tuning',
      ]) {
        expect(
          source,
          isNot(contains(RegExp('\\b$forbidden\\b', caseSensitive: false))),
          reason: forbidden,
        );
      }
      expect(
        RegExp(r'fromEncounterMapping\s*\(').allMatches(source),
        hasLength(1),
      );
      expect(
        RegExp(r'CombatSettlementSnapshot\s*\(').allMatches(source),
        hasLength(1),
      );
      expect(
        RegExp(r'for\s*\(final event in \w*[Ee]vent\w*\)').allMatches(source),
        hasLength(1),
      );
      expect(source, isNot(contains('mapping.director')));
      expect(source, isNot(contains('mapping.roster')));
    },
  );
}
