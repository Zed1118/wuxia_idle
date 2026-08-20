import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/enemy_combatant_snapshot_assembler.dart';
import 'package:wuxia_idle/features/battle/application/legacy_3v3_combatant_adapter.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

import '../../../support/test_data.dart';

Object _shape(BattleCharacter character) => (
  characterId: character.characterId,
  name: character.name,
  realmTier: character.realmTier,
  realmLayer: character.realmLayer,
  school: character.school,
  maxHp: character.maxHp,
  currentHp: character.currentHp,
  internalForce: character.internalForce,
  maxQi: character.maxQi,
  currentQi: character.currentQi,
  speed: character.speed,
  criticalRate: character.criticalRate,
  evasionRate: character.evasionRate,
  defenseRate: character.defenseRate,
  totalEquipmentAttack: character.totalEquipmentAttack,
  cultivation: character.mainCultivationLayer,
  skills: character.availableSkills.map((skill) => skill.id).join(','),
  cooldowns: character.skillCooldowns.toString(),
  buffs: character.activeBuffs.join(','),
  teamSide: character.teamSide,
  slotIndex: character.slotIndex,
  iconPath: character.iconPath,
  isBoss: character.isBoss,
  chargeSkillId: character.chargeSkillId,
  bossPhaseIndex: character.bossPhaseIndex,
  bossPhases: character.bossPhases
      ?.map((phase) => '${phase.hpThresholdPct}:${phase.aiMode}')
      .join(','),
  phaseSkills: character.bossPhaseUnlockSkills
      ?.map((skills) => skills.map((skill) => skill.id).join('+'))
      .join(','),
  weaknesses: character.schoolDamageTakenMult.toString(),
  enemyDefId: character.enemyDefId,
  guardianWardMult: character.guardianWardMult,
  guardianDefIds: character.guardianDefIds.join(','),
  vulnerabilityMult: character.vulnerabilityMult,
  guardInterceptsInterrupt: character.guardInterceptsInterrupt,
);

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  test('新 Module 与旧 Adapter 在关键敌人矩阵逐字段同值', () {
    for (final stageId in ['stage_01_01', 'stage_01_05', 'stage_17_05']) {
      final stage = repo.getStage(stageId);
      for (final cycle in [1, 2, 3]) {
        for (final readable in [false, true]) {
          final legacy = StageBattleSetup.buildEnemyTeam(
            stage.enemyTeam,
            cycleIndex: cycle,
            isTower: false,
            advanceRealmPerCycle: false,
            stageNpcId: stage.isBossStage ? stage.npcId : null,
            readableFirstClearTuning: readable,
          );
          final extracted = EnemyCombatantSnapshotAssembler.assembleAll(
            stage.enemyTeam,
            cycleIndex: cycle,
            isTower: false,
            advanceRealmPerCycle: false,
            stageNpcId: stage.isBossStage ? stage.npcId : null,
            readableFirstClearTuning: readable,
          );
          expect(
            [
              for (final (index, snapshot) in extracted.indexed)
                _shape(
                  Legacy3v3CombatantAdapter.fromSnapshot(
                    snapshot,
                    teamSide: 1,
                    slotIndex: index,
                  ),
                ),
            ],
            legacy.map(_shape).toList(),
            reason: '$stageId cycle=$cycle readable=$readable',
          );
        }
      }
    }
  });

  test('可复用 seam 不继承旧 3 人 cap；legacy Adapter 仍截前三人', () {
    final template = repo.getStage('stage_01_01').enemyTeam.single;
    final four = <EnemyDef>[template, template, template, template];
    expect(EnemyCombatantSnapshotAssembler.assembleAll(four), hasLength(4));
    expect(StageBattleSetup.buildEnemyTeam(four), hasLength(3));
  });
}
