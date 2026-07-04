import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/defs/stage_win_condition.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// 终局机制型 Boss 批次3 Task 2:限时生存胜负条件红线。
///
/// [BattleState.winCondition] 由 [BattleNotifier.startBattle] 透传;
/// `surviveTicks` 型在 `DefaultGroundStrategy.stepOne` 的 tick 边界逐 tick 判定:
/// tick≥N 且左队存活 → leftWin,与「右队全灭→leftWin」两通道并存(任一即胜)。
///
/// **确定性设计**:全部 fixture 用 `criticalRate: 0.0` + `evasionRate: 0.0`
/// 消灭 rng 依赖(伤害公式中闪避/暴击是仅有的两处 rng 消费点),使四个场景的分歧
/// 完全由 equipAttack / defenseRate / speed / maxHp 决定,与 seed 无关
/// (仍传固定 seed 只为满足 startBattle 签名,不参与结果分歧)。
/// 同 school(gangMeng)+ 同 realm + 同 cultivation layer(chuKui,100%)
/// 消去流派克制/境界差/修炼度倍率,使 finalDamage = equipAttack * (1-defenseRate)
/// (skill.powerMultiplier=0,internalForce=0)——精确可控。
void main() {
  setUpAll(() async {
    // loadAllDefs 副作用设 GameRepository.instance 单例;numbersConfigProvider
    // 默认实现读该单例(与 battle_seed_determinism_test 同构)。
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  const normal = SkillDef(
    id: 'skill_survive_wc_normal',
    name: '普攻',
    description: '限时生存胜负条件测试用普攻(无内力消耗/无 CD)',
    type: SkillType.normalAttack,
    powerMultiplier: 0,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter mkChar({
    required int charId,
    required int teamSide,
    required int slot,
    required int speed,
    required int equipAttack,
    required int maxHp,
    required double defenseRate,
  }) => BattleCharacter(
    characterId: charId,
    name: 'c$charId',
    realmTier: RealmTier.yiLiu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    maxHp: maxHp,
    currentHp: maxHp,
    maxInternalForce: 0,
    currentInternalForce: 0,
    speed: speed,
    criticalRate: 0.0,
    evasionRate: 0.0,
    defenseRate: defenseRate,
    totalEquipmentAttack: equipAttack,
    mainCultivationLayer: CultivationLayer.chuKui,
    availableSkills: const [normal],
    skillCooldowns: const {},
    activeBuffs: const [],
    actionPoint: 0,
    isAlive: true,
    teamSide: teamSide,
    slotIndex: slot,
  );

  const survive40 = StageWinCondition(
    type: StageWinConditionType.surviveTicks,
    surviveTicksRequired: 40,
  );

  /// 经 ProviderContainer + notifier.advance 驱动跑到终局(或 guard 耗尽)。
  BattleState runToEndViaNotifier({
    required List<BattleCharacter> left,
    required List<BattleCharacter> right,
    required int seed,
    StageWinCondition? wc,
  }) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // 永久 listener 防 autoDispose 在 read 间隙释放 notifier(否则 state 丢失,
    // 依 project memory `feedback_wuxia_rngprovider_vs_dartmath_random` /
    // 既有 battle_seed_determinism_test 同构手法)。
    final sub = container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);

    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(left, right, seed: seed, winCondition: wc);

    var s = container.read(battleProvider);
    var guard = 0;
    while (!s.isFinished && guard++ < 3000) {
      notifier.advance();
      s = container.read(battleProvider);
    }
    return s;
  }

  test('surviveTicks: 双方低伤互耗撑过 40 tick,左队存活 → leftWin', () {
    // 双方各 3 人,伤害极低(equipAttack=40,defenseRate=0.5 → 20 dmg/hit)且
    // maxHp 高(5000),speed 中等(每 10 tick 出手一次)——40 tick 内双方都只
    // 掉几发子弹血,谁都死不了,tick 边界一到 40 即触发 survive 判定。
    final left = [
      mkChar(
        charId: 1,
        teamSide: 0,
        slot: 0,
        speed: 100,
        equipAttack: 40,
        maxHp: 5000,
        defenseRate: 0.5,
      ),
      mkChar(
        charId: 2,
        teamSide: 0,
        slot: 1,
        speed: 100,
        equipAttack: 40,
        maxHp: 5000,
        defenseRate: 0.5,
      ),
      mkChar(
        charId: 3,
        teamSide: 0,
        slot: 2,
        speed: 100,
        equipAttack: 40,
        maxHp: 5000,
        defenseRate: 0.5,
      ),
    ];
    final right = [
      mkChar(
        charId: -1,
        teamSide: 1,
        slot: 0,
        speed: 100,
        equipAttack: 40,
        maxHp: 5000,
        defenseRate: 0.5,
      ),
      mkChar(
        charId: -2,
        teamSide: 1,
        slot: 1,
        speed: 100,
        equipAttack: 40,
        maxHp: 5000,
        defenseRate: 0.5,
      ),
      mkChar(
        charId: -3,
        teamSide: 1,
        slot: 2,
        speed: 100,
        equipAttack: 40,
        maxHp: 5000,
        defenseRate: 0.5,
      ),
    ];

    final s = runToEndViaNotifier(
      left: left,
      right: right,
      seed: 12345,
      wc: survive40,
    );

    expect(s.result, BattleResult.leftWin);
    expect(s.tick, greaterThanOrEqualTo(40));
    expect(s.leftTeam.any((c) => c.isAlive), isTrue);
  });

  test('surviveTicks: 满配秒镜像(tick<40 右队全灭)→ leftWin(击败通道并存)', () {
    // 左队碾压:equipAttack=100000,defenseRate=0(右队) → 单发秒杀;speed=1000
    // → tick=1 就出手,3 人一 tick 内清光右队 3 人。
    final left = [
      mkChar(
        charId: 1,
        teamSide: 0,
        slot: 0,
        speed: 1000,
        equipAttack: 100000,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
      mkChar(
        charId: 2,
        teamSide: 0,
        slot: 1,
        speed: 1000,
        equipAttack: 100000,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
      mkChar(
        charId: 3,
        teamSide: 0,
        slot: 2,
        speed: 1000,
        equipAttack: 100000,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
    ];
    final right = [
      mkChar(
        charId: -1,
        teamSide: 1,
        slot: 0,
        speed: 10,
        equipAttack: 1,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
      mkChar(
        charId: -2,
        teamSide: 1,
        slot: 1,
        speed: 10,
        equipAttack: 1,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
      mkChar(
        charId: -3,
        teamSide: 1,
        slot: 2,
        speed: 10,
        equipAttack: 1,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
    ];

    final s = runToEndViaNotifier(
      left: left,
      right: right,
      seed: 777,
      wc: survive40,
    );

    expect(s.result, BattleResult.leftWin);
    expect(s.tick, lessThan(40));
    expect(s.rightTeam.every((c) => !c.isAlive), isTrue);
  });

  test('surviveTicks: 左队 tick<40 全灭 → rightWin(被击败,survive 未及生效)', () {
    // 右队碾压,左队玻璃大炮:right speed=1000/equipAttack=100000 秒杀 left
    // (defenseRate=0/maxHp=5000);left speed 极低,还没轮到出手就已全灭。
    final left = [
      mkChar(
        charId: 1,
        teamSide: 0,
        slot: 0,
        speed: 10,
        equipAttack: 1,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
      mkChar(
        charId: 2,
        teamSide: 0,
        slot: 1,
        speed: 10,
        equipAttack: 1,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
      mkChar(
        charId: 3,
        teamSide: 0,
        slot: 2,
        speed: 10,
        equipAttack: 1,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
    ];
    final right = [
      mkChar(
        charId: -1,
        teamSide: 1,
        slot: 0,
        speed: 1000,
        equipAttack: 100000,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
      mkChar(
        charId: -2,
        teamSide: 1,
        slot: 1,
        speed: 1000,
        equipAttack: 100000,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
      mkChar(
        charId: -3,
        teamSide: 1,
        slot: 2,
        speed: 1000,
        equipAttack: 100000,
        maxHp: 5000,
        defenseRate: 0.0,
      ),
    ];

    final s = runToEndViaNotifier(
      left: left,
      right: right,
      seed: 999,
      wc: survive40,
    );

    expect(s.result, BattleResult.rightWin);
    expect(s.tick, lessThan(40));
  });

  test('winCondition==null: 不因 tick 数提前判 leftWin(旧行为零影响)', () {
    // 双方 defenseRate=1.0 → defMult=0 → finalDamage 恒为 0(数学上永不掉血,
    // 见 damage_calculator: raw *= defMult, defMult=(1-1.0)=0)。wc=null 时
    // 无论 tick 推多久都不会触发 survive 判定;guard 耗尽后 result 应仍为 null
    // (isFinished=false)——绝不可能是 leftWin。
    final left = [
      mkChar(
        charId: 1,
        teamSide: 0,
        slot: 0,
        speed: 200,
        equipAttack: 999999,
        maxHp: 5000,
        defenseRate: 1.0,
      ),
      mkChar(
        charId: 2,
        teamSide: 0,
        slot: 1,
        speed: 200,
        equipAttack: 999999,
        maxHp: 5000,
        defenseRate: 1.0,
      ),
      mkChar(
        charId: 3,
        teamSide: 0,
        slot: 2,
        speed: 200,
        equipAttack: 999999,
        maxHp: 5000,
        defenseRate: 1.0,
      ),
    ];
    final right = [
      mkChar(
        charId: -1,
        teamSide: 1,
        slot: 0,
        speed: 200,
        equipAttack: 999999,
        maxHp: 5000,
        defenseRate: 1.0,
      ),
      mkChar(
        charId: -2,
        teamSide: 1,
        slot: 1,
        speed: 200,
        equipAttack: 999999,
        maxHp: 5000,
        defenseRate: 1.0,
      ),
      mkChar(
        charId: -3,
        teamSide: 1,
        slot: 2,
        speed: 200,
        equipAttack: 999999,
        maxHp: 5000,
        defenseRate: 1.0,
      ),
    ];

    final s = runToEndViaNotifier(left: left, right: right, seed: 1, wc: null);

    expect(s.result, isNot(BattleResult.leftWin));
    // 免疫局:guard 耗尽仍未结束(真实 0 伤害验证,而非侥幸打平)。
    expect(s.isFinished, isFalse);
  });
}
