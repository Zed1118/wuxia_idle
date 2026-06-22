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
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  const normal = SkillDef(
    id: 'skill_adv1_normal',
    name: '普攻',
    description: 'adv1 普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const power = SkillDef(
    id: 'skill_adv1_power',
    name: '强力技',
    description: 'adv1 强力技',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter unit({
    required int charId,
    required int teamSide,
    required int slot,
    required int speed,
    required int equipAttack,
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
        speed: speed,
        criticalRate: 0.5,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: equipAttack,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[power, normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: teamSide,
        slotIndex: slot,
      );

  List<BattleCharacter> leftTeam() => [
        unit(charId: 1, teamSide: 0, slot: 0, speed: 130, equipAttack: 700),
        unit(charId: 2, teamSide: 0, slot: 1, speed: 120, equipAttack: 700),
        unit(charId: 3, teamSide: 0, slot: 2, speed: 110, equipAttack: 700),
      ];
  List<BattleCharacter> rightTeam() => [
        unit(charId: -1, teamSide: 1, slot: 0, speed: 105, equipAttack: 450),
        unit(charId: -2, teamSide: 1, slot: 1, speed: 100, equipAttack: 450),
        unit(charId: -3, teamSide: 1, slot: 2, speed: 95, equipAttack: 450),
      ];

  // 与 battle_step_one_test.dart 的 action-log fingerprint 故意逐字复刻,
  // 锁定同一格式(同 seed 全等比对依赖两测产出可逐字符比较)。各 battle 测
  // 文件按此约定各自重复 fixtures,不抽公共 helper(避免部分一致)。
  String summarize(BattleState s) =>
      '${s.result}#${s.actionLog.map((a) => '${a.tick}|${a.actorId}|${a.targetId}|${a.skill?.id}|${a.attackResult?.finalDamage}|${a.interrupted}').join(';')}';

  String runVia(int seed, {required bool oneAction}) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);
    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(leftTeam(), rightTeam(), seed: seed);
    var guard = 0;
    while (!container.read(battleProvider).isFinished && guard < 30000) {
      if (oneAction) {
        notifier.advanceOneAction();
      } else {
        notifier.advance();
      }
      guard++;
    }
    return summarize(container.read(battleProvider));
  }

  test('advanceOneAction 每次调用 actionLog 恰好 +1（或战斗已结束）', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);
    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(leftTeam(), rightTeam(), seed: 2468);

    var prevLen = container.read(battleProvider).actionLog.length;
    var calls = 0;
    while (!container.read(battleProvider).isFinished && calls < 30000) {
      notifier.advanceOneAction();
      final len = container.read(battleProvider).actionLog.length;
      if (container.read(battleProvider).isFinished && len == prevLen) break;
      expect(len, prevLen + 1,
          reason: '单次 advanceOneAction 只产出一个 action（自动跳过空 tick 边界）');
      prevLen = len;
      calls++;
    }
    expect(calls, greaterThan(10), reason: '防空过：需足够多产出步');
  });

  test('红线：advanceOneAction 逐拍跑完 == advance 整 tick 跑完（同 seed 全等）', () {
    final viaOne = runVia(2468, oneAction: true);
    final viaAdvance = runVia(2468, oneAction: false);
    expect(viaOne.split(';').length, greaterThan(10),
        reason: '防空过：需足够多 action 暴露 rng 顺序不一致');
    expect(viaOne, equals(viaAdvance),
        reason: 'advanceOneAction 与 advance 单一 seeded rng 下复刻同一场战斗');
  });
}
