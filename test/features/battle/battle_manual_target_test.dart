import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// 半手动战斗 P0 步骤3a:手动选目标。
///
/// `requestUltimate(charId, skill, targetId:)` 让玩家指定该次手动技的目标;
/// [BattleAI.decide] 消费该指定目标(优先于「对面血最低」默认)。当前引擎
/// 全技能皆单体,§八#4「群体技自动」为前瞻条款(AoE 引入后那些技忽略
/// 指定目标)。指定目标随 [BattleNotifier.recordedOps] 一并记录供重放。
void main() {
  setUpAll(() async {
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  const normal = SkillDef(
    id: 'skill_manual_tgt_normal',
    name: '普攻',
    description: '手动目标测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const power = SkillDef(
    id: 'skill_manual_tgt_power',
    name: '强力技',
    description: '手动目标测强力技',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter unit({
    required int charId,
    required int teamSide,
    required int slot,
    required int hp,
    required int speed,
    List<SkillDef> skills = const [power, normal],
  }) =>
      BattleCharacter(
        characterId: charId,
        name: '$charId',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 12000,
        currentHp: hp,
        maxInternalForce: 5000,
        currentInternalForce: 5000,
        speed: speed,
        criticalRate: 0.0,
        evasionRate: 0.0,
        defenseRate: 0.0,
        totalEquipmentAttack: 600,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: skills,
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: teamSide,
        slotIndex: slot,
      );

  // 玩家 1(高速先手)vs 敌 -1(高血)/ 敌 -2(低血)。AI 默认打血最低 -2。
  List<BattleCharacter> leftTeam() =>
      [unit(charId: 1, teamSide: 0, slot: 0, hp: 12000, speed: 200)];
  List<BattleCharacter> rightTeam() => [
        unit(charId: -1, teamSide: 1, slot: 0, hp: 12000, speed: 100, skills: const [normal]),
        unit(charId: -2, teamSide: 1, slot: 1, hp: 3000, speed: 100, skills: const [normal]),
      ];

  ({ProviderContainer container, BattleNotifier notifier}) freshBattle() {
    final container = ProviderContainer();
    final sub =
        container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);
    addTearDown(container.dispose);
    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(leftTeam(), rightTeam(), seed: 1);
    return (container: container, notifier: notifier);
  }

  test('requestUltimate 指定目标 → 解析动作命中指定目标(非 AI 默认血最低)', () {
    final b = freshBattle();

    // 玩家手动请求强力技,指定打高血的 -1(AI 默认会打血最低的 -2)。
    b.notifier.requestUltimate(1, power, targetId: -1);

    // 推进到玩家这次行动落地。
    var guard = 0;
    BattleAction? playerHit;
    while (guard < 50 && playerHit == null) {
      b.notifier.advance();
      final log = b.container.read(battleProvider).actionLog;
      for (final a in log) {
        if (a.actorId == 1 && a.skill?.id == power.id) {
          playerHit = a;
          break;
        }
      }
      if (b.container.read(battleProvider).isFinished) break;
      guard++;
    }

    expect(playerHit, isNotNull, reason: '玩家应使出指定的强力技');
    expect(playerHit!.targetId, -1,
        reason: '手动指定目标 -1 应被消费,而非 AI 默认血最低 -2');
  });

  test('指定目标随 recordedOps 一并记录', () {
    final b = freshBattle();
    b.notifier.requestUltimate(1, power, targetId: -1);
    expect(b.notifier.recordedOps.single.targetId, -1);
  });
}
