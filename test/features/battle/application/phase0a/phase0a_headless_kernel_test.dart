import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';

/// Phase 0A headless 内核红测(headless 内核批,路线 C 子项①落地):
/// ① bot 策略:无敌人/玩家死亡 → 空指令;超射程或朝向出扇 → 朝目标移动;
///   射程内且朝向正确 → 站定输出;技能印 ready 才按;
/// ② runToEnd:单波/两波 bot 全程驾驶 victory;玩家死亡 defeat;
///   拍数预算耗尽 ongoing + timedOut;maxTicks=0 零推进;
/// ③ 确定性:相同初态 + 相同 resolver 行为两次运行,ticks/终局/终态全等;
/// ④ fail-fast:deltaSeconds 零/负/NaN、maxTicks 负均 ArgumentError。

class CountingDamageResolver implements Phase0aDamageResolver {
  CountingDamageResolver({required this.damage});

  final int damage;
  int calls = 0;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
  }) {
    calls++;
    return Phase0aResolvedHit(isHit: true, isCritical: false, damage: damage);
  }
}

Phase0aActor makePlayer({int currentHealth = 100}) {
  return Phase0aActor(
    id: 'player',
    side: Phase0aSide.player,
    position: const ArenaVector(0, 0),
    facing: const ArenaVector(1, 0),
    maxHealth: 100,
    currentHealth: currentHealth,
    moveSpeed: 100,
    qiCurrent: 100,
    qiMax: 100,
    attackCooldownRemaining: 0,
    defeatKind: Phase0aDefeatKind.normal,
  );
}

Phase0aActor makeEnemy({
  required String id,
  required ArenaVector position,
  int currentHealth = 30,
}) {
  return Phase0aActor(
    id: id,
    side: Phase0aSide.enemy,
    position: position,
    facing: const ArenaVector(-1, 0),
    maxHealth: currentHealth,
    currentHealth: currentHealth,
    moveSpeed: 60,
    qiCurrent: 0,
    qiMax: 0,
    attackCooldownRemaining: 0,
    defeatKind: Phase0aDefeatKind.normal,
  );
}

const readySkillSlots = [
  Phase0aSkillSlot(
    slot: 'gather',
    cooldownRemaining: 0,
    qiCost: 20,
    availability: Phase0aSkillAvailability.ready,
  ),
  Phase0aSkillSlot(
    slot: 'clear',
    cooldownRemaining: 0,
    qiCost: 30,
    availability: Phase0aSkillAvailability.ready,
  ),
];

Phase0aArenaState makeState({
  Phase0aActor? player,
  List<Phase0aActor>? enemies,
  List<Phase0aSkillSlot>? skillSlots,
}) {
  return Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: player ?? makePlayer(),
    enemies: enemies ?? const [],
    skillSlots: skillSlots ?? readySkillSlots,
  );
}

Phase0aPlayerInputAdapter makePlayerAdapter() {
  return const Phase0aPlayerInputAdapter(
    playerId: 'player',
    attackRange: 120,
    attackHalfArcRadians: math.pi / 4,
    attackCooldownSeconds: 1,
    gatherSlot: 'gather',
    gatherRingRadius: 90,
    gatherEffectRadius: 500,
    gatherQiCost: 20,
    gatherCooldownSeconds: 3,
    clearSlot: 'clear',
    clearEffectRadius: 500,
    clearQiCost: 30,
    clearCooldownSeconds: 4,
  );
}

Phase0aPlayerBotAdapter makeBot() =>
    Phase0aPlayerBotAdapter(playerAdapter: makePlayerAdapter());

Phase0aWaveBattleFlow makeFlow({
  required List<Phase0aActor> firstWaveEnemies,
  List<List<Phase0aActor>>? extraWaves,
  Phase0aActor? player,
  List<Phase0aSkillSlot>? skillSlots,
  Phase0aDamageResolver? damageResolver,
}) {
  final waves = <Phase0aWave>[
    Phase0aWave(enemies: firstWaveEnemies),
    for (final enemies in extraWaves ?? const <List<Phase0aActor>>[])
      Phase0aWave(enemies: enemies),
  ];
  return Phase0aWaveBattleFlow(
    session: Phase0aCombatSession(
      initialState: makeState(
        player: player,
        enemies: firstWaveEnemies,
        skillSlots: skillSlots,
      ),
      playerAdapter: makePlayerAdapter(),
      enemyAiAdapter: const Phase0aEnemyAiAdapter(
        attackRange: 70,
        attackHalfArcRadians: math.pi / 3,
        attackCooldownSeconds: 1.2,
      ),
      damageResolver: damageResolver ?? CountingDamageResolver(damage: 15),
    ),
    waves: waves,
  );
}

void main() {
  group('bot 策略', () {
    test('无敌人或玩家死亡返回空指令', () {
      final bot = makeBot();
      final empty = bot.commandFor(makeState());
      expect(empty.attack, isFalse);
      expect(empty.left || empty.right || empty.up || empty.down, isFalse);

      final dead = bot.commandFor(
        makeState(
          player: makePlayer(currentHealth: 0),
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
      );
      expect(dead.attack, isFalse);
    });

    test('敌人超出射程时朝目标移动且常按普攻', () {
      final command = makeBot().commandFor(
        makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(300, 40))],
        ),
      );
      expect(command.right, isTrue);
      expect(command.down, isTrue);
      expect(command.left, isFalse);
      expect(command.up, isFalse);
      expect(command.attack, isTrue);
    });

    test('射程内且朝向在扇区内时站定输出', () {
      final command = makeBot().commandFor(
        makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
      );
      expect(
        command.left || command.right || command.up || command.down,
        isFalse,
      );
      expect(command.attack, isTrue);
    });

    test('射程内但朝向出扇时用移动校正朝向', () {
      final command = makeBot().commandFor(
        makeState(
          player: const Phase0aActor(
            id: 'player',
            side: Phase0aSide.player,
            position: ArenaVector(0, 0),
            facing: ArenaVector(-1, 0),
            maxHealth: 100,
            currentHealth: 100,
            moveSpeed: 100,
            qiCurrent: 100,
            qiMax: 100,
            attackCooldownRemaining: 0,
            defeatKind: Phase0aDefeatKind.normal,
          ),
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
      );
      expect(command.right, isTrue);
      expect(command.attack, isTrue);
    });

    test('技能印 ready 即按,非 ready 不按', () {
      final ready = makeBot().commandFor(
        makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
      );
      expect(ready.gather, isTrue);
      expect(ready.clear, isTrue);

      final coolingDown = makeBot().commandFor(
        makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
          skillSlots: const [
            Phase0aSkillSlot(
              slot: 'gather',
              cooldownRemaining: 2,
              qiCost: 20,
              availability: Phase0aSkillAvailability.cooldown,
            ),
            Phase0aSkillSlot(
              slot: 'clear',
              cooldownRemaining: 0,
              qiCost: 30,
              availability: Phase0aSkillAvailability.qi,
            ),
          ],
        ),
      );
      expect(coolingDown.gather, isFalse);
      expect(coolingDown.clear, isFalse);
    });
  });

  group('runToEnd 终局', () {
    test('bot 全程驾驶单波 victory', () {
      final flow = makeFlow(
        firstWaveEnemies: [
          makeEnemy(id: 'e1', position: const ArenaVector(200, 0)),
        ],
      );
      final result = Phase0aHeadlessRunner.runToEnd(
        flow: flow,
        bot: makeBot(),
        deltaSeconds: 1 / 30,
      );
      expect(result.outcome, Phase0aBattleOutcome.victory);
      expect(result.timedOut, isFalse);
      expect(result.ticks, greaterThan(0));
      expect(result.finalState.player.isAlive, isTrue);
      expect(result.finalState.enemies, isEmpty);
    });

    test('bot 驾驶两波连续 victory', () {
      final flow = makeFlow(
        firstWaveEnemies: [
          makeEnemy(id: 'e1', position: const ArenaVector(150, 0)),
        ],
        extraWaves: [
          [makeEnemy(id: 'e2', position: const ArenaVector(180, 30))],
        ],
      );
      final result = Phase0aHeadlessRunner.runToEnd(flow: flow, bot: makeBot());
      expect(result.outcome, Phase0aBattleOutcome.victory);
      expect(result.finalState.enemies, isEmpty);
      expect(result.finalState.player.isAlive, isTrue);
    });

    test('敌方压制时 defeat,玩家终态死亡', () {
      final flow = makeFlow(
        firstWaveEnemies: [
          makeEnemy(
            id: 'e1',
            position: const ArenaVector(200, 0),
            currentHealth: 1000,
          ),
        ],
        damageResolver: CountingDamageResolver(damage: 60),
      );
      final result = Phase0aHeadlessRunner.runToEnd(flow: flow, bot: makeBot());
      expect(result.outcome, Phase0aBattleOutcome.defeat);
      expect(result.finalState.player.isAlive, isFalse);
    });

    test('拍数预算耗尽为 ongoing + timedOut,maxTicks=0 零推进', () {
      final flow = makeFlow(
        firstWaveEnemies: [
          makeEnemy(
            id: 'e1',
            position: const ArenaVector(200, 0),
            currentHealth: 1000,
          ),
        ],
      );
      final result = Phase0aHeadlessRunner.runToEnd(
        flow: flow,
        bot: makeBot(),
        maxTicks: 3,
      );
      expect(result.outcome, Phase0aBattleOutcome.ongoing);
      expect(result.timedOut, isTrue);
      expect(result.ticks, 3);

      final idleFlow = makeFlow(
        firstWaveEnemies: [
          makeEnemy(id: 'e1', position: const ArenaVector(200, 0)),
        ],
      );
      final idle = Phase0aHeadlessRunner.runToEnd(
        flow: idleFlow,
        bot: makeBot(),
        maxTicks: 0,
      );
      expect(idle.ticks, 0);
      expect(idle.outcome, Phase0aBattleOutcome.ongoing);
      expect(idleFlow.state.tick, 0);
    });

    test('确定性:相同初态与 resolver 行为两次运行全等', () {
      Phase0aHeadlessResult run() => Phase0aHeadlessRunner.runToEnd(
        flow: makeFlow(
          firstWaveEnemies: [
            makeEnemy(id: 'e1', position: const ArenaVector(200, 0)),
          ],
          extraWaves: [
            [makeEnemy(id: 'e2', position: const ArenaVector(160, -40))],
          ],
        ),
        bot: makeBot(),
      );
      final first = run();
      final second = run();
      expect(second.outcome, first.outcome);
      expect(second.ticks, first.ticks);
      expect(second.finalState, first.finalState);
    });
  });

  group('runToEnd fail-fast', () {
    test('非法拍长与负预算 ArgumentError', () {
      for (final delta in [0.0, -0.1, double.nan, double.infinity]) {
        expect(
          () => Phase0aHeadlessRunner.runToEnd(
            flow: makeFlow(
              firstWaveEnemies: [
                makeEnemy(id: 'e1', position: const ArenaVector(50, 0)),
              ],
            ),
            bot: makeBot(),
            deltaSeconds: delta,
          ),
          throwsArgumentError,
          reason: 'deltaSeconds=$delta 应 fail-fast',
        );
      }
      expect(
        () => Phase0aHeadlessRunner.runToEnd(
          flow: makeFlow(
            firstWaveEnemies: [
              makeEnemy(id: 'e1', position: const ArenaVector(50, 0)),
            ],
          ),
          bot: makeBot(),
          maxTicks: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}
