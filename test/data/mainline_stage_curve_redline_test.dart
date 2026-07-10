import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../support/test_data.dart';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    GameRepository.resetForTest();
    repo = await loadTestGameRepository();
  });

  tearDownAll(GameRepository.resetForTest);

  test('Ch1_04 early boss stays in readable onboarding range', () {
    final enemy = repo.getStage('stage_01_04').enemyTeam.single;

    expect(
      enemy.baseHp,
      inInclusiveRange(2000, 2600),
      reason: 'Ch1_04 是第一章小 Boss，不应回退成过厚的新手墙',
    );
    expect(
      enemy.baseAttack,
      lessThanOrEqualTo(80),
      reason: 'Ch1_04 攻击只做新手压力，不应秒杀刚成型角色',
    );
  });

  test('Ch2_05 chapter boss attack does not regress to the old spike', () {
    final boss = repo
        .getStage('stage_02_05')
        .enemyTeam
        .singleWhere((enemy) => enemy.id == 'enemy_sanLiu_qingshan_main');

    expect(
      boss.baseHp,
      lessThanOrEqualTo(10000),
      reason: 'Ch2_05 章末 Boss 可厚，但不应越过当前三流章节曲线',
    );
    expect(
      boss.baseAttack,
      lessThanOrEqualTo(1000),
      reason: '外部审查中过高攻击已修正，后续不能回退到 1100+',
    );
  });

  test('Ch5 mainline base HP and attack form a clear chapter curve', () {
    final stageIds = [
      'stage_05_01',
      'stage_05_02',
      'stage_05_03',
      'stage_05_04',
      'stage_05_05',
    ];
    final enemies = stageIds.map(
      (stageId) => repo.getStage(stageId).enemyTeam.single,
    );
    final hpCurve = enemies.map((enemy) => enemy.baseHp).toList();
    final attackCurve = enemies.map((enemy) => enemy.baseAttack).toList();

    expect(hpCurve, [
      10000,
      11000,
      12000,
      17000,
      24000,
    ], reason: 'Ch5 应从普通关递进到小 Boss，再到跨阶章末 Boss');
    expect(attackCurve, [
      700,
      800,
      850,
      1000,
      1500,
    ], reason: 'Ch5 攻击压力应随关卡逐步抬升，不再首关倒挂');
    for (var i = 1; i < hpCurve.length; i += 1) {
      expect(hpCurve[i], greaterThanOrEqualTo(hpCurve[i - 1]));
      expect(attackCurve[i], greaterThanOrEqualTo(attackCurve[i - 1]));
    }
  });
}
