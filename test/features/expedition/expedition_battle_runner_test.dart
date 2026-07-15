import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_battle_runner.dart';

import '../../support/progression_battle_probe.dart';
import '../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  test('同队伍同 seed → 同结果同存活 HP/qi（确定性）', () {
    final repo = GameRepository.instance;
    final stage = repo.stageDefs['stage_01_01']!;
    List<BattleCharacter> players() => [
          for (var s = 0; s < 3; s++)
            buildProgressionPlayer(
              repository: repo,
              tier: stage.requiredRealm,
              slot: s,
              isFounder: s == 0,
              profile: ProgressionBuildProfile.standard,
            ),
        ];
    final enemies = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);

    final r1 = ExpeditionBattleRunner.runNodeBattle(
      playerTeam: players(),
      enemyTeam: enemies,
      numbers: repo.numbers,
      nodeSeed: 20260715,
    );
    final r2 = ExpeditionBattleRunner.runNodeBattle(
      playerTeam: players(),
      enemyTeam: enemies,
      numbers: repo.numbers,
      nodeSeed: 20260715,
    );
    expect(r1.leftWin, r2.leftWin);
    expect(r1.survivorHp, r2.survivorHp);
    expect(r1.survivorQi, r2.survivorQi);
  });

  test('弱队对高阶敌 → leftWin=false（战败即停信号）', () {
    final repo = GameRepository.instance;
    final strongStage = repo.stageDefs['stage_06_05']!;
    final weakPlayers = [
      buildProgressionPlayer(
        repository: repo,
        tier: RealmTier.xueTu,
        slot: 0,
        isFounder: true,
        profile: ProgressionBuildProfile.undergeared,
      ),
    ];
    final strongEnemies = StageBattleSetup.buildEnemyTeam(strongStage.enemyTeam);

    final r = ExpeditionBattleRunner.runNodeBattle(
      playerTeam: weakPlayers,
      enemyTeam: strongEnemies,
      numbers: repo.numbers,
      nodeSeed: 7,
    );
    expect(r.leftWin, isFalse);
  });
}
