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
BattleCharacter _mkChar({
  required int id,
  int teamSide = 1,
  bool isAlive = true,
  String? enemyDefId,
  double? guardianWardMult,
  List<String> guardianDefIds = const [],
}) => BattleCharacter(
  characterId: id,
  name: 'c$id',
  realmTier: RealmTier.sanLiu,
  realmLayer: RealmLayer.yuanShu,
  school: TechniqueSchool.gangMeng,
  maxHp: 1000,
  currentHp: isAlive ? 1000 : 0,
  maxInternalForce: 500,
  currentInternalForce: 500,
  speed: 100,
  criticalRate: 0,
  evasionRate: 0,
  defenseRate: 0.1,
  totalEquipmentAttack: 0,
  mainCultivationLayer: CultivationLayer.daCheng,
  availableSkills: const [],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: isAlive,
  teamSide: teamSide,
  slotIndex: id,
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
}
