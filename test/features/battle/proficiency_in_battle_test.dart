import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  const profAtk = SkillDef(
    id: 'prof_atk',
    name: '熟练普攻',
    description: 'C5 测试用',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 攻方快(先手),内力1000/装备0/普攻500 → base=1000*0.4+0+500=900;
  // 守方防御率0/同流派/同境界/不闪不暴 → finalDamage=900(uses=0);uses=800 → ×1.30=1170。
  BattleState makeState({required Map<String, int> skillUses}) {
    final attacker = BattleCharacter(
      characterId: 1,
      name: '攻',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 12000,
      currentHp: 12000,
      maxInternalForce: 10000,
      currentInternalForce: 1000,
      speed: 400,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.chuKui,
      availableSkills: const <SkillDef>[profAtk],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: 0,
      skillUses: skillUses,
    );
    const defender = BattleCharacter(
      characterId: -1,
      name: '守',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 50000,
      currentHp: 50000,
      maxInternalForce: 100,
      currentInternalForce: 0,
      speed: 1,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.chuKui,
      availableSkills: <SkillDef>[profAtk],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
    );
    return BattleState.initial(leftTeam: [attacker], rightTeam: [defender]);
  }

  const strategy = DefaultGroundStrategy();

  int firstHitOnDefender(Map<String, int> skillUses) {
    final n = GameRepository.instance.numbers;
    var s = makeState(skillUses: skillUses);
    final rng = Random(7);
    var guard = 0;
    while (guard < 200 && !s.isFinished) {
      s = strategy.tick(s, n, rng: rng);
      for (final a in s.actionLog) {
        if (a.actorId == 1 && a.attackResult != null && !a.attackResult!.isDodged) {
          return a.attackResult!.finalDamage;
        }
      }
      guard++;
    }
    fail('攻方未对守方造成伤害');
  }

  test('实战路径:skillUses=0 → 基线伤害', () {
    expect(firstHitOnDefender(const {}), 900);
  });

  test('实战路径:skillUses=800(huaJing) → 基线 ×1.30', () {
    expect(firstHitOnDefender(const {'prof_atk': 800}), 1170);
  });
}
