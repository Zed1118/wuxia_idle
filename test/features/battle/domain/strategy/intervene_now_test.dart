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
    await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
  });

  const power = SkillDef(
    id: 'skill_iv_power',
    name: '截脉手',
    description: '插队测强力技',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const normal = SkillDef(
    id: 'skill_iv_normal',
    name: '普攻',
    description: '插队测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter unit({
    required int charId,
    required int teamSide,
    required int slot,
    int ap = 0,
  }) =>
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
        speed: 120,
        criticalRate: 0.0,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: 700,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[power, normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: ap,
        isAlive: true,
        teamSide: teamSide,
        slotIndex: slot,
      );

  test('AP 未满的玩家角色拖招 → 立即出手 + AP 归零 + 命中指定目标', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final state = BattleState.initial(
      leftTeam: [unit(charId: 1, teamSide: 0, slot: 0, ap: 300)],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );

    final after = strat.interveneNow(
      state, 1, power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );

    final acted = after.actionLog.where((a) => a.actorId == 1).toList();
    expect(acted, isNotEmpty, reason: '拖招应立即结算一次行动');
    expect(acted.last.skill?.id, 'skill_iv_power');
    expect(acted.last.targetId, -1);

    final actor = after.leftTeam.firstWhere((c) => c.characterId == 1);
    expect(actor.actionPoint, 0, reason: '预支语义:出手后 AP 归零');

    expect(after.pendingUltimates.containsKey(1), isFalse);
    expect(after.pendingTargets.containsKey(1), isFalse);
  });

  test('已死角色拖招 → noop（state 不变）', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final dead = unit(charId: 1, teamSide: 0, slot: 0)
        .copyWith(currentHp: 0, isAlive: false);
    final state = BattleState.initial(
      leftTeam: [dead],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );
    final after = strat.interveneNow(state, 1, power, targetId: -1, n: n, rng: Random(7));
    expect(after.actionLog, isEmpty);
  });
}
