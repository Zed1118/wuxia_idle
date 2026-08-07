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

  test('正确性:幸存表内容——谁活下来/状态如何(非只测确定性)', () {
    // 确定性测只锁「两跑一致」——对「hp/qi 两表串行」「id 错配」「恒空表」
    // 的实现同样成立。本条锁内容本身:keys、存活语义、数值域、与 qi 表可区分。
    final repo = GameRepository.instance;
    final stage = repo.stageDefs['stage_01_01']!;
    final players = [
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

    final r = ExpeditionBattleRunner.runNodeBattle(
      playerTeam: players,
      enemyTeam: enemies,
      numbers: repo.numbers,
      nodeSeed: 20260715,
    );

    expect(
      r.leftWin,
      isTrue,
      reason: 'standard 画像对 stage_01_01 应胜(本条断言行走在胜者语义上)',
    );

    final ids = players.map((c) => c.characterId).toSet();
    expect(r.survivorHp.keys, ids, reason: 'hp 表应覆盖全队(含倒下者)');
    expect(r.survivorQi.keys, ids, reason: 'qi 表应覆盖全队');

    // 谁活下来:standard 画像打第一关全员存活(零承伤速胜,实测无掉血)。
    for (final entry in r.survivorHp.entries) {
      expect(entry.value, greaterThan(0), reason: '成员 ${entry.key} 应存活');
    }
    expect(
      r.finalState.actionLog.where((a) => a.attackResult != null),
      isNotEmpty,
      reason: '应真产生攻击动作(防空过:恒空表/恒等实现无法靠本断言区分)',
    );

    // 数值域 + 映射归位:hp 落在 [0, maxHp],且按 characterId 对应到
    // 终局状态本人(防 id 错配)。
    for (final c in r.finalState.leftTeam) {
      expect(r.survivorHp[c.characterId], c.currentHp);
      expect(r.survivorQi[c.characterId], c.currentQi);
      expect(r.survivorHp[c.characterId]!, inInclusiveRange(0, c.maxHp));
      expect(r.survivorQi[c.characterId]!, inInclusiveRange(0, c.maxQi));
    }

    // 可区分性锚:至少一名成员 hp ≠ qi,否则「两表串行」类 bug 无从证伪。
    expect(
      r.finalState.leftTeam.any((c) => c.currentHp != c.currentQi),
      isTrue,
      reason: '场景应存在 hp ≠ qi 的成员,否则 hp/qi 串行 bug 不可证伪(防空过)',
    );
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
    final strongEnemies = StageBattleSetup.buildEnemyTeam(
      strongStage.enemyTeam,
    );

    final r = ExpeditionBattleRunner.runNodeBattle(
      playerTeam: weakPlayers,
      enemyTeam: strongEnemies,
      numbers: repo.numbers,
      nodeSeed: 7,
    );
    expect(r.leftWin, isFalse);
  });
}
