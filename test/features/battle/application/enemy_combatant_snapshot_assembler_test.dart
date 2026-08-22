import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/shared/battle_shared/enemy_combatant_snapshot_assembler.dart';

import '../../../support/test_data.dart';

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await loadTestGameRepository();
  });

  test('代表关卡逐敌装配完整 neutral snapshot', () {
    for (final stageId in ['stage_01_01', 'stage_01_05', 'stage_17_05']) {
      final stage = repo.getStage(stageId);
      final snapshots = EnemyCombatantSnapshotAssembler.assembleAll(
        stage.enemyTeam,
        stageNpcId: stage.isBossStage ? stage.npcId : null,
      );

      expect(snapshots, hasLength(stage.enemyTeam.length), reason: stageId);
      for (final (index, snapshot) in snapshots.indexed) {
        final enemy = stage.enemyTeam[index];
        expect(snapshot.name, enemy.name, reason: stageId);
        expect(snapshot.realmTier, enemy.realmTier, reason: stageId);
        expect(snapshot.realmLayer, enemy.realmLayer, reason: stageId);
        expect(snapshot.school, enemy.school, reason: stageId);
        expect(snapshot.maxHp, enemy.baseHp, reason: stageId);
        expect(snapshot.currentHp, snapshot.maxHp, reason: stageId);
        expect(snapshot.speed, enemy.baseSpeed, reason: stageId);
        expect(
          snapshot.totalEquipmentAttack,
          enemy.baseAttack,
          reason: stageId,
        );
        expect(snapshot.isBoss, enemy.isBoss, reason: stageId);
        expect(snapshot.chargeSkillId, enemy.chargeSkillId, reason: stageId);
        expect(snapshot.enemyDefId, enemy.id, reason: stageId);
        expect(snapshot.iconPath, enemy.iconPath, reason: stageId);
        expect(
          snapshot.availableSkills.map((skill) => skill.id),
          containsAll(enemy.skillIds),
          reason: stageId,
        );
      }
    }
  });

  test('neutral seam 保留全部敌人，不继承旧三人容量限制', () {
    final template = repo.getStage('stage_01_01').enemyTeam.single;
    final four = <EnemyDef>[template, template, template, template];

    expect(EnemyCombatantSnapshotAssembler.assembleAll(four), hasLength(4));
  });

  test('assembler 直接构造 neutral snapshot，不回引已退役战斗角色', () {
    final source = File(
      'lib/shared/battle_shared/enemy_combatant_snapshot_assembler.dart',
    ).readAsStringSync();

    expect(source, contains('CombatantSnapshot('));
    expect(source, isNot(contains('battle_state.dart')));
    expect(source, isNot(contains('legacy_3v3_combatant_adapter.dart')));
    expect(source, isNot(matches(RegExp(r'\bBattleCharacter\b'))));
  });
}
