import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

import 'progression_battle_probe.dart';
import 'test_data.dart';

void main() {
  late GameRepository repository;
  late StageDef stage;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    stage = repository.stageDefs['stage_01_05']!;
  });

  test('three profiles create legal and monotonically stronger snapshots', () {
    final players = [
      for (final profile in ProgressionBuildProfile.values)
        buildProgressionPlayer(
          repository: repository,
          tier: RealmTier.yiLiu,
          slot: 0,
          isFounder: true,
          profile: profile,
        ),
    ];

    expect(
      players.map((player) => player.realmLayer),
      everyElement(RealmLayer.huaJing),
    );
    expect(players.map((player) => player.mainCultivationLayer), [
      CultivationLayer.zhongCheng,
      CultivationLayer.zhongCheng,
      CultivationLayer.daCheng,
    ]);
    expect(
      players[0].totalEquipmentAttack,
      lessThan(players[1].totalEquipmentAttack),
    );
    expect(
      players[1].totalEquipmentAttack,
      lessThan(players[2].totalEquipmentAttack),
    );
    expect(players[0].maxHp, lessThan(players[1].maxHp));
    expect(players[1].maxHp, lessThan(players[2].maxHp));
    expect(players[0].speed, lessThan(players[1].speed));
    expect(players[1].speed, lessThan(players[2].speed));
  });

  test('probe is deterministic for the same stage profile and seed', () {
    final first = probeMainlineStage(
      repository: repository,
      stage: stage,
      profile: ProgressionBuildProfile.standard,
      seed: 17,
    );
    final second = probeMainlineStage(
      repository: repository,
      stage: stage,
      profile: ProgressionBuildProfile.standard,
      seed: 17,
    );

    expect(_snapshot(first), _snapshot(second));
  });

  test('observation fields mirror the terminal battle state', () {
    const profile = ProgressionBuildProfile.undergeared;
    const seed = 23;
    final players = [
      for (var slot = 0; slot < 3; slot++)
        buildProgressionPlayer(
          repository: repository,
          tier: stage.requiredRealm,
          slot: slot,
          isFounder: slot == 0,
          profile: profile,
        ),
    ].map(StageBattleSetup.debugApplyReadableFirstClearTuning).toList();
    final enemies = StageBattleSetup.buildEnemyTeam(
      stage.enemyTeam,
      readableFirstClearTuning: true,
    );
    final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
    final terminal = defaultGroundStrategy.runToEnd(
      initial,
      repository.numbers,
      maxTicks: 240,
      rng: Random(seed),
    );

    final observation = probeMainlineStage(
      repository: repository,
      stage: stage,
      profile: profile,
      seed: seed,
    );

    expect(observation.stageId, stage.id);
    expect(observation.profile, profile);
    expect(observation.seed, seed);
    expect(observation.result, terminal.result);
    expect(observation.ticks, terminal.tick);
    expect(observation.playerHpStart, _sumHp(initial.leftTeam));
    expect(observation.playerHpEnd, _sumHp(terminal.leftTeam));
    expect(observation.playerQiStart, _sumQi(initial.leftTeam));
    expect(observation.playerQiEnd, _sumQi(terminal.leftTeam));
    expect(observation.actionRows, terminal.actionLog.length);
  });
}

(
  String,
  ProgressionBuildProfile,
  int,
  BattleResult,
  int,
  int,
  int,
  int,
  int,
  int,
)
_snapshot(ProgressionBattleObservation observation) => (
  observation.stageId,
  observation.profile,
  observation.seed,
  observation.result,
  observation.ticks,
  observation.playerHpStart,
  observation.playerHpEnd,
  observation.playerQiStart,
  observation.playerQiEnd,
  observation.actionRows,
);

int _sumHp(List<BattleCharacter> team) =>
    team.fold(0, (sum, character) => sum + character.currentHp);

int _sumQi(List<BattleCharacter> team) =>
    team.fold(0, (sum, character) => sum + character.currentQi);
