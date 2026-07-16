import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_controller.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';

/// C1.3.3b：断魂庄关次推进状态机 `GauntletController.advance`（§5.2-5.5/§9.2）。
///
/// 一次 advance 只消费「当前关战末态」→ 快照继承 + 推进一关：
/// 胜利非终关 → `interlude` 停整备（不自动连打）+ `currentStage++`；
/// 胜利终关(boss) → `awaitingRewardChoice`；
/// 败/平 → 不推进停当前关（失败结算归 C2.5），但仍记战末快照。
/// 快照走 `snapshotAfterStage` 白名单（生命/真气/阵亡/冷却），临时态无路径进。
BattleCharacter _combatant(
  int id, {
  required int hp,
  required int qi,
  required bool alive,
}) => BattleCharacter(
  characterId: id,
  name: 'c$id',
  realmTier: RealmTier.yiLiu,
  realmLayer: RealmLayer.qiMeng,
  school: TechniqueSchool.gangMeng,
  maxHp: 1000,
  currentHp: hp,
  internalForce: 100,
  maxQi: 140,
  currentQi: qi,
  speed: 100,
  criticalRate: 0,
  evasionRate: 0,
  defenseRate: 0,
  totalEquipmentAttack: 100,
  mainCultivationLayer: CultivationLayer.chuKui,
  availableSkills: const [],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: alive,
  teamSide: 0,
  slotIndex: id - 1,
);

ActivityMemberSnapshot _before(int id) => ActivityMemberSnapshot()
  ..characterId = id
  ..reservedEquipmentIds = []
  ..reservedTechniqueIds = []
  ..currentHp = 99999 // 哨兵：应被 finalState 覆盖
  ..currentQi = 99999
  ..isDowned = false;

BattleState _final(List<BattleCharacter> left, BattleResult result) =>
    BattleState.initial(
      leftTeam: left,
      rightTeam: const [],
    ).copyWith(result: result);

BossGauntletRun _run({
  required int stage,
  required List<ActivityMemberSnapshot> members,
}) => BossGauntletRun()
  ..saveDataId = 1
  ..seed = 1
  ..currentStage = stage
  ..sessionPhase = GauntletPhase.inBattle
  ..members = members;

void main() {
  test('胜利非终关 → interlude + currentStage++，快照继承战末生命/真气/阵亡', () {
    final run = _run(stage: 1, members: [_before(1), _before(2)]);
    final finalState = _final([
      _combatant(1, hp: 320, qi: 55, alive: true),
      _combatant(2, hp: 0, qi: 0, alive: false),
    ], BattleResult.leftWin);

    GauntletController.advance(
      run: run,
      finalState: finalState,
      isBossStage: false,
    );

    expect(run.currentStage, 2, reason: '胜利非终关推进到下一关');
    expect(run.sessionPhase, GauntletPhase.interlude, reason: '停整备不自动连打');
    expect(run.members[0].currentHp, 320, reason: '覆盖 before 哨兵');
    expect(run.members[0].currentQi, 55);
    expect(run.members[0].isDowned, false);
    expect(run.members[1].isDowned, true);
  });

  test('胜利终关(boss) → awaitingRewardChoice，currentStage 不变', () {
    final run = _run(stage: 3, members: [_before(1)]);
    final finalState = _final(
      [_combatant(1, hp: 200, qi: 40, alive: true)],
      BattleResult.leftWin,
    );

    GauntletController.advance(
      run: run,
      finalState: finalState,
      isBossStage: true,
    );

    expect(run.sessionPhase, GauntletPhase.awaitingRewardChoice);
    expect(run.currentStage, 3, reason: '终关胜不再 ++');
  });

  test('战败 → 不推进(停当前关)，但快照记战末态供 C2.5 失败结算', () {
    final run = _run(stage: 2, members: [_before(1)]);
    final finalState = _final(
      [_combatant(1, hp: 0, qi: 0, alive: false)],
      BattleResult.rightWin,
    );

    GauntletController.advance(
      run: run,
      finalState: finalState,
      isBossStage: false,
    );

    expect(run.currentStage, 2, reason: '战败不推进');
    expect(run.sessionPhase, GauntletPhase.inBattle, reason: '不进 interlude');
    expect(run.members[0].isDowned, true, reason: '战末态仍记录供失败结算');
  });

  test('平局 → 同战败不推进', () {
    final run = _run(stage: 1, members: [_before(1)]);
    final finalState = _final(
      [_combatant(1, hp: 500, qi: 30, alive: true)],
      BattleResult.draw,
    );

    GauntletController.advance(
      run: run,
      finalState: finalState,
      isBossStage: false,
    );

    expect(run.currentStage, 1);
    expect(run.sessionPhase, GauntletPhase.inBattle);
  });
}
