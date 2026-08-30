import 'dart:math';

import '../../../core/domain/enums.dart';
import '../../../data/defs/phase0a_skill_behavior.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/numbers_config.dart';
import '../../../data/yaml_loader.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import '../../battle/application/phase0a/phase0a_defense_tuning_mapper.dart';
import '../../battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import '../../battle/application/phase0a/phase0a_enemy_skill_binding.dart';
import '../../battle/application/phase0a/phase0a_player_input_adapter.dart';
import '../../battle/application/phase0a/phase0a_tactical_skill_binding.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_wave_battle_flow.dart';
import '../../battle/domain/phase0a/arena_vector.dart';
import '../../battle/domain/phase0a/phase0a_combat_model.dart';
import '../../battle/domain/phase0a/phase0a_combat_reducer.dart';
import '../../battle/domain/phase0a/phase0a_defense_tuning.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../../battle/domain/phase0a/posture.dart';
import '../../battle/presentation/phase0a/phase0a_visual_roster.dart';

typedef Phase0aDebugAssetLoader = Future<String> Function(String path);

// Legacy debug YAML without a bound Q skill carries no skill power. This is an
// absence sentinel for the fixture adapter, not a gameplay tuning value.
const _noSkillPowerMultiplier = 0;

final class Phase0aDebugBattleFixture {
  const Phase0aDebugBattleFixture._({
    required this.flow,
    required this.roster,
    required this.fixedDeltaSeconds,
    required this.seed,
    required this.arenaMin,
    required this.arenaMax,
    required this.playerAdapter,
    required _DebugBattleConfig config,
    required NumbersConfig numbers,
  }) : _config = config,
       _numbers = numbers;

  static const String assetPath = 'data/phase0a_debug_battle.yaml';

  final Phase0aWaveBattleFlow flow;
  final Phase0aVisualRoster roster;
  final double fixedDeltaSeconds;
  final int seed;
  final ArenaVector arenaMin;
  final ArenaVector arenaMax;
  final Phase0aPlayerInputAdapter playerAdapter;
  final _DebugBattleConfig _config;
  final NumbersConfig _numbers;

  static Future<Phase0aDebugBattleFixture> load({
    required Phase0aDebugAssetLoader assetLoader,
    required NumbersConfig numbers,
    String assetPath = Phase0aDebugBattleFixture.assetPath,
  }) async {
    final config = _DebugBattleConfig.fromYaml(
      parseYamlMap(await assetLoader(assetPath)),
    );
    return _fromConfig(config, numbers);
  }

  /// Rebuilds mutable combat state from the parsed fixture configuration.
  /// Profile loops avoid repeated YAML I/O/parsing at battle boundaries so
  /// debug-only allocation spikes do not contaminate production-frame data.
  Phase0aDebugBattleFixture fresh() => _fromConfig(_config, _numbers);

  /// Builds the bounded restart pool before profile sampling begins. The Gate
  /// runs for 102 seconds, so four deterministic flows cover every expected
  /// battle boundary without assembling debug fixtures on a measured frame.
  List<Phase0aDebugBattleFixture> prewarmRestartPool({int count = 4}) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must not be negative');
    }
    return List<Phase0aDebugBattleFixture>.generate(count, (_) => fresh());
  }

  static Phase0aDebugBattleFixture _fromConfig(
    _DebugBattleConfig config,
    NumbersConfig numbers,
  ) {
    final roster = Phase0aVisualRoster.debugBattle();
    final playerActor = config.playerActor();
    final waves = config.waves(numbers);
    final combatants = config.combatants();
    for (final combatant in combatants) {
      roster.visualFor(combatant.actorId);
    }
    final defenseTuning = Phase0aDefenseTuningMapper.fromNumbers(numbers);
    final playerAdapter = config.playerAdapter(
      numbers,
      defenseTuning: defenseTuning,
    );
    final flow = Phase0aProductionFlowAssembler.assemble(
      initialState: Phase0aArenaState(
        tick: config.initialTick,
        nextSeq: config.initialSeq,
        player: playerActor,
        enemies: waves.first.enemies,
        skillSlots: config.skillSlots(),
        winCondition: config.winCondition,
      ),
      waves: waves,
      combatants: combatants,
      moveBindings: config.moveBindings(),
      numbers: numbers,
      rng: Random(config.seed),
      playerAdapter: playerAdapter,
      enemyAiAdapter: config.enemyAiAdapter(
        numbers,
        defenseTuning: defenseTuning,
      ),
    );
    return Phase0aDebugBattleFixture._(
      flow: flow,
      roster: roster,
      fixedDeltaSeconds: config.fixedDeltaSeconds,
      seed: config.seed,
      arenaMin: config.arenaMin,
      arenaMax: config.arenaMax,
      playerAdapter: playerAdapter,
      config: config,
      numbers: numbers,
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
      winCondition = _optionalWinCondition(yaml['win_condition']),
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
  final Phase0aWinCondition? winCondition;
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

  List<Phase0aWave> waves(NumbersConfig numbers) => List.unmodifiable([
    for (final wave in waveMaps)
      Phase0aWave(
        enemies: [
          for (final enemy in _mapList(wave, 'enemies'))
            _enemyActor(enemy, numbers),
        ],
      ),
  ]);

  List<Phase0aCombatantInput> combatants() {
    final result = <Phase0aCombatantInput>[
      Phase0aCombatantInput(
        actorId: _text(player, 'id'),
        snapshot: _combatantSnapshot(player, isPlayer: true),
      ),
    ];
    for (final wave in waveMaps) {
      for (final enemy in _mapList(wave, 'enemies')) {
        result.add(
          Phase0aCombatantInput(
            actorId: _text(enemy, 'id'),
            snapshot: _combatantSnapshot(enemy, isPlayer: false),
          ),
        );
      }
    }
    return List.unmodifiable(result);
  }

  Map<Phase0aDamageKind, SkillDef?> moveBindings() {
    final attack = _map(player, 'attack');
    final clear = _clearSkill();
    final tactical = _tacticalSkills();
    return Map.unmodifiable({
      Phase0aDamageKind.basic: _skill(
        id: 'phase0a_debug_basic',
        multiplier: _integer(attack, 'power_multiplier'),
        qiDelta: _integer(defaults, 'basic_qi_delta'),
      ),
      Phase0aDamageKind.gather: tactical?.gather.skill,
      Phase0aDamageKind.clear: clear,
    });
  }

  Phase0aPlayerInputAdapter playerAdapter(
    NumbersConfig numbers, {
    required Phase0aDefenseTuning? defenseTuning,
  }) {
    final attack = _map(player, 'attack');
    final gather = _map(player, 'gather');
    final clear = _map(player, 'clear');
    final tactical = _tacticalSkills();
    return Phase0aPlayerInputAdapter(
      playerId: _text(player, 'id'),
      attackRange: _number(attack, 'range'),
      attackHalfArcRadians: _number(attack, 'half_arc_radians'),
      attackCooldownSeconds: _number(attack, 'cooldown_seconds'),
      attackQiDelta: _integer(defaults, 'basic_qi_delta'),
      postureBasicPowerMultiplier: numbers.phase0aArena.basicPowerMultiplier,
      attackPowerMultiplier: _integer(attack, 'power_multiplier'),
      gatherPowerMultiplier:
          tactical?.gather.skill.powerMultiplier ?? _noSkillPowerMultiplier,
      clearPowerMultiplier: _integer(clear, 'power_multiplier'),
      gatherSlot: _text(gather, 'slot'),
      gatherRingRadius: _number(gather, 'ring_radius'),
      gatherEffectRadius: _number(gather, 'effect_radius'),
      gatherQiCost: _integer(gather, 'qi_cost'),
      gatherCooldownSeconds: _number(gather, 'cooldown_seconds'),
      clearSlot: _text(clear, 'slot'),
      clearEffectRadius: _number(clear, 'effect_radius'),
      clearQiCost: _integer(clear, 'qi_cost'),
      clearCooldownSeconds: _number(clear, 'cooldown_seconds'),
      gatherSkillBinding: tactical?.gather,
      clearSkillBinding: tactical?.clear,
      defenseTuning: defenseTuning,
    );
  }

  Phase0aEnemyAiAdapter enemyAiAdapter(
    NumbersConfig numbers, {
    required Phase0aDefenseTuning? defenseTuning,
  }) => Phase0aEnemyAiAdapter(
    attackRange: _number(enemyAi, 'attack_range'),
    attackHalfArcRadians: _number(enemyAi, 'attack_half_arc_radians'),
    attackCooldownSeconds: _number(enemyAi, 'attack_cooldown_seconds'),
    postureBasicPowerMultiplier: numbers.phase0aArena.basicPowerMultiplier,
    basicPowerMultiplierByActor: {
      for (final wave in waveMaps)
        for (final enemy in _mapList(wave, 'enemies'))
          _text(enemy, 'id'): _integer(
            _map(player, 'attack'),
            'power_multiplier',
          ),
    },
    skillBindingsByActor: {
      for (final wave in waveMaps)
        for (final enemy in _mapList(wave, 'enemies'))
          if (_bossSkill(enemy) case final SkillDef skill)
            _text(enemy, 'id'): [
              Phase0aEnemySkillBinding(
                skill: skill,
                attackRange: _number(enemyAi, 'attack_range'),
                halfArcRadians: _number(enemyAi, 'attack_half_arc_radians'),
                effectRadius: _number(enemyAi, 'attack_range'),
                cooldownSeconds: _number(enemyAi, 'attack_cooldown_seconds'),
              ),
            ],
    },
    defenseTuning: defenseTuning,
  );

  Phase0aActor _enemyActor(Map<String, dynamic> enemy, NumbersConfig numbers) {
    final template = _enemyTemplate(enemy);
    final hp = _integer(enemy, 'max_health');
    final role = _text(enemy, 'role');
    final bossConfig = role == 'boss' ? _map(enemy, 'boss') : null;
    final chargeSkill = _bossSkill(enemy);
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
      defeatKind: role == 'elite' || role == 'boss'
          ? Phase0aDefeatKind.elite
          : Phase0aDefeatKind.normal,
      isBoss: role == 'boss',
      chargeCast: chargeSkill == null
          ? null
          : Phase0aChargeCast(
              skill: chargeSkill,
              chargeTicks: _integer(bossConfig!, 'charge_ticks'),
              attackRange: _number(enemyAi, 'attack_range'),
              halfArcRadians: _number(enemyAi, 'attack_half_arc_radians'),
              effectRadius: _number(enemyAi, 'attack_range'),
              cooldownSeconds: _number(enemyAi, 'attack_cooldown_seconds'),
              actionCooldownSeconds: _number(
                enemyAi,
                'attack_cooldown_seconds',
              ),
              postureDamage: powerMultiplierToPostureDamage(
                chargeSkill.powerMultiplier,
                basicPowerMultiplier: numbers.phase0aArena.basicPowerMultiplier,
              ),
              postureHitKind: PostureHitKind.heavy,
            ),
      staggerTicksTotal: bossConfig == null
          ? 0
          : _integer(bossConfig, 'stagger_ticks'),
      vulnerabilityMult: bossConfig == null
          ? null
          : _number(bossConfig, 'vulnerability_mult'),
      guardianWardMult: bossConfig == null
          ? null
          : _optionalNumber(bossConfig, 'guardian_ward_mult'),
      guardianDefIds: bossConfig == null
          ? const []
          : _optionalStringList(bossConfig, 'guardian_ids'),
      guardInterceptsInterrupt:
          bossConfig != null &&
          _optionalBool(bossConfig, 'guard_intercepts_interrupt'),
      posture: PostureState.initial(
        PostureConfig(
          capacity: numbers.combat.posture.capacity,
          vulnerabilityTicks: numbers.combat.posture.vulnerabilityTicks,
          recoveryPolicy:
              numbers.combat.posture.recoveryPolicy ==
                  PostureRecoveryPolicyConfig.reset
              ? PostureRecoveryPolicy.reset
              : PostureRecoveryPolicy.recover,
          postVulnerabilityAccumulated:
              numbers.combat.posture.postVulnerabilityAccumulated,
          bossControlConversionFactor:
              numbers.combat.posture.bossConversionFactor,
        ),
      ),
    );
  }

  CombatantSnapshot _combatantSnapshot(
    Map<String, dynamic> actor, {
    required bool isPlayer,
  }) {
    final stats = isPlayer ? actor : _enemyTemplate(actor);
    final hp = _integer(actor, 'max_health');
    final qi = _integer(stats, 'qi');
    final boss = !isPlayer && _text(actor, 'role') == 'boss';
    final bossSkill = boss ? _bossSkill(actor) : null;
    return CombatantSnapshot(
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
      qiGainMultiplier: 1,
      qiCostReductionPct: 0,
      autoUltimate: false,
      speed: _number(stats, 'move_speed').round(),
      criticalRate: _number(stats, 'critical_rate'),
      evasionRate: _number(stats, 'evasion_rate'),
      defenseRate: _number(stats, 'defense_rate'),
      totalEquipmentAttack: _integer(stats, 'equipment_attack'),
      mainCultivationLayer: CultivationLayer.values.byName(
        _text(defaults, 'cultivation_layer'),
      ),
      availableSkills: bossSkill == null ? const [] : [bossSkill],
      openingSkillCooldowns: const {},
      skillUses: const {},
      activeBuffs: const [],
      swordSongResonanceActive: false,
      iconPath: null,
      attackPowerMultiplier: _number(defaults, 'attack_power_multiplier'),
      outputMultiplier: _number(defaults, 'output_multiplier'),
      isBoss: boss,
      chargeSkillId: bossSkill?.id,
      bossPhases: null,
      bossPhaseUnlockSkills: null,
      schoolDamageTakenMult: const {},
      lineageRole: null,
      forgingPiercePct: _number(defaults, 'forging_pierce_pct'),
      forgingLifestealPct: _number(defaults, 'forging_lifesteal_pct'),
      enemyDefId: isPlayer ? null : _text(actor, 'id'),
      guardianWardMult: boss && _map(actor, 'boss')['guardian_ward_mult'] is num
          ? _number(_map(actor, 'boss'), 'guardian_ward_mult')
          : null,
      guardianDefIds: boss
          ? _optionalStringList(_map(actor, 'boss'), 'guardian_ids')
          : const [],
      vulnerabilityMult: boss
          ? _number(_map(actor, 'boss'), 'vulnerability_mult')
          : null,
      guardInterceptsInterrupt:
          boss &&
          _optionalBool(_map(actor, 'boss'), 'guard_intercepts_interrupt'),
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

  SkillDef? _bossSkill(Map<String, dynamic> enemy) {
    if (_text(enemy, 'role') != 'boss') return null;
    return _skillFromMap(_map(_map(enemy, 'boss'), 'charge_skill'));
  }

  SkillDef _clearSkill() {
    final clear = _map(player, 'clear');
    final behavior = clear['phase0a_behavior'];
    if (behavior is! Map) {
      return _skill(
        id: 'phase0a_debug_clear',
        multiplier: _integer(clear, 'power_multiplier'),
        qiDelta: _integer(defaults, 'clear_qi_delta'),
      );
    }
    return _skillFromMap({
      'id': 'phase0a_debug_clear',
      'name': 'phase0a_debug_clear',
      'description': 'phase0a_debug_clear',
      'type': 'normalAttack',
      'power_multiplier': _integer(clear, 'power_multiplier'),
      'qi_delta': _integer(defaults, 'clear_qi_delta'),
      'cooldown_turns': _integer(defaults, 'skill_cooldown_turns'),
      'cooldown_seconds': _number(clear, 'cooldown_seconds'),
      'phase0a_behavior': behavior,
      'target_type': 'aoe',
      'source': 'special',
    });
  }

  _DebugTacticalSkills? _tacticalSkills() {
    final gather = _map(player, 'gather')['phase0a_behavior'];
    final clear = _map(player, 'clear')['phase0a_behavior'];
    if (gather is! Map && clear is! Map) return null;
    if (gather is! Map || clear is! Map) {
      throw const FormatException(
        'phase0a tactical gather and clear behaviors must be paired',
      );
    }
    final gatherMap = <String, dynamic>{
      'id': 'phase0a_debug_gather',
      'name': 'phase0a_debug_gather',
      'description': 'phase0a_debug_gather',
      'type': 'normalAttack',
      'power_multiplier': 0,
      'qi_delta': -_integer(_map(player, 'gather'), 'qi_cost'),
      'cooldown_turns': _integer(_map(player, 'gather'), 'cooldown_seconds'),
      'cooldown_seconds': _number(_map(player, 'gather'), 'cooldown_seconds'),
      'phase0a_behavior': gather,
      'target_type': 'aoe',
      'source': 'special',
    };
    return _DebugTacticalSkills(
      gather: Phase0aTacticalSkillBinding(
        kind: Phase0aTacticalSkillKind.gather,
        slot: _text(_map(player, 'gather'), 'slot'),
        skill: _skillFromMap(gatherMap),
      ),
      clear: Phase0aTacticalSkillBinding(
        kind: Phase0aTacticalSkillKind.clear,
        slot: _text(_map(player, 'clear'), 'slot'),
        skill: _clearSkill(),
      ),
    );
  }

  SkillDef _skillFromMap(Map<String, dynamic> raw) {
    final behavior = raw['phase0a_behavior'];
    return SkillDef(
      id: _text(raw, 'id'),
      name: _text(raw, 'name'),
      description: _text(raw, 'description'),
      type: SkillType.values.byName(raw['type'] as String),
      powerMultiplier: _integer(raw, 'power_multiplier'),
      qiDelta: _integer(raw, 'qi_delta'),
      cooldownTurns: _integer(raw, 'cooldown_turns'),
      cooldownSeconds: behavior is Map
          ? _number(raw, 'cooldown_seconds')
          : _optionalNumber(raw, 'cooldown_seconds'),
      requiresManualTrigger: false,
      visualEffect: '',
      source: raw['source'] == null
          ? null
          : SkillSource.values.byName(raw['source'] as String),
      targetType: raw['target_type'] == null
          ? TargetType.single
          : TargetType.values.byName(raw['target_type'] as String),
      phase0aBehavior: behavior is Map
          ? Phase0aSkillBehavior.fromYaml(Map<String, dynamic>.from(behavior))
          : null,
    );
  }
}

final class _DebugTacticalSkills {
  const _DebugTacticalSkills({required this.gather, required this.clear});

  final Phase0aTacticalSkillBinding gather;
  final Phase0aTacticalSkillBinding clear;
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

double? _optionalNumber(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value == null) return null;
  if (value is! num) throw FormatException('$key must be numeric');
  return value.toDouble();
}

bool _optionalBool(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value == null) return false;
  if (value is! bool) throw FormatException('$key must be boolean');
  return value;
}

List<String> _optionalStringList(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value == null) return const [];
  if (value is! List || value.any((item) => item is! String || item.isEmpty)) {
    throw FormatException('$key must be a list of non-empty strings');
  }
  return List.unmodifiable(value.cast<String>());
}

Phase0aWinCondition? _optionalWinCondition(Object? raw) {
  if (raw == null) return null;
  if (raw is! Map) throw const FormatException('win_condition must be a map');
  final value = Map<String, dynamic>.from(raw);
  final type = value['type'];
  if (type != 'surviveTicks') {
    throw FormatException('unsupported debug win condition: $type');
  }
  final required = value['required_ticks'];
  if (required is! num || required.toInt() != required || required <= 0) {
    throw const FormatException('required_ticks must be a positive integer');
  }
  return Phase0aWinCondition.surviveTicks(required.toInt());
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
