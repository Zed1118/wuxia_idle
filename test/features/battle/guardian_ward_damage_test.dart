/// floor30 护法结界 Task 3：承伤管线 ward 减伤单测。
///
/// 验 [DefaultGroundStrategy.wardMultOf] 纯函数（护法存活/全灭/非结界/空 ids）
/// + [DamageCalculator.calculateResolved] 末端 `defenderWardMult` 相乘行为。
/// 默认 1.0 = 零回归；结界生效时主伤害 × wardMult（85% 减伤 = 0.15）。
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

// ── Fixture builders ──────────────────────────────────────────────────────
// wardMultOf 纯测只用 ward 相关字段;e2e 测额外用 speed/hp/内力/技能 驱动真实结算。
BattleCharacter _mkChar({
  required int id,
  int teamSide = 1,
  bool isAlive = true,
  String? enemyDefId,
  double? guardianWardMult,
  List<String> guardianDefIds = const [],
  int speed = 100,
  int maxHp = 1000,
  int? currentHp,
  int currentInternalForce = 500,
  int maxInternalForce = 500,
  List<SkillDef> availableSkills = const [],
  int? slotIndex,
}) => BattleCharacter(
  characterId: id,
  name: 'c$id',
  realmTier: RealmTier.sanLiu,
  realmLayer: RealmLayer.yuanShu,
  school: TechniqueSchool.gangMeng,
  maxHp: maxHp,
  currentHp: currentHp ?? (isAlive ? maxHp : 0),
  maxInternalForce: maxInternalForce,
  currentInternalForce: currentInternalForce,
  speed: speed,
  criticalRate: 0,
  evasionRate: 0,
  // e2e 期望满伤 900:defenseRate 0 → defMult 1.0(纯测不读此字段)。
  defenseRate: 0,
  totalEquipmentAttack: 0,
  // chuKui = 基础层(cultMult 1.0),e2e 满伤 base=1000*0.4+0+500=900。
  mainCultivationLayer: CultivationLayer.chuKui,
  availableSkills: availableSkills,
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: isAlive,
  teamSide: teamSide,
  slotIndex: slotIndex ?? id,
  enemyDefId: enemyDefId,
  guardianWardMult: guardianWardMult,
  guardianDefIds: guardianDefIds,
);

SkillDef _mkSkill({required int power}) => SkillDef(
  id: 's',
  name: 'x',
  description: 'd',
  type: SkillType.normalAttack,
  powerMultiplier: power,
  internalForceCost: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: 'v',
);

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  group('DefaultGroundStrategy.wardMultOf', () {
    final boss = _mkChar(
      id: 1,
      enemyDefId: 'boss',
      guardianWardMult: 0.15,
      guardianDefIds: const ['g'],
    );
    final guardianAlive = _mkChar(id: 2, enemyDefId: 'g', isAlive: true);
    final guardianDead = _mkChar(id: 2, enemyDefId: 'g', isAlive: false);
    final plainEnemy = _mkChar(id: 3, enemyDefId: 'boss');

    final stateGuardianAlive = BattleState.initial(
      leftTeam: const [],
      rightTeam: [boss, guardianAlive],
    );
    final stateGuardianDead = BattleState.initial(
      leftTeam: const [],
      rightTeam: [boss, guardianDead],
    );

    test('护法存活 → wardMult 生效', () {
      expect(DefaultGroundStrategy.wardMultOf(boss, stateGuardianAlive), 0.15);
    });

    test('护法全灭 → 1.0', () {
      expect(DefaultGroundStrategy.wardMultOf(boss, stateGuardianDead), 1.0);
    });

    test('非结界单位(guardianWardMult null) → 1.0', () {
      expect(
        DefaultGroundStrategy.wardMultOf(plainEnemy, stateGuardianAlive),
        1.0,
      );
    });

    test('guardianDefIds 空 → 1.0', () {
      final bossNoIds = _mkChar(
        id: 4,
        enemyDefId: 'boss',
        guardianWardMult: 0.15,
        guardianDefIds: const [],
      );
      final state = BattleState.initial(
        leftTeam: const [],
        rightTeam: [bossNoIds, guardianAlive],
      );
      expect(DefaultGroundStrategy.wardMultOf(bossNoIds, state), 1.0);
    });

    // ── floor30 真实场景:双护法 OR 语义(结界撑到最后一个护法倒下)──
    test('多护法 OR:一死一活 → 仍生效(0.15)', () {
      final twoGuardBoss = _mkChar(
        id: 10,
        enemyDefId: 'boss',
        guardianWardMult: 0.15,
        guardianDefIds: const ['g1', 'g2'],
      );
      final g1Dead = _mkChar(id: 11, enemyDefId: 'g1', isAlive: false);
      final g2Alive = _mkChar(id: 12, enemyDefId: 'g2', isAlive: true);
      final state = BattleState.initial(
        leftTeam: const [],
        rightTeam: [twoGuardBoss, g1Dead, g2Alive],
      );
      expect(DefaultGroundStrategy.wardMultOf(twoGuardBoss, state), 0.15);
    });

    test('多护法 OR:全灭 → 1.0', () {
      final twoGuardBoss = _mkChar(
        id: 10,
        enemyDefId: 'boss',
        guardianWardMult: 0.15,
        guardianDefIds: const ['g1', 'g2'],
      );
      final g1Dead = _mkChar(id: 11, enemyDefId: 'g1', isAlive: false);
      final g2Dead = _mkChar(id: 12, enemyDefId: 'g2', isAlive: false);
      final state = BattleState.initial(
        leftTeam: const [],
        rightTeam: [twoGuardBoss, g1Dead, g2Dead],
      );
      expect(DefaultGroundStrategy.wardMultOf(twoGuardBoss, state), 1.0);
    });

    // ── teamSide==0 分支:结界单位在 leftTeam,须读 state.leftTeam ──
    test('leftTeam 分支:teamSide 0 护法存活 → 生效(0.15)', () {
      final leftBoss = _mkChar(
        id: 20,
        teamSide: 0,
        enemyDefId: 'boss',
        guardianWardMult: 0.15,
        guardianDefIds: const ['g'],
      );
      final leftGuardian = _mkChar(id: 21, teamSide: 0, enemyDefId: 'g');
      final state = BattleState.initial(
        leftTeam: [leftBoss, leftGuardian],
        rightTeam: const [],
      );
      expect(DefaultGroundStrategy.wardMultOf(leftBoss, state), 0.15);
    });

    test('leftTeam 分支:teamSide 0 护法死亡 → 1.0', () {
      final leftBoss = _mkChar(
        id: 20,
        teamSide: 0,
        enemyDefId: 'boss',
        guardianWardMult: 0.15,
        guardianDefIds: const ['g'],
      );
      final leftGuardianDead = _mkChar(
        id: 21,
        teamSide: 0,
        enemyDefId: 'g',
        isAlive: false,
      );
      final state = BattleState.initial(
        leftTeam: [leftBoss, leftGuardianDead],
        rightTeam: const [],
      );
      expect(DefaultGroundStrategy.wardMultOf(leftBoss, state), 1.0);
    });
  });

  group('DamageCalculator.defenderWardMult 末端相乘', () {
    AttackResult call({double wardMult = 1.0}) {
      final n = GameRepository.instance.numbers;
      return DamageCalculator.calculateResolved(
        attackerInternalForce: 1000,
        attackerEquipmentAttack: 100,
        attackerCultivationLayer: CultivationLayer.chuKui,
        attackerSchool: TechniqueSchool.gangMeng,
        defenderSchool: TechniqueSchool.gangMeng,
        attackerRealmTier: RealmTier.sanLiu,
        attackerRealmLayer: RealmLayer.qiMeng,
        defenderRealmTier: RealmTier.sanLiu,
        defenderRealmLayer: RealmLayer.qiMeng,
        defenderDefenseRate: 0.05,
        defenderEvasionRate: 0.0,
        attackerCriticalRate: 0.0,
        attackPowerMultiplier: 1.0,
        skill: _mkSkill(power: 500),
        n: n,
        rng: Random(0),
        defenderWardMult: wardMult,
      );
    }

    test('默认 1.0 = 零回归', () {
      // base=(1000*0.4+100+500)=1000; *0.95(def)=950。
      expect(call().mainDamage, 950);
    });

    test('结界 0.15 → 主伤害 ≈ 满伤 ×0.15（容差兜 toInt 截断）', () {
      final full = call().mainDamage;
      final warded = call(wardMult: 0.15).mainDamage;
      expect(warded, closeTo(full * 0.15, full * 0.02 + 1));
      expect(warded, lessThan(full));
    });
  });

  // ── 端到端:守 default_ground_strategy 结算路径确实透传 wardMultOf ──
  // 真实跑 strategy.tick:玩家攻结界 Boss;护法存活 → Boss 承伤 ≈满伤 ×0.15,
  // 护法死亡 → 满伤。若有人删掉 `defenderWardMult: wardMultOf(...)` 实参,
  // 护法存活分支会退回满伤 → 本测失败(wiring 回归守卫)。
  group('端到端 wiring:strategy 结算透传 wardMultOf', () {
    const profAtk = SkillDef(
      id: 'prof_atk',
      name: '普攻',
      description: 'e2e stub',
      type: SkillType.normalAttack,
      powerMultiplier: 500,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      visualEffect: 'stub',
    );
    const strategy = DefaultGroundStrategy();

    // 玩家(快,先手)攻结界 Boss;Boss hp<护法 → AI 选最低血目标恒锁 Boss。
    // 返回玩家首次命中 Boss(targetId==2)的 finalDamage。
    int firstBossHit({required bool guardianAlive}) {
      final n = GameRepository.instance.numbers;
      final player = _mkChar(
        id: 1,
        teamSide: 0,
        speed: 400,
        maxHp: 12000,
        currentHp: 12000,
        currentInternalForce: 1000,
        maxInternalForce: 10000,
        availableSkills: const [profAtk],
        slotIndex: 0,
      );
      final boss = _mkChar(
        id: 2,
        teamSide: 1,
        enemyDefId: 'boss',
        guardianWardMult: 0.15,
        guardianDefIds: const ['g'],
        speed: 1,
        maxHp: 100000,
        currentHp: 40000, // < 护法 → AI 锁 Boss
        availableSkills: const [profAtk],
        slotIndex: 0,
      );
      final guardian = _mkChar(
        id: 3,
        teamSide: 1,
        enemyDefId: 'g',
        isAlive: guardianAlive,
        speed: 1,
        maxHp: 100000,
        currentHp: guardianAlive ? 50000 : 0,
        availableSkills: const [profAtk],
        slotIndex: 1,
      );
      var s = BattleState.initial(
        leftTeam: [player],
        rightTeam: [boss, guardian],
      );
      final rng = Random(7);
      var guard = 0;
      while (guard < 200 && !s.isFinished) {
        s = strategy.tick(s, n, rng: rng);
        for (final a in s.actionLog) {
          if (a.actorId == 1 &&
              a.targetId == 2 &&
              a.attackResult != null &&
              !a.attackResult!.isDodged) {
            return a.attackResult!.finalDamage;
          }
        }
        guard++;
      }
      fail('玩家未命中结界 Boss');
    }

    test('护法存活 → Boss 承伤减免;护法死亡 → 满伤', () {
      // 满伤 base=1000*0.4+0+500=900;同流派/同境界/无防御/不闪不暴 → 900。
      final full = firstBossHit(guardianAlive: false);
      final warded = firstBossHit(guardianAlive: true);
      expect(full, 900);
      expect(warded, 135); // 900 × 0.15 = 135
      expect(warded, lessThan(full));
    });
  });
}
