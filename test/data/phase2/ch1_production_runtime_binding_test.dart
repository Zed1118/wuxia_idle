import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/combat_runtime_binding_loader.dart';
import 'package:wuxia_idle/data/defs/combat_runtime_binding_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';

Future<String> _fileLoader(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw FileSystemException('missing', path, const OSError('missing', 2));
  }
  return (await file.readAsString()).replaceAll('\r\n', '\n');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(GameRepository.resetForTest);

  test(
    'rootBundle exposes the three production binding sources and asset',
    () async {
      expect(
        (await rootBundle.loadString('data/combat/manifest.yaml')),
        contains('stage_assignments_source'),
      );
      expect(
        await rootBundle.loadString(
          'data/combat/manifest/stage_assignments.yaml',
        ),
        contains('stage_01_03'),
      );
      expect(
        await rootBundle.loadString('data/combat/runtime_bindings.yaml'),
        contains('enemy_xueTu_bandit_a'),
      );
      expect(
        (await rootBundle.load(
          'assets/enemies/battle_bandit_blade.png',
        )).lengthInBytes,
        greaterThan(0),
      );
    },
  );

  test(
    'GameRepository exposes a typed 40-entry production runtime closure',
    () async {
      final repo = await GameRepository.loadAllDefs(
        loader: _fileLoader,
        assetExists: (path) async => File(path).existsSync(),
      );
      final encounter = repo.combatEncounterForStage('stage_01_03');
      final binding = repo.combatRuntimeBindingForStage('stage_01_03');

      expect(
        repo.combatAssignmentForStage('stage_01_03')?.migrationState.name,
        'migrated',
      );
      expect(encounter?.id, 'ch1_encounter_03_ambush');
      expect(binding, isNotNull);
      expect(binding!.baseEnemyId, 'enemy_xueTu_bandit_a');
      expect(binding.enemyBindings, hasLength(40));
      expect(
        binding.enemyBindings.map((entry) => entry.entryId).toSet(),
        hasLength(40),
      );
      expect(
        binding.enemyBindings.map((entry) => entry.entryId).toSet(),
        equals(encounter!.spawnEntries.map((entry) => entry.entryId).toSet()),
      );

      final sortedBindings = binding.enemyBindings.toList()
        ..sort((a, b) => a.entryId.compareTo(b.entryId));
      final firstTwelve = sortedBindings.take(12).toList();
      expect(
        firstTwelve.every((entry) => entry.roleId == 'bandit_blade'),
        isTrue,
      );
      expect(
        firstTwelve.map((entry) => entry.positionId).toSet(),
        hasLength(12),
      );
      final visualPathsByRole = <String, Set<String>>{};
      for (final point in binding.entrances.values) {
        expect(
          point.x,
          inInclusiveRange(
            repo.numbers.phase0aArena.arenaMinX,
            repo.numbers.phase0aArena.arenaMaxX,
          ),
        );
        expect(
          point.y,
          inInclusiveRange(
            repo.numbers.phase0aArena.arenaMinY,
            repo.numbers.phase0aArena.arenaMaxY,
          ),
        );
      }
      for (final point in binding.positions.values) {
        expect(
          point.x,
          inInclusiveRange(
            repo.numbers.phase0aArena.arenaMinX,
            repo.numbers.phase0aArena.arenaMaxX,
          ),
        );
        expect(
          point.y,
          inInclusiveRange(
            repo.numbers.phase0aArena.arenaMinY,
            repo.numbers.phase0aArena.arenaMaxY,
          ),
        );
      }
      for (final entry in binding.enemyBindings) {
        expect(entry.attackSet.skills, isNotEmpty);
        expect(
          entry.attackSet.skills.every(
            (skill) => repo.skillDefs[skill.id] == skill,
          ),
          isTrue,
        );
        expect(entry.visualVariant.assetPath, isNotEmpty);
        expect(File(entry.visualVariant.assetPath).existsSync(), isTrue);
        visualPathsByRole
            .putIfAbsent(entry.roleId, () => <String>{})
            .add(entry.visualVariant.assetPath);
        expect(entry.behavior.priority, greaterThanOrEqualTo(0));
        expect(entry.behavior.spawnGraceTicksRemaining, 0);
        expect(entry.behavior.telegraphReady, isTrue);
        expect(entry.behavior.isOffscreen, isFalse);
        // All four production attack sets currently bind single-target SkillDef
        // actions; no unblockable-area/high-impact behavior is claimed here.
        expect(entry.behavior.isHighImpact, isFalse);
        expect(entry.behavior.isUnblockableArea, isFalse);
        final token = AttackTokenRequest(
          actorId: entry.entryId,
          kind: AttackTokenKind.values.byName(entry.behavior.tokenPolicy.name),
          priority: entry.behavior.priority,
          isOffscreen: entry.behavior.isOffscreen,
          isHighImpact: entry.behavior.isHighImpact,
          isUnblockableArea: entry.behavior.isUnblockableArea,
          // Phase0aEncounterFlow has already completed the explicit spawn-grace
          // gate before this request is eligible for allocation.
          spawnGraceTicksRemaining: entry.behavior.spawnGraceTicksRemaining,
          telegraphReady: entry.behavior.telegraphReady,
        );
        expect(
          const AttackTokenDirector()
              .allocate(
                budgets: AttackTokenBudgets(
                  melee: 1,
                  ranged: 1,
                  charge: 1,
                  support: 1,
                ),
                requests: [token],
              )
              .decisions
              .single
              .granted,
          isTrue,
        );
        expect(
          entry.entrance.x,
          inInclusiveRange(
            repo.numbers.phase0aArena.arenaMinX,
            repo.numbers.phase0aArena.arenaMaxX,
          ),
        );
        expect(
          entry.position.y,
          inInclusiveRange(
            repo.numbers.phase0aArena.arenaMinY,
            repo.numbers.phase0aArena.arenaMaxY,
          ),
        );
      }
      expect(
        visualPathsByRole.values.every((paths) => paths.length == 2),
        isTrue,
        reason:
            'content-order selection must use both production variants per role',
      );

      final reloaded = await loadProductionCombatRuntimeBindings(
        load: _fileLoader,
        manifest: repo.combatCatalog!,
        stageDefs: repo.stageDefs,
        skillDefs: repo.skillDefs,
        arenaBounds: CombatRuntimeArenaBounds(
          minX: repo.numbers.phase0aArena.arenaMinX,
          maxX: repo.numbers.phase0aArena.arenaMaxX,
          minY: repo.numbers.phase0aArena.arenaMinY,
          maxY: repo.numbers.phase0aArena.arenaMaxY,
        ),
        assetExists: (path) async => File(path).existsSync(),
      );
      expect(
        reloaded
            .bindingForStage('stage_01_03')!
            .enemyBindings
            .map((entry) => entry.visualVariant.id),
        equals(binding.enemyBindings.map((entry) => entry.visualVariant.id)),
        reason: 'content-order visual selection must be stable across reloads',
      );

      for (final stageId in const [
        'stage_01_01',
        'stage_01_02',
        'stage_01_04',
        'stage_01_05',
      ]) {
        expect(
          repo.combatAssignmentForStage(stageId)?.migrationState.name,
          'legacy',
        );
        expect(repo.combatEncounterForStage(stageId), isNull);
        expect(repo.combatRuntimeBindingForStage(stageId), isNull);
        expect(repo.getStage(stageId).id, stageId);
      }
    },
  );

  test(
    'base enemy binding fails closed for unknown, mismatch, and multiple templates',
    () async {
      final repo = await GameRepository.loadAllDefs(
        loader: _fileLoader,
        assetExists: (path) async => File(path).existsSync(),
      );
      final runtimeYaml = await _fileLoader(
        'data/combat/runtime_bindings.yaml',
      );
      final manifest = repo.combatCatalog!;
      final bounds = CombatRuntimeArenaBounds(
        minX: repo.numbers.phase0aArena.arenaMinX,
        maxX: repo.numbers.phase0aArena.arenaMaxX,
        minY: repo.numbers.phase0aArena.arenaMinY,
        maxY: repo.numbers.phase0aArena.arenaMaxY,
      );

      Future<void> expectRejected({
        required String yaml,
        required Map<String, StageDef> stageDefs,
      }) async {
        await expectLater(
          loadCombatRuntimeBindings(
            sourceName: 'data/combat/runtime_bindings.yaml',
            yaml: yaml,
            manifest: manifest,
            stageDefs: stageDefs,
            skillDefs: repo.skillDefs,
            arenaBounds: bounds,
            assetExists: (path) async => File(path).existsSync(),
          ),
          throwsA(isA<FormatException>()),
        );
      }

      final unknownStageDefs = Map<String, StageDef>.from(repo.stageDefs)
        ..remove('stage_01_03');
      await expectRejected(yaml: runtimeYaml, stageDefs: unknownStageDefs);

      await expectRejected(
        yaml: runtimeYaml.replaceFirst(
          'base_enemy_id: enemy_xueTu_bandit_a',
          'base_enemy_id: enemy_xueTu_qingshan',
        ),
        stageDefs: repo.stageDefs,
      );

      final original = repo.getStage('stage_01_03');
      final multipleTemplate = StageDef(
        id: original.id,
        name: original.name,
        stageType: original.stageType,
        chapterIndex: original.chapterIndex,
        towerLayer: original.towerLayer,
        requiredRealm: original.requiredRealm,
        enemyTeam: [original.enemyTeam.single, original.enemyTeam.single],
        isBossStage: original.isBossStage,
        prevStageId: original.prevStageId,
        narrativeOpeningId: original.narrativeOpeningId,
        narrativeVictoryId: original.narrativeVictoryId,
        narrativeDefeatId: original.narrativeDefeatId,
        dropTable: original.dropTable,
        baseExpReward: original.baseExpReward,
        difficultyMultiplier: original.difficultyMultiplier,
        biome: original.biome,
        weather: original.weather,
        sceneBackgroundPath: original.sceneBackgroundPath,
        terrainBiome: original.terrainBiome,
        massBattleWaveCount: original.massBattleWaveCount,
        massBattleEnemyCounts: original.massBattleEnemyCounts,
        npcId: original.npcId,
        bossRecruit: original.bossRecruit,
        factionId: original.factionId,
        dropSkillManualId: original.dropSkillManualId,
        dropSkillFragmentId: original.dropSkillFragmentId,
        winCondition: original.winCondition,
      );
      final multipleStageDefs = Map<String, StageDef>.from(repo.stageDefs)
        ..['stage_01_03'] = multipleTemplate;
      await expectRejected(yaml: runtimeYaml, stageDefs: multipleStageDefs);
    },
  );

  test(
    'production runtime binding fails closed for missing, duplicate, unknown skill, and asset',
    () async {
      final repo = await GameRepository.loadAllDefs(
        loader: _fileLoader,
        assetExists: (path) async => File(path).existsSync(),
      );
      final runtimeYaml = await _fileLoader(
        'data/combat/runtime_bindings.yaml',
      );
      final manifest = repo.combatCatalog!;
      final bounds = CombatRuntimeArenaBounds(
        minX: repo.numbers.phase0aArena.arenaMinX,
        maxX: repo.numbers.phase0aArena.arenaMaxX,
        minY: repo.numbers.phase0aArena.arenaMinY,
        maxY: repo.numbers.phase0aArena.arenaMaxY,
      );

      Future<void> expectRejected(String yaml) async {
        await expectLater(
          loadCombatRuntimeBindings(
            sourceName: 'data/combat/runtime_bindings.yaml',
            yaml: yaml,
            manifest: manifest,
            stageDefs: repo.stageDefs,
            skillDefs: repo.skillDefs,
            arenaBounds: bounds,
            assetExists: (path) async => File(path).existsSync(),
          ),
          throwsA(isA<FormatException>()),
        );
      }

      final bindingStart = runtimeYaml.indexOf('runtime_bindings:');
      await expectRejected(
        '${runtimeYaml.substring(0, bindingStart)}runtime_bindings: []\n',
      );

      final firstBindingStart = runtimeYaml.indexOf('  - stage_id:');
      await expectRejected(
        '$runtimeYaml\n${runtimeYaml.substring(firstBindingStart)}',
      );

      await expectRejected(
        runtimeYaml.replaceFirst(
          'skill_gangmeng_jichu_basic',
          'skill_runtime_unknown',
        ),
      );

      await expectRejected(
        runtimeYaml.replaceFirst(
          'skill_ids: [skill_gangmeng_jichu_basic]',
          'skill_ids: [skill_gangmeng_jichu_basic, skill_gangmeng_jichu_basic]',
        ),
      );

      await expectRejected(
        runtimeYaml.replaceFirst(
          'assets/enemies/battle_bandit_blade.png',
          'assets/enemies/missing-production-asset.png',
        ),
      );
    },
  );
}
