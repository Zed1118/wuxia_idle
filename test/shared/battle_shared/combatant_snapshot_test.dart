import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

SkillDef skill(String id) => SkillDef(
  id: id,
  name: id,
  description: id,
  type: SkillType.normalAttack,
  powerMultiplier: 1,
  qiDelta: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: '',
);

CombatantSnapshot fixture({
  required List<SkillDef> skills,
  required List<List<SkillDef>> unlocks,
}) => CombatantSnapshot(
  characterId: -1,
  name: 'enemy',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.ruMen,
  school: TechniqueSchool.gangMeng,
  maxHp: 100,
  currentHp: 100,
  internalForce: 10,
  maxQi: 20,
  currentQi: 20,
  qiGainMultiplier: 1,
  qiCostReductionPct: 0,
  autoUltimate: false,
  speed: 1,
  criticalRate: 0,
  evasionRate: 0,
  defenseRate: 0,
  totalEquipmentAttack: 1,
  mainCultivationLayer: CultivationLayer.chuKui,
  availableSkills: skills,
  openingSkillCooldowns: {'x': 1},
  skillUses: {'x': 2},
  activeBuffs: ['b'],
  swordSongResonanceActive: false,
  iconPath: null,
  attackPowerMultiplier: 1,
  outputMultiplier: 1,
  isBoss: true,
  chargeSkillId: null,
  bossPhases: null,
  bossPhaseUnlockSkills: unlocks,
  schoolDamageTakenMult: {},
  lineageRole: null,
  forgingPiercePct: 0,
  forgingLifestealPct: 0,
  enemyDefId: null,
  guardianWardMult: null,
  guardianDefIds: [],
  vulnerabilityMult: null,
  guardInterceptsInterrupt: false,
);

void main() {
  test('所有输入集合（含 SkillDef 嵌套列表）防御性不可变', () {
    final skills = <SkillDef>[skill('a')];
    final unlocks = <List<SkillDef>>[
      [skill('b')],
    ];
    final snapshot = fixture(skills: skills, unlocks: unlocks);
    skills.add(skill('mutated'));
    unlocks.single.add(skill('nested'));
    expect(snapshot.availableSkills, hasLength(1));
    expect(snapshot.bossPhaseUnlockSkills!.single, hasLength(1));
    expect(
      () => snapshot.availableSkills.add(skill('x')),
      throwsUnsupportedError,
    );
    expect(
      () => snapshot.bossPhaseUnlockSkills!.single.add(skill('x')),
      throwsUnsupportedError,
    );
    expect(
      () => snapshot.openingSkillCooldowns['x'] = 9,
      throwsUnsupportedError,
    );
  });

  test('neutral schema 不暴露旧 3v3 运行态字段', () {
    final source = File(
      'lib/shared/battle_shared/combatant_snapshot.dart',
    ).readAsStringSync();
    for (final field in [
      'teamSide',
      'slotIndex',
      'actionPoint',
      'isAlive',
      'internalInjury',
      'chargingSkill',
      'chargeTicksRemaining',
      'staggerTicksRemaining',
      'staggerDefenseDownOverride',
      'bossPhaseIndex',
      'coopStrikeUsedInCharge',
      'coopStrikeConsumedAtTick',
    ]) {
      expect(source, isNot(contains(field)), reason: 'schema leaks $field');
    }
  });
}
