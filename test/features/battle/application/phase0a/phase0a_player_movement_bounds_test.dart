import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  late Phase0aPlayerRuntimeMapping mapping;
  late double minX;
  late double maxX;
  late double minY;
  late double maxY;
  late double delta;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    final arena = repository.numbers.phase0aArena;
    minX = arena.arenaMinX;
    maxX = arena.arenaMaxX;
    minY = arena.arenaMinY;
    maxY = arena.arenaMaxY;
    delta = arena.fixedDeltaSeconds;
    mapping = Phase0aStageContentMapper.mapPlayerOnly(
      contentId: 'stage_01_01',
      numbers: repository.numbers,
      playerSnapshot: testCombatantSnapshot(
        characterId: 1,
        name: 'Player',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        weaponArchetype: WeaponArchetype.heavy,
        skillLoadout: CombatantSkillLoadout(
          basicAttack: repository.skillDefs['skill_gangmeng_jichu_basic'],
        ),
      ),
    );
  });

  Phase0aCombatSession sessionAt(
    ArenaVector position, {
    ArenaVector facing = const ArenaVector(1, 0),
    List<Phase0aActor> enemies = const [],
  }) => Phase0aCombatSession(
    initialState: Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: mapping.initialPlayer.copyWith(
        position: position,
        facing: facing,
      ),
      enemies: enemies,
      skillSlots: mapping.skillSlots,
    ),
    playerAdapter: mapping.playerAdapter,
    enemyAiAdapter: const Phase0aEnemyAiAdapter(
      attackRange: 0,
      attackHalfArcRadians: 0,
      attackCooldownSeconds: 1,
      postureBasicPowerMultiplier: 1,
      uniformBasicPowerMultiplier: 1,
    ),
    damageResolver: const _NoDamage(),
  );

  test(
    'production movement stops at all four configured edges and can leave',
    () {
      final edges = [
        (
          ArenaVector(maxX - 1, 0),
          const ArenaVector(1, 0),
          ArenaVector(maxX, 0),
        ),
        (
          ArenaVector(minX + 1, 0),
          const ArenaVector(-1, 0),
          ArenaVector(minX, 0),
        ),
        (
          ArenaVector(0, maxY - 1),
          const ArenaVector(0, 1),
          ArenaVector(0, maxY),
        ),
        (
          ArenaVector(0, minY + 1),
          const ArenaVector(0, -1),
          ArenaVector(0, minY),
        ),
      ];
      for (final (start, direction, edge) in edges) {
        final session = sessionAt(start);
        for (var tick = 0; tick < 20; tick++) {
          session.advance(
            deltaSeconds: delta,
            command: Phase0aPlayerCommand(moveDirection: direction),
          );
          expect(session.state.player.position, edge);
        }
        session.advance(
          deltaSeconds: delta,
          command: Phase0aPlayerCommand(moveDirection: direction * -1),
        );
        expect(
          session.state.player.position,
          edge - direction * (mapping.initialPlayer.moveSpeed * delta),
        );
      }
    },
  );

  test('production dodge and same-frame movement stay inside each corner', () {
    for (final xSign in [-1.0, 1.0]) {
      for (final ySign in [-1.0, 1.0]) {
        final corner = ArenaVector(
          xSign < 0 ? minX : maxX,
          ySign < 0 ? minY : maxY,
        );
        final direction = ArenaVector(xSign, ySign).normalized();
        final start = corner - direction;
        final session = sessionAt(start);
        final events = session.advance(
          deltaSeconds: delta,
          command: Phase0aPlayerCommand(
            moveDirection: direction,
            defenseAction: Phase0aDefenseAction.dodge,
            defenseDirection: direction,
          ),
        );
        expect(session.state.player.position, corner);
        final dodge = events.whereType<Phase0aDefenseStarted>().single;
        expect(dodge.fromPosition, start);
        expect(dodge.toPosition, corner);
        expect(session.state.player.dodgeTicksRemaining, greaterThan(0));
      }
    }
  });

  test(
    'objective movement projection and session forks use the same bounds',
    () {
      final session = sessionAt(ArenaVector(maxX - 1, 0));
      const command = Phase0aPlayerCommand(right: true);
      expect(
        session.playerMovementDeltaFor(deltaSeconds: delta, command: command),
        const ArenaVector(1, 0),
      );
      final fork = session.forkWithState(session.state);
      fork.advance(deltaSeconds: delta, command: command);
      expect(fork.state.player.position, ArenaVector(maxX, 0));
      expect(
        fork.playerMovementDeltaFor(deltaSeconds: delta, command: command),
        ArenaVector.zero,
      );
    },
  );

  test(
    'visible bot and headless runner retain identical boundary positions',
    () {
      final enemy = Phase0aActor(
        id: 'enemy',
        side: Phase0aSide.enemy,
        position: ArenaVector(0, maxY),
        facing: const ArenaVector(0, -1),
        maxHealth: 100,
        currentHealth: 100,
        moveSpeed: 0,
        qiCurrent: 0,
        qiMax: 0,
        attackCooldownRemaining: 0,
        defeatKind: Phase0aDefeatKind.normal,
      );
      Phase0aWaveBattleFlow flow() => Phase0aWaveBattleFlow(
        session: sessionAt(
          ArenaVector(0, maxY - 1),
          facing: const ArenaVector(0, -1),
          enemies: [enemy],
        ),
        waves: [
          Phase0aWave(enemies: [enemy]),
        ],
      );
      final bot = Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter);
      final visible = flow();
      for (var tick = 0; tick < 10; tick++) {
        visible.advance(
          deltaSeconds: delta,
          command: bot.commandFor(visible.state),
        );
        expect(visible.state.player.position, ArenaVector(0, maxY));
      }
      final headless = Phase0aHeadlessRunner.runToEnd(
        flow: flow(),
        bot: bot,
        deltaSeconds: delta,
        maxTicks: 10,
      );
      expect(headless.finalState, visible.state);
      expect(headless.ticks, 10);
    },
  );
}

class _NoDamage implements Phase0aDamageResolver {
  const _NoDamage();

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1,
  }) => const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 0);
}
