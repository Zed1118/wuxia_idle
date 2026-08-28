import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/combat_encounter_catalog_loader.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_reference_index.dart';
import 'package:wuxia_idle/data/defs/combat_enemy_archetype_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_host.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_enemy_behavior_profile.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:yaml/yaml.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

Future<CombatCatalogYamlSource> _source(String path) async =>
    ('data/combat/$path', await File('data/combat/$path').readAsString());

CombatCatalogReferenceIndex _referenceIndex() => CombatCatalogReferenceIndex(
  entranceIds: const {
    'ch1_entrance_s03_front',
    'ch1_entrance_s03_rear',
    'ch1_entrance_s03_upper',
  },
  positionIds: const {
    'ch1_position_s03_slot_01',
    'ch1_position_s03_slot_02',
    'ch1_position_s03_slot_03',
    'ch1_position_s03_slot_04',
    'ch1_position_s03_slot_05',
    'ch1_position_s03_slot_06',
    'ch1_position_s03_slot_07',
    'ch1_position_s03_slot_08',
    'ch1_position_s03_slot_09',
    'ch1_position_s03_slot_10',
    'ch1_position_s03_slot_11',
    'ch1_position_s03_slot_12',
  },
  behaviorIds: const {
    'ch1_behavior_blade_press',
    'ch1_behavior_crossbow_offset',
    'ch1_behavior_rope_flank',
    'ch1_behavior_gong_command',
  },
  attackSetIds: const {
    'ch1_attack_set_blade',
    'ch1_attack_set_crossbow',
    'ch1_attack_set_rope_raider',
    'ch1_attack_set_gong_leader',
  },
  attackTagIds: const {
    'ch1_attack_tag_melee',
    'ch1_attack_tag_projectile',
    'ch1_attack_tag_charge',
    'ch1_attack_tag_support',
  },
  postureProfileIds: const {
    'ch1_posture_blade',
    'ch1_posture_crossbow',
    'ch1_posture_rope_raider',
    'ch1_posture_gong_leader',
  },
  dropGroupIds: const {'ch1_drop_group_bandit_encounter'},
  sfxGroupIds: const {
    'ch1_sfx_blade',
    'ch1_sfx_crossbow',
    'ch1_sfx_rope_raider',
    'ch1_sfx_gong_leader',
  },
  visualVariantIds: const {
    'ch1_visual_blade_a',
    'ch1_visual_blade_b',
    'ch1_visual_crossbow_a',
    'ch1_visual_crossbow_b',
    'ch1_visual_rope_raider_a',
    'ch1_visual_rope_raider_b',
    'ch1_visual_gong_leader_a',
    'ch1_visual_gong_leader_b',
  },
  objectiveTargetIds: {
    for (final prefix in const ['blade', 'crossbow', 'rope'])
      for (var index = 1; index <= (prefix == 'blade' ? 18 : 10); index++)
        'ch1_s03_${prefix}_${index.toString().padLeft(2, '0')}',
    'ch1_s03_leader_01',
    'ch1_s03_leader_02',
  },
  objectiveAnchorIds: const [],
  objectiveEntityIds: const [],
  objectiveCheckpointIds: const [],
  objectiveMarkerIds: const [],
);

Future<CombatCatalogManifestDef> _productionCatalog() async =>
    loadCombatCatalogManifest(
      archetypeSources: [await _source('archetypes/bandits.yaml')],
      encounterSources: [await _source('encounters/black_wind_ridge.yaml')],
      manifestSource: await _source('manifest/stage_assignments.yaml'),
      referenceIndex: _referenceIndex(),
    );

void main() {
  late GameRepository repository;
  late CombatCatalogManifestDef catalog;
  late Phase0aPlayerRuntimeMapping playerMapping;
  late _ProductionRuntimeSource runtimeSource;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    catalog = await _productionCatalog();
    playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
      contentId: 'stage_01_03',
      playerSnapshot: testCombatantSnapshot(
        maxHp: 15000,
        currentHp: 15000,
        maxQi: 100,
        currentQi: 100,
        includeProductionBasicAttack: true,
      ),
      numbers: repository.numbers,
    );
    runtimeSource = _ProductionRuntimeSource(
      catalog: catalog,
      repository: repository,
    );
  });

  test(
    'production catalog -> factory builds 40 actors, 12 cap and roster',
    () async {
      final host = await createFreshPhase0aMainlineEncounter(
        Phase0aMainlineEncounterHostBuildRequest(
          stage: repository.getStage('stage_01_03'),
          playerMapping: playerMapping,
          numbers: repository.numbers,
          cycleIndex: 1,
          rng: Random(7),
          runtimeBindingSource: runtimeSource,
          catalogOverride: catalog,
        ),
      );

      expect(host, isNotNull);
      final mapping = host!.mapping!;
      expect(mapping.combatants, hasLength(41));
      expect(mapping.director.config.activeLimit, 12);
      final enemyIds = mapping.combatants.skip(1).map((item) => item.actorId);
      expect(enemyIds.toSet(), hasLength(40));
      expect(enemyIds, everyElement(matches(RegExp(r'actor-\d{3}$'))));
      expect(enemyIds, everyElement(isNot(contains('ch1_s03_'))));

      final activePositions = runtimeSource.positions.take(12).toSet();
      expect(activePositions, hasLength(12));
      final arena = repository.numbers.phase0aArena;
      for (final position in activePositions) {
        expect(position.x, inInclusiveRange(arena.arenaMinX, arena.arenaMaxX));
        expect(position.y, inInclusiveRange(arena.arenaMinY, arena.arenaMaxY));
      }

      final roster = Phase0aVisualRoster.fromCombatants(
        playerId: mapping.initialState.player.id,
        combatants: mapping.combatants,
        assetPathByActorId: host.visualAssetPathByActorId,
        threatsByActorId: host.tokenBindingsByActorId?.map(
          (actorId, token) => MapEntry(
            actorId,
            Phase0aActorThreatVisual(
              kind: token.kind,
              isHighImpact: token.isHighImpact,
            ),
          ),
        ),
      );
      for (final actorId in enemyIds) {
        expect(roster.visualFor(actorId).assetPath, startsWith('assets/'));
      }
      expect(runtimeSource.tokens.map((token) => token.kind).toSet(), {
        AttackTokenKind.melee,
        AttackTokenKind.ranged,
        AttackTokenKind.charge,
        AttackTokenKind.support,
      });
      expect(host.tokenBindingsByActorId, hasLength(40));
      expect(
        enemyIds
            .map((actorId) => roster.visualFor(actorId).threat!.kind)
            .toSet(),
        {
          AttackTokenKind.melee,
          AttackTokenKind.ranged,
          AttackTokenKind.charge,
          AttackTokenKind.support,
        },
      );
    },
  );

  test('default provider consumes the real repository runtime closure', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final source = container.read(
      phase0aMainlineEncounterRuntimeBindingSourceProvider,
    );
    final bundle = await source.load(
      stageId: 'stage_01_03',
      encounterId: 'ch1_encounter_03_ambush',
      cycleIndex: 1,
    );

    expect(bundle.tickDuration, const Duration(milliseconds: 100));
    expect(bundle.actorBindingsByEntryId, hasLength(40));
    final blade = bundle.actorBindingsByEntryId['ch1_s03_blade_01']!;
    final crossbow = bundle.actorBindingsByEntryId['ch1_s03_crossbow_01']!;
    final rope = bundle.actorBindingsByEntryId['ch1_s03_rope_01']!;
    final leader = bundle.actorBindingsByEntryId['ch1_s03_leader_01']!;

    expect(blade.combatant.maxHp, 2900);
    expect(crossbow.combatant.maxHp, 2320);
    expect(rope.combatant.maxHp, 3190);
    expect(leader.combatant.maxHp, 3770);
    expect(blade.combatant.speed, 110);
    expect(crossbow.combatant.speed, 110);
    expect(rope.combatant.speed, 121);
    expect(leader.combatant.speed, 99);
    expect(
      leader.combatant.defenseRate,
      closeTo(
        (blade.combatant.defenseRate * 1.2).clamp(
          0.0,
          repository.numbers.cycleEvolution.defenseRateCap,
        ),
        0.000001,
      ),
    );
    expect(
      leader.combatant.skillLoadout.basicAttack!.id,
      'skill_gangmeng_jichu_basic',
    );
    expect(
      leader.enemySkillBindings.single.skill.id,
      'skill_gangmeng_jichu_skill',
    );
    expect(blade.token.kind, AttackTokenKind.melee);
    expect(crossbow.token.kind, AttackTokenKind.ranged);
    expect(rope.token.kind, AttackTokenKind.charge);
    expect(leader.token.kind, AttackTokenKind.support);
    expect(
      blade.behaviorProfile,
      const Phase0aEnemyBehaviorProfile(
        id: 'ai_bandit_press',
        movementPolicy: Phase0aEnemyMovementPolicy.directAdvance,
        attackPolicy: Phase0aEnemyAttackPolicy.closeRange,
      ),
    );
    expect(
      crossbow.behaviorProfile,
      const Phase0aEnemyBehaviorProfile(
        id: 'ai_crossbow_offset',
        movementPolicy: Phase0aEnemyMovementPolicy.holdDistance,
        attackPolicy: Phase0aEnemyAttackPolicy.rangedPressure,
      ),
    );
    expect(
      rope.behaviorProfile,
      const Phase0aEnemyBehaviorProfile(
        id: 'ai_rope_flank',
        movementPolicy: Phase0aEnemyMovementPolicy.lateralFlank,
        attackPolicy: Phase0aEnemyAttackPolicy.chargeAndReposition,
      ),
    );
    expect(
      leader.behaviorProfile,
      const Phase0aEnemyBehaviorProfile(
        id: 'ai_gong_command',
        movementPolicy: Phase0aEnemyMovementPolicy.guardedPosition,
        attackPolicy: Phase0aEnemyAttackPolicy.supportPulse,
      ),
    );
    expect(leader.token.priority, 3);
    expect(leader.visualAssetPath, startsWith('assets/enemies/'));
    final ropeActor = rope.createActor('runtime-rope');
    expect(ropeActor.id, 'runtime-rope');
    expect(ropeActor.position, const ArenaVector(120, 120));
    expect(ropeActor.moveSpeed, 121);

    final host = await createFreshPhase0aMainlineEncounter(
      Phase0aMainlineEncounterHostBuildRequest(
        stage: repository.getStage('stage_01_03'),
        playerMapping: playerMapping,
        numbers: repository.numbers,
        cycleIndex: 1,
        rng: Random(17),
        runtimeBindingSource: source,
      ),
    );
    expect(host, isNotNull);
    final mapping = host!.mapping!;
    expect(mapping.combatants, hasLength(41));
    expect(mapping.enemyAiAdapter.behaviorProfilesByActor, hasLength(40));
    final encounter = catalog.encounterForStage('stage_01_03')!;
    String runtimeIdFor(String entryId) {
      final ordinal = encounter.spawnEntries.indexWhere(
        (entry) => entry.entryId == entryId,
      );
      return 'stage_01_03/${encounter.id}/actor-${ordinal.toString().padLeft(3, '0')}';
    }

    final intentState = Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: mapping.initialState.player,
      enemies: [
        for (final entryId in const [
          'ch1_s03_blade_01',
          'ch1_s03_crossbow_01',
          'ch1_s03_rope_01',
          'ch1_s03_leader_01',
        ])
          bundle.actorBindingsByEntryId[entryId]!.createActor(
            runtimeIdFor(entryId),
          ),
      ],
      skillSlots: mapping.initialState.skillSlots,
    );
    final profileIds = {
      for (final intent in mapping.enemyAiAdapter.intentsFor(
        state: intentState,
      ))
        switch (intent) {
          Phase0aMoveIntent(:final behaviorProfile) => behaviorProfile?.id,
          Phase0aAttackIntent(:final behaviorProfile) => behaviorProfile?.id,
          Phase0aEnemySkillIntent(:final behaviorProfile) =>
            behaviorProfile?.id,
          _ => null,
        },
    };
    expect(profileIds, {
      'ai_bandit_press',
      'ai_crossbow_offset',
      'ai_rope_flank',
      'ai_gong_command',
    });
    host.advanceManual(
      deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
      command: const Phase0aPlayerCommand(),
    );
    expect(host.flow.state.tick, 1);
  });

  test('migrated binding failure never falls back to legacy', () async {
    await expectLater(
      createFreshPhase0aMainlineEncounter(
        Phase0aMainlineEncounterHostBuildRequest(
          stage: repository.getStage('stage_01_03'),
          playerMapping: playerMapping,
          numbers: repository.numbers,
          cycleIndex: 1,
          rng: Random(7),
          runtimeBindingSource:
              const Phase0aMainlineEncounterRuntimeBindingSourceAdapter.unconfigured(),
          catalogOverride: catalog,
        ),
      ),
      throwsStateError,
    );
  });

  test(
    'three fresh production sessions keep live and headless parity',
    () async {
      Future<Phase0aEncounterHost> fresh() async =>
          (await createFreshPhase0aMainlineEncounter(
            Phase0aMainlineEncounterHostBuildRequest(
              stage: repository.getStage('stage_01_03'),
              playerMapping: playerMapping,
              numbers: repository.numbers,
              cycleIndex: 1,
              rng: Random(42),
              runtimeBindingSource: runtimeSource,
              catalogOverride: catalog,
            ),
          ))!;

      final manual = await fresh();
      final auto = await fresh();
      final headless = await fresh();
      manual.advanceManual(
        deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
        command: const Phase0aPlayerCommand(),
      );
      auto.advanceAuto(
        deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
        bot: Phase0aPlayerBotAdapter(
          playerAdapter: auto.mapping!.playerAdapter,
        ),
      );
      final headlessResult = headless.runHeadless(
        bot: Phase0aPlayerBotAdapter(
          playerAdapter: headless.mapping!.playerAdapter,
        ),
        deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: 1,
      );

      expect(manual.flow.state.tick, 1);
      expect(auto.flow.state.tick, 1);
      expect(headlessResult.ticks, 1);
      expect(manual.flow.outcome, auto.flow.outcome);
      expect(auto.flow.outcome, headlessResult.outcome);
    },
  );

  test(
    'explicit legacy assignment remains null from the same factory',
    () async {
      final host = await createFreshPhase0aMainlineEncounter(
        Phase0aMainlineEncounterHostBuildRequest(
          stage: repository.getStage('stage_01_01'),
          playerMapping: playerMapping,
          numbers: repository.numbers,
          cycleIndex: 1,
          rng: Random(7),
          runtimeBindingSource: runtimeSource,
          catalogOverride: catalog,
        ),
      );
      expect(host, isNull);
    },
  );
}

final class _ProductionRuntimeSource
    implements Phase0aMainlineEncounterRuntimeBindingSource {
  _ProductionRuntimeSource({required this.catalog, required this.repository}) {
    final encounter = catalog.encounterForStage('stage_01_03')!;
    final arena = repository.numbers.phase0aArena;
    final activeLimit = encounter.spawnConfig.activeLimit;
    final runtime =
        loadYaml(File('data/combat/runtime_bindings.yaml').readAsStringSync())
            as YamlMap;
    final binding = (runtime['runtime_bindings'] as YamlList).single as YamlMap;
    final visualVariants = <String, String>{};
    for (final raw in binding['visual_variants'] as YamlList) {
      final item = raw as YamlMap;
      visualVariants[item['id'] as String] = item['asset_path'] as String;
    }
    final attackSets = <String, String>{};
    for (final raw in binding['attack_sets'] as YamlList) {
      final item = raw as YamlMap;
      attackSets[item['id'] as String] =
          (item['skill_ids'] as YamlList).first as String;
    }
    final actorBindings = <String, Phase0aEncounterActorRuntimeBinding>{};
    for (var ordinal = 0; ordinal < encounter.spawnEntries.length; ordinal++) {
      final entry = encounter.spawnEntries[ordinal];
      final variant = catalog
          .archetypeById(entry.archetypeId)!
          .variantByRole(entry.roleId)!;
      final skill = repository.getSkill(attackSets[variant.attackSetId]!);
      final slot = ordinal % activeLimit;
      final position = ArenaVector(
        arena.arenaMaxX * 0.4,
        arena.arenaMinY +
            (arena.arenaMaxY - arena.arenaMinY) * (slot + 0.5) / activeLimit,
      );
      positions.add(position);
      final snapshot = testCombatantSnapshot(
        characterId: ordinal + 2,
        name: entry.entryId,
        maxHp: 1000,
        currentHp: 1000,
        skillLoadout: CombatantSkillLoadout(basicAttack: skill),
        availableSkills: [skill],
        iconPath: visualVariants[variant.visualVariantIds.first],
      );
      final token = Phase0aEncounterTokenBinding(
        kind: switch (variant.attackTokenKind) {
          CombatAttackTokenKind.melee => AttackTokenKind.melee,
          CombatAttackTokenKind.ranged => AttackTokenKind.ranged,
          CombatAttackTokenKind.charge => AttackTokenKind.charge,
          CombatAttackTokenKind.support => AttackTokenKind.support,
        },
        priority: 1,
        tag: variant.attackTagIds.first,
        visibility: 'on_screen',
        isOffscreen: false,
        isHighImpact: false,
        isUnblockableArea: false,
        spawnGraceTicksRemaining: 0,
        telegraphReady: true,
      );
      tokens.add(token);
      actorBindings[entry.entryId] = Phase0aEncounterActorRuntimeBinding(
        createActor: (id) => Phase0aActor(
          id: id,
          side: Phase0aSide.enemy,
          position: position,
          facing: const ArenaVector(-1, 0),
          maxHealth: snapshot.maxHp,
          currentHealth: snapshot.currentHp,
          moveSpeed: arena.enemyMoveSpeed,
          qiCurrent: snapshot.currentQi,
          qiMax: snapshot.maxQi,
          attackCooldownRemaining: 0,
          defeatKind: Phase0aDefeatKind.normal,
        ),
        combatant: snapshot,
        token: token,
        enemySkillBindings: const [],
        basicQiDelta: skill.qiDelta,
        basicPowerMultiplier: skill.powerMultiplier,
        entrance: entry.entranceId,
        behaviorAiProfile: entry.behaviorId,
        attackSet: variant.attackSetId,
        visualVariant: variant.visualVariantIds.first,
        visualAssetPath: visualVariants[variant.visualVariantIds.first]!,
      );
    }
    bundle = Phase0aMainlineEncounterRuntimeBindingBundle(
      stageId: 'stage_01_03',
      encounterId: encounter.id,
      tickDuration: Duration(
        microseconds: (arena.fixedDeltaSeconds * Duration.microsecondsPerSecond)
            .round(),
      ),
      actorBindingsByEntryId: actorBindings,
    );
  }

  final CombatCatalogManifestDef catalog;
  final GameRepository repository;
  late final Phase0aMainlineEncounterRuntimeBindingBundle bundle;
  final positions = <ArenaVector>[];
  final tokens = <Phase0aEncounterTokenBinding>[];

  @override
  Future<Phase0aMainlineEncounterRuntimeBindingBundle> load({
    required String stageId,
    required String encounterId,
    required int cycleIndex,
  }) async => bundle;
}
