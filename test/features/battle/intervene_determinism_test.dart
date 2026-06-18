import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

void main() {
  setUpAll(() async {
    await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
  });

  const power = SkillDef(
    id: 'skill_ivd_power',
    name: '强力技',
    description: '插队确定性测',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const normal = SkillDef(
    id: 'skill_ivd_normal',
    name: '普攻',
    description: '插队确定性测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter unit(int charId, int teamSide, int slot, int speed, int atk) =>
      BattleCharacter(
        characterId: charId,
        name: '$charId',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 12000,
        currentHp: 12000,
        maxInternalForce: 2000,
        currentInternalForce: 2000,
        speed: speed,
        criticalRate: 0.5,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: atk,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[power, normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: teamSide,
        slotIndex: slot,
      );

  String runOnce(int seed) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);
    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(
      [unit(1, 0, 0, 130, 700), unit(2, 0, 1, 120, 700), unit(3, 0, 2, 110, 700)],
      [unit(-1, 1, 0, 105, 450), unit(-2, 1, 1, 100, 450), unit(-3, 1, 2, 95, 450)],
      seed: seed,
    );
    for (var i = 0; i < 3 && !container.read(battleProvider).isFinished; i++) {
      notifier.advance();
    }
    notifier.interveneNow(1, power, targetId: -1);
    var guard = 0;
    while (!container.read(battleProvider).isFinished && guard < 3000) {
      notifier.advance();
      guard++;
    }
    final s = container.read(battleProvider);
    return '${s.result}#' +
        s.actionLog
            .map((a) =>
                '${a.tick}|${a.actorId}|${a.targetId}|${a.skill?.id}|${a.attackResult?.finalDamage}')
            .join(';');
  }

  test('红线:同 seed + 同插队时点两跑 actionLog + 胜负全等', () {
    final first = runOnce(20260618);
    final second = runOnce(20260618);
    expect(first.split(';').length, greaterThan(10));
    expect(first, equals(second),
        reason: 'interveneNow 走同一 seeded _rng,插队路径须确定');
  });
}
