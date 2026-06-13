import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// 半手动战斗 P0 步骤5-A:BattleNotifier 暴露可回溯 seed。
///
/// 首通手动通关要把本场 seed 落盘(`BattleReplayRecord.seed`),之后自动战斗
/// 同 seed 确定性重演。Dart `Random(seed)` 的种子不可从实例回溯,故 startBattle
/// 不传 seed 时也要**生成并存**一个可回溯种子;getter 读回供落盘采集。
void main() {
  const normal = SkillDef(
    id: 'skill_seed_capture_normal',
    name: '普攻',
    description: 'seed capture 测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter unit(int charId, int teamSide, int slot) => BattleCharacter(
        characterId: charId,
        name: '$charId',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 12000,
        currentHp: 12000,
        maxInternalForce: 2000,
        currentInternalForce: 2000,
        speed: 110,
        criticalRate: 0.0,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: 700,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: teamSide,
        slotIndex: slot,
      );

  List<BattleCharacter> team(int side) =>
      [unit(side == 0 ? 1 : -1, side, 0)];

  test('startBattle 不传 seed 生成可回溯 seed; 传 seed 则原样存', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(battleProvider.notifier);

    notifier.startBattle(team(0), team(1));
    final generated = notifier.seed;
    expect(generated, isNot(0), reason: '不传 seed 应生成可回溯种子(非默认 0)');

    notifier.startBattle(team(0), team(1), seed: 12345);
    expect(notifier.seed, 12345, reason: '显式 seed 原样存,供落盘采集');
  });
}
