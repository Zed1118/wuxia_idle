import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

/// Fix 验证：识破词条注入 chargeSkillId 的同时把该技能加入 availableSkills。
///
/// 修复前：_enemyToBattle 设了 chargeSkillId=shipo.chargeSkillId，但 skills 列表
/// 只来自 enemy.skillIds，battle_ai._pickSkill 只迭代 availableSkills → AI 永远
/// 选不到 chargeSkillId → 识破死机制。
///
/// 修复后：当 识破 注入时，把 shipo.chargeSkillId 对应的 SkillDef 同时追加到
/// availableSkills，AI 才能执行蓄力路径。
///
/// 本测 3 层防御：
///   T1 - 单元层：chargeSkillId 注入后 availableSkills 必含该技能。
///   T2 - 单元层：availableSkills 已含该技能后不重复追加。
///   T3 - 集成 e2e：真实 1v1 战斗（strategy.tick 驱动，固定 seed），断言
///        敌人在有限步内达到 chargingSkill != null（蓄力真的被 AI 选到）。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // ── 普通主线敌人：无技能 + 无自带蓄力技（cycle 3 识破会注入）─────────────
  const shipoEnemy = EnemyDef(
    id: 'test_shipo_enemy',
    name: '识破测试敌人',
    realmTier: RealmTier.yiLiu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    baseHp: 20000,
    baseAttack: 600,
    baseSpeed: 80, // 慢于玩家，保证玩家先动（降低 rng 干扰）
    skillIds: [], // 无技能 → 识破追加的才是唯一蓄力源
    iconPath: 'assets/enemies/stub.png',
    isBoss: true, // Boss 才会触发蓄力状态机
  );

  // T1：识破注入后 availableSkills 含蓄力技 ──────────────────────────────────
  test('T1: 识破注入 chargeSkillId → availableSkills 含对应技能', () {
    final ce = GameRepository.instance.numbers.cycleEvolution;
    final shipoSkillId = ce.traits.shipo.chargeSkillId;

    // cycle 3 主线：assignment=[yuti,fanzhen,shipo]，触发识破
    final enemy = StageBattleSetup.debugEnemyToBattle(
      enemy: shipoEnemy,
      slotIndex: 0,
      cycleIndex: 3,
      isTower: false,
    );

    expect(enemy.chargeSkillId, shipoSkillId,
        reason: '识破：chargeSkillId 已注入');
    expect(
      enemy.availableSkills.any((s) => s.id == shipoSkillId),
      isTrue,
      reason: '识破：蓄力技必须出现在 availableSkills，否则 AI 选不到',
    );
  });

  // T2：敌自带技能时识破追加不重复 ────────────────────────────────────────────
  test('T2: 识破注入时 availableSkills 长度恰好 +1（无重复追加）', () {
    final ce = GameRepository.instance.numbers.cycleEvolution;
    final shipoSkillId = ce.traits.shipo.chargeSkillId;

    // 敌已有 shipoSkillId 在 skillIds 中时，不应重复追加
    final enemyWithSkill = EnemyDef(
      id: 'test_shipo_already_has',
      name: '已有蓄力技敌人',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      baseHp: 20000,
      baseAttack: 600,
      baseSpeed: 80,
      skillIds: [shipoSkillId], // 已含
      iconPath: 'assets/enemies/stub.png',
      isBoss: true,
    );

    final c3 = StageBattleSetup.debugEnemyToBattle(
      enemy: enemyWithSkill,
      slotIndex: 0,
      cycleIndex: 3,
      isTower: false,
    );

    // 已含时长度 == 1（不重复追加）
    expect(
      c3.availableSkills.where((s) => s.id == shipoSkillId).length,
      1,
      reason: 'shipoSkillId 已在 enemy.skillIds 中，追加逻辑不应重复',
    );
  });

  // T3：e2e 战斗 — 识破敌在有限步内真正进入蓄力 ────────────────────────────
  test(
      'T3: 识破敌在真实战斗中（固定 seed）达到 chargingSkill != null（蓄力机制 live）',
      () {
    final numbers = GameRepository.instance.numbers;
    final ce = numbers.cycleEvolution;
    final shipoSkillId = ce.traits.shipo.chargeSkillId;

    // ── 构造识破敌人 ──
    final enemy = StageBattleSetup.debugEnemyToBattle(
      enemy: shipoEnemy,
      slotIndex: 0,
      cycleIndex: 3,
      isTower: false,
    );

    // 前置断言：结构层正确（保证 T3 e2e 部分的前提成立）
    expect(enemy.chargeSkillId, shipoSkillId,
        reason: 'T3 前提: chargeSkillId 已注入');
    expect(enemy.availableSkills.any((s) => s.id == shipoSkillId), isTrue,
        reason: 'T3 前提: 蓄力技在 availableSkills');

    // ── 构造玩家（极慢 + 极低攻击，避免打死 Boss 妨碍蓄力观察）──
    const playerNormal = SkillDef(
      id: 'skill_shipo_test_normal',
      name: '测试普攻',
      description: '识破 e2e 测试用普攻',
      type: SkillType.normalAttack,
      powerMultiplier: 50,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      visualEffect: 'stub',
    );
    const player = BattleCharacter(
      characterId: 1,
      name: '测试玩家',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 15000,
      currentHp: 15000,
      maxInternalForce: 8000,
      currentInternalForce: 0,
      speed: 50, // 远慢于敌（speed=80），让敌先行动
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 0, // 极低攻击，不会在蓄力触发前打死 Boss
      mainCultivationLayer: CultivationLayer.chuKui,
      availableSkills: [playerNormal],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: 0,
    );

    var state = BattleState.initial(leftTeam: [player], rightTeam: [enemy]);
    const strategy = DefaultGroundStrategy();
    final rng = Random(42);

    BattleCharacter enemyOf(BattleState s) =>
        s.rightTeam.firstWhere((c) => c.characterId == -1);

    // ── 推进战斗，最多 300 步 ──
    var guard = 0;
    while (guard < 300 && !state.isFinished) {
      state = strategy.tick(state, numbers, rng: rng);
      if (enemyOf(state).chargingSkill != null) break;
      guard++;
    }

    expect(
      enemyOf(state).chargingSkill,
      isNotNull,
      reason:
          '识破敌在 $guard 步内应进入蓄力状态（chargingSkill != null），'
          '证明 AI 真正选到了 chargeSkillId 对应的技能。'
          '若此断言 FAIL = availableSkills 修复未生效或 AI 路径错误。',
    );
    expect(
      enemyOf(state).chargingSkill!.id,
      shipoSkillId,
      reason: '蓄力技 id 应等于 shipo.chargeSkillId',
    );
  });
}
