import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// 半手动战斗 P0 步骤2:操作序列 in-memory 记录。
///
/// 每次 [BattleNotifier.requestUltimate] 记一条 `{anchor=state.tick, charId,
/// skillId, targetId}` 到 in-memory 序列([BattleNotifier.recordedOps]),供
/// 步骤4 重放、步骤5 落盘。锚点用 `state.tick`(spec §八#6 用户拍板)。
void main() {
  setUpAll(() async {
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  const normal = SkillDef(
    id: 'skill_replay_rec_normal',
    name: '普攻',
    description: 'op 记录测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const power = SkillDef(
    id: 'skill_replay_rec_power',
    name: '强力技',
    description: 'op 记录测强力技',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 2,
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
        speed: teamSide == 0 ? 120 : 100,
        criticalRate: 0.0,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: teamSide == 0 ? 700 : 450,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[power, normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: teamSide,
        slotIndex: slot,
      );

  List<BattleCharacter> leftTeam() => [unit(1, 0, 0), unit(2, 0, 1)];
  List<BattleCharacter> rightTeam() => [unit(-1, 1, 0), unit(-2, 1, 1)];

  ({ProviderContainer container, BattleNotifier notifier}) freshBattle(int seed) {
    final container = ProviderContainer();
    final sub =
        container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);
    addTearDown(container.dispose);
    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(leftTeam(), rightTeam(), seed: seed);
    return (container: container, notifier: notifier);
  }

  test('requestUltimate 记录 op(锚点=当前 state.tick + charId + skillId)', () {
    final b = freshBattle(1);
    b.notifier.advance(); // 推进让 tick 前进,锚点非 0 才有意义
    final anchorTick = b.container.read(battleProvider).tick;
    expect(anchorTick, greaterThan(0));

    b.notifier.requestUltimate(1, power);

    expect(b.notifier.recordedOps, hasLength(1));
    final op = b.notifier.recordedOps.single;
    expect(op.anchor, anchorTick);
    expect(op.charId, 1);
    expect(op.skillId, power.id);
  });

  test('多次 requestUltimate 按序追加', () {
    final b = freshBattle(1);
    b.notifier.advance();
    b.notifier.requestUltimate(1, power);
    b.notifier.advance();
    b.notifier.requestUltimate(2, power);

    expect(b.notifier.recordedOps, hasLength(2));
    expect(b.notifier.recordedOps.map((o) => o.charId), [1, 2]);
  });

  test('startBattle 清空上一场 recordedOps', () {
    final b = freshBattle(1);
    b.notifier.advance();
    b.notifier.requestUltimate(1, power);
    expect(b.notifier.recordedOps, isNotEmpty);

    // 同一 notifier 重开新战斗 → 记录清零。
    b.notifier.startBattle(leftTeam(), rightTeam(), seed: 2);
    expect(b.notifier.recordedOps, isEmpty);
  });
}
