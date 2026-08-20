import 'dart:math';

import '../../../core/domain/enums.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/numbers_config.dart';
import '../../../data/yaml_loader.dart';
import '../../battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import '../../battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import '../../battle/application/phase0a/phase0a_player_input_adapter.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_wave_battle_flow.dart';
import '../../battle/application/legacy_3v3_combatant_adapter.dart';
import '../../battle/domain/battle_state.dart';
import '../../battle/domain/phase0a/arena_vector.dart';
import '../../battle/domain/phase0a/phase0a_combat_model.dart';
import '../../battle/domain/phase0a/phase0a_combat_reducer.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../../battle/presentation/phase0a/phase0a_visual_roster.dart';

typedef Phase0aDebugAssetLoader = Future<String> Function(String path);

final class Phase0aDebugBattleFixture {
  const Phase0aDebugBattleFixture._({
    required this.flow,
    required this.roster,
    required this.fixedDeltaSeconds,
    required this.seed,
    required this.arenaMin,
    required this.arenaMax,
  });

  static const String assetPath = 'data/phase0a_debug_battle.yaml';

  final Phase0aWaveBattleFlow flow;
  final Phase0aVisualRoster roster;
  final double fixedDeltaSeconds;
  final int seed;
  final ArenaVector arenaMin;
  final ArenaVector arenaMax;

  static Future<Phase0aDebugBattleFixture> load({
    required Phase0aDebugAssetLoader assetLoader,
    required NumbersConfig numbers,
  }) async {
    final config = _DebugBattleConfig.fromYaml(
      parseYamlMap(await assetLoader(assetPath)),
    );
    final roster = Phase0aVisualRoster.debugBattle();
    final playerActor = config.playerActor();
    final waves = config.waves();
    final combatants = config.combatants();
    for (final combatant in combatants) {
      roster.visualFor(combatant.actorId);
    }
    final flow = Phase0aProductionFlowAssembler.assemble(
      initialState: Phase0aArenaState(
        tick: config.initialTick,
        nextSeq: config.initialSeq,
        player: playerActor,
        enemies: waves.first.enemies,
        skillSlots: config.skillSlots(),
      ),
      waves: waves,
      combatants: combatants,
      moveBindings: config.moveBindings(),
      numbers: numbers,
      rng: Random(config.seed),
      playerAdapter: config.playerAdapter(),
      enemyAiAdapter: config.enemyAiAdapter(),
    );
    return Phase0aDebugBattleFixture._(
      flow: flow,
      roster: roster,
      fixedDeltaSeconds: config.fixedDeltaSeconds,
      seed: config.seed,
      arenaMin: config.arenaMin,
      arenaMax: config.arenaMax,
    );
  }
}

final class _DebugBattleConfig {
  _DebugBattleConfig.fromYaml(Map<String, dynamic> yaml)
    : meta = _map(yaml, 'meta'),
      arena = _map(yaml, 'arena'),
      defaults = _map(yaml, 'combat_defaults'),
      player = _map(yaml, 'player'),
      enemyAi = _map(yaml, 'enemy_ai'),
      enemyTemplates = _map(yaml, 'enemy_templates'),
      waveMaps = _mapList(yaml, 'waves') {
    if (waveMaps.isEmpty) {
      throw const FormatException('waves must not be empty');
    }
    if (!(fixedDeltaSeconds.isFinite && fixedDeltaSeconds > 0)) {
      throw const FormatException('fixed_delta_seconds must be positive');
    }
    if (!(arenaMin.x < arenaMax.x && arenaMin.y < arenaMax.y)) {
      throw const FormatException('arena bounds must be ordered');
    }
  }

  final Map<String, dynamic> meta;
  final Map<String, dynamic> arena;
  final Map<String, dynamic> defaults;
  final Map<String, dynamic> player;
  final Map<String, dynamic> enemyAi;
  final Map<String, dynamic> enemyTemplates;
  final List<Map<String, dynamic>> waveMaps;

  int get seed => _integer(meta, 'seed');
  double get fixedDeltaSeconds => _number(meta, 'fixed_delta_seconds');
  int get initialTick => _integer(meta, 'initial_tick');
  int get initialSeq => _integer(meta, 'initial_seq');
  ArenaVector get arenaMin =>
      ArenaVector(_number(arena, 'min_x'), _number(arena, 'min_y'));
  ArenaVector get arenaMax =>
      ArenaVector(_number(arena, 'max_x'), _number(arena, 'max_y'));

  Phase0aActor playerActor() => Phase0aActor(
    id: _text(player, 'id'),
    side: Phase0aSide.player,
    position: _vector(player, 'position'),
    facing: _vector(player, 'facing'),
    maxHealth: _integer(player, 'max_health'),
    currentHealth: _integer(player, 'max_health'),
    moveSpeed: _number(player, 'move_speed'),
    qiCurrent: _integer(player, 'qi'),
    qiMax: _integer(player, 'qi'),
    attackCooldownRemaining: _number(defaults, 'action_point'),
    defeatKind: Phase0aDefeatKind.normal,
  );

  List<Phase0aSkillSlot> skillSlots() {
    final gather = _map(player, 'gather');
    final clear = _map(player, 'clear');
    return List.unmodifiable([
      Phase0aSkillSlot(
        slot: _text(gather, 'slot'),
        cooldownRemaining: _number(defaults, 'action_point'),
        qiCost: _integer(gather, 'qi_cost'),
        availability: Phase0aSkillAvailability.ready,
      ),
      Phase0aSkillSlot(
        slot: _text(clear, 'slot'),
        cooldownRemaining: _number(defaults, 'action_point'),
        qiCost: _integer(clear, 'qi_cost'),
        availability: Phase0aSkillAvailability.ready,
      ),
    ]);
  }

  List<Phase0aWave> waves() => List.unmodifiable([
    for (final wave in waveMaps)
      Phase0aWave(
        enemies: [
          for (final enemy in _mapList(wave, 'enemies')) _enemyActor(enemy),
        ],
      ),
  ]);

  List<Phase0aCombatantInput> combatants() {
    final result = <Phase0aCombatantInput>[
      Phase0aCombatantInput(
        actorId: _text(player, 'id'),
        snapshot: Legacy3v3CombatantAdapter.toSnapshot(
          _character(player, isPlayer: true),
        ),
      ),
    ];
    for (final wave in waveMaps) {
      for (final enemy in _mapList(wave, 'enemies')) {
        result.add(
          Phase0aCombatantInput(
            actorId: _text(enemy, 'id'),
            snapshot: Legacy3v3CombatantAdapter.toSnapshot(
              _character(enemy, isPlayer: false),
            ),
          ),
        );
      }
    }
    return List.unmodifiable(result);
  }

  Map<Phase0aDamageKind, SkillDef?> moveBindings() {
    final attack = _map(player, 'attack');
    final clear = _map(player, 'clear');
    return Map.unmodifiable({
      Phase0aDamageKind.basic: _skill(
        id: 'phase0a_debug_basic',
        multiplier: _integer(attack, 'power_multiplier'),
        qiDelta: _integer(defaults, 'basic_qi_delta'),
      ),
      Phase0aDamageKind.gather: null,
      Phase0aDamageKind.clear: _skill(
        id: 'phase0a_debug_clear',
        multiplier: _integer(clear, 'power_multiplier'),
        qiDelta: _integer(defaults, 'clear_qi_delta'),
      ),
    });
  }

  Phase0aPlayerInputAdapter playerAdapter() {
    final attack = _map(player, 'attack');
    final gather = _map(player, 'gather');
    final clear = _map(player, 'clear');
    return Phase0aPlayerInputAdapter(
      playerId: _text(player, 'id'),
      attackRange: _number(attack, 'range'),
      attackHalfArcRadians: _number(attack, 'half_arc_radians'),
      attackCooldownSeconds: _number(attack, 'cooldown_seconds'),
      gatherSlot: _text(gather, 'slot'),
      gatherRingRadius: _number(gather, 'ring_radius'),
      gatherEffectRadius: _number(gather, 'effect_radius'),
      gatherQiCost: _integer(gather, 'qi_cost'),
      gatherCooldownSeconds: _number(gather, 'cooldown_seconds'),
      clearSlot: _text(clear, 'slot'),
      clearEffectRadius: _number(clear, 'effect_radius'),
      clearQiCost: _integer(clear, 'qi_cost'),
      clearCooldownSeconds: _number(clear, 'cooldown_seconds'),
    );
  }

  Phase0aEnemyAiAdapter enemyAiAdapter() => Phase0aEnemyAiAdapter(
    attackRange: _number(enemyAi, 'attack_range'),
    attackHalfArcRadians: _number(enemyAi, 'attack_half_arc_radians'),
    attackCooldownSeconds: _number(enemyAi, 'attack_cooldown_seconds'),
  );

  Phase0aActor _enemyActor(Map<String, dynamic> enemy) {
    final template = _enemyTemplate(enemy);
    final hp = _integer(enemy, 'max_health');
    final elite = _text(enemy, 'role') == 'elite';
    return Phase0aActor(
      id: _text(enemy, 'id'),
      side: Phase0aSide.enemy,
      position: _vector(enemy, 'position'),
      facing: const ArenaVector(-1, 0),
      maxHealth: hp,
      currentHealth: hp,
      moveSpeed: _number(template, 'move_speed'),
      qiCurrent: _integer(template, 'qi'),
      qiMax: _integer(template, 'qi'),
      attackCooldownRemaining: _number(template, 'initial_attack_cooldown'),
      defeatKind: elite ? Phase0aDefeatKind.elite : Phase0aDefeatKind.normal,
    );
  }

  BattleCharacter _character(
    Map<String, dynamic> actor, {
    required bool isPlayer,
  }) {
    final stats = isPlayer ? actor : _enemyTemplate(actor);
    final hp = _integer(actor, 'max_health');
    final qi = _integer(stats, 'qi');
    return BattleCharacter(
      characterId: _integer(actor, 'character_id'),
      name: _text(actor, 'id'),
      realmTier: RealmTier.values.byName(_text(defaults, 'realm_tier')),
      realmLayer: RealmLayer.values.byName(_text(defaults, 'realm_layer')),
      school: TechniqueSchool.values.byName(
        _text(defaults, isPlayer ? 'player_school' : 'enemy_school'),
      ),
      maxHp: hp,
      currentHp: hp,
      internalForce: _integer(stats, 'internal_force'),
      maxQi: qi,
      currentQi: qi,
      speed: _number(stats, 'move_speed').round(),
      criticalRate: _number(stats, 'critical_rate'),
      evasionRate: _number(stats, 'evasion_rate'),
      defenseRate: _number(stats, 'defense_rate'),
      totalEquipmentAttack: _integer(stats, 'equipment_attack'),
      mainCultivationLayer: CultivationLayer.values.byName(
        _text(defaults, 'cultivation_layer'),
      ),
      availableSkills: const [],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: _integer(defaults, 'action_point'),
      isAlive: true,
      teamSide: _integer(
        defaults,
        isPlayer ? 'player_team_side' : 'enemy_team_side',
      ),
      slotIndex: isPlayer
          ? _integer(defaults, 'player_slot_index')
          : _integer(actor, 'slot_index'),
      attackPowerMultiplier: _number(defaults, 'attack_power_multiplier'),
      outputMultiplier: _number(defaults, 'output_multiplier'),
      forgingPiercePct: _number(defaults, 'forging_pierce_pct'),
      forgingLifestealPct: _number(defaults, 'forging_lifesteal_pct'),
    );
  }

  Map<String, dynamic> _enemyTemplate(Map<String, dynamic> enemy) {
    final role = _text(enemy, 'role');
    final template = enemyTemplates[role];
    if (template is! Map) {
      throw FormatException('Missing enemy template: $role');
    }
    return Map<String, dynamic>.from(template);
  }

  SkillDef _skill({
    required String id,
    required int multiplier,
    required int qiDelta,
  }) => SkillDef(
    id: id,
    name: id,
    description: id,
    type: SkillType.normalAttack,
    powerMultiplier: multiplier,
    qiDelta: qiDelta,
    cooldownTurns: _integer(defaults, 'skill_cooldown_turns'),
    requiresManualTrigger: false,
    visualEffect: '',
  );
}

Map<String, dynamic> _map(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! Map) throw FormatException('$key must be a map');
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _mapList(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! List) throw FormatException('$key must be a list');
  return [
    for (final item in value)
      if (item is Map)
        Map<String, dynamic>.from(item)
      else
        throw FormatException('$key entries must be maps'),
  ];
}

String _text(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string');
  }
  return value;
}

double _number(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! num) throw FormatException('$key must be numeric');
  return value.toDouble();
}

int _integer(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! num || value.toInt() != value) {
    throw FormatException('$key must be an integer');
  }
  return value.toInt();
}

ArenaVector _vector(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! List ||
      value.length != 2 ||
      value.any((item) => item is! num)) {
    throw FormatException('$key must contain two numbers');
  }
  return ArenaVector(
    (value[0] as num).toDouble(),
    (value[1] as num).toDouble(),
  );
}
