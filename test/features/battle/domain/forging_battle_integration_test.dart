import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// Task 4:开锋破甲 / 吸血接战斗集成测试。
///
/// 验证目标:
/// - **吸血(lifesteal)**:攻方 `forgingLifestealPct > 0` 时，攻击命中后
///   currentHp 应因回血高于无 lifesteal 的对照组。
/// - **破甲(pierce)**:攻方 `forgingPiercePct > 0` 时，对有防御率守方造成
///   的累计伤害应高于无 pierce 的对照组。
///
/// 骨架沿用 `battle_seed_determinism_test.dart`：
///   ProviderContainer + 永久 listener + BattleNotifier.startBattle(seed:) +
///   advance() 循环 + 读最终 BattleState。
void main() {
  setUpAll(() async {
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  // 普攻(无消耗,保证每拍都出手)。
  const normal = SkillDef(
    id: 'skill_forging_normal',
    name: '普攻',
    description: 'forging 集成测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // ── 通用单位工厂 ──────────────────────────────────────────────────────────
  /// [piercePct]  > 0 时测试破甲增伤。
  /// [lifestealPct] > 0 时测试吸血回血。
  /// 守方 defenseRate 固定 0.30，确保破甲可以从 0.30→0.10 看到显著增伤。
  BattleCharacter attacker({
    required int charId,
    double piercePct = 0.0,
    double lifestealPct = 0.0,
  }) =>
      BattleCharacter(
        characterId: charId,
        name: 'attacker$charId',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 10000,
        currentHp: 10000,
        maxInternalForce: 0, // 无内力 → 永远走普攻
        currentInternalForce: 0,
        speed: 200, // 比守方快很多，先手多
        criticalRate: 0.0, // 关闭暴击，伤害确定
        evasionRate: 0.0,
        defenseRate: 0.05,
        totalEquipmentAttack: 800,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const [normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 0,
        slotIndex: 0,
        forgingPiercePct: piercePct,
        forgingLifestealPct: lifestealPct,
      );

  BattleCharacter defender({required int charId}) => BattleCharacter(
        characterId: charId,
        name: 'defender$charId',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 50000, // 高血量，战斗不会太快结束
        currentHp: 50000,
        maxInternalForce: 0,
        currentInternalForce: 0,
        speed: 50, // 慢，让攻方多拍手
        criticalRate: 0.0,
        evasionRate: 0.0,
        defenseRate: 0.30, // 明显防御率，便于破甲对比
        totalEquipmentAttack: 100,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const [normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 1,
        slotIndex: 0,
      );

  // ── 运行战斗若干拍（固定 action 数上限）并返回最终 BattleState ───────────
  BattleState runBattle(
    List<BattleCharacter> left,
    List<BattleCharacter> right, {
    int seed = 42,
    int maxActions = 30, // 最多观察 30 个 action
  }) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(
      battleProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(left, right, seed: seed);

    var actions = 0;
    while (!container.read(battleProvider).isFinished && actions < maxActions) {
      final before = container.read(battleProvider).actionLog.length;
      notifier.advance();
      final after = container.read(battleProvider).actionLog.length;
      if (after > before) actions += (after - before);
    }

    return container.read(battleProvider);
  }

  // ── 吸血测试 ─────────────────────────────────────────────────────────────
  test('吸血:forgingLifestealPct>0 时攻方 currentHp 应高于无 lifesteal 对照', () {
    // 对照组：无吸血
    final stateNoLifesteal = runBattle(
      [attacker(charId: 1, lifestealPct: 0.0)],
      [defender(charId: -1)],
      seed: 42,
    );

    // 实验组：吸血 20%
    final stateLifesteal = runBattle(
      [attacker(charId: 1, lifestealPct: 0.20)],
      [defender(charId: -1)],
      seed: 42,
    );

    // 注:两组攻方都未受到攻击（守方 speed=50，攻方 speed=200，30 action 内
    // 守方只能行动极少次）。但吸血让攻方每次命中都回血，因此 currentHp 应不低于
    // 对照组（实验组初始 hp 相同，受到少量守方攻击后因回血补回）。
    // 更精确：累计 lifesteal 回血量 = 所有命中 action 的 lifestealHeal 之和。

    final lifestealHealed = stateLifesteal.actionLog
        .where((a) => a.actorId == 1 && (a.attackResult?.lifestealHeal ?? 0) > 0)
        .fold<int>(0, (sum, a) => sum + (a.attackResult!.lifestealHeal));

    // 主断言：至少有一次命中产生了 lifestealHeal > 0（证明 wiring 已接通）。
    expect(
      lifestealHealed,
      greaterThan(0),
      reason: '吸血词条接通后，每次命中应产生 lifestealHeal > 0；'
          '当前累计回血=$lifestealHealed；'
          '若=0 说明 calculateResolved 传参未接通（Task 4 未实装）',
    );

    // 副断言：攻方最终 currentHp 在吸血组中高于或等于无吸血组。
    final hpNoLifesteal =
        stateNoLifesteal.leftTeam.firstWhere((c) => c.characterId == 1).currentHp;
    final hpLifesteal =
        stateLifesteal.leftTeam.firstWhere((c) => c.characterId == 1).currentHp;

    expect(
      hpLifesteal,
      greaterThanOrEqualTo(hpNoLifesteal),
      reason: '吸血组攻方 currentHp($hpLifesteal) 应 >= 无吸血组($hpNoLifesteal)',
    );
  });

  // ── 破甲测试 ─────────────────────────────────────────────────────────────
  test('破甲:forgingPiercePct>0 时对有防御率目标造成伤害应高于无 pierce 对照', () {
    // 对照组：无破甲
    final stateNoPierce = runBattle(
      [attacker(charId: 2, piercePct: 0.0)],
      [defender(charId: -2)],
      seed: 42,
    );

    // 实验组：破甲 20%（守方 defenseRate=0.30 → 有效防御 0.10）
    final statePierce = runBattle(
      [attacker(charId: 2, piercePct: 0.20)],
      [defender(charId: -2)],
      seed: 42,
    );

    // 计算两组攻方命中守方的累计伤害。
    int totalDmg(BattleState s) => s.actionLog
        .where((a) => a.actorId == 2 && !(a.attackResult?.isDodged ?? true))
        .fold<int>(0, (sum, a) => sum + (a.attackResult?.finalDamage ?? 0));

    final dmgNoPierce = totalDmg(stateNoPierce);
    final dmgPierce = totalDmg(statePierce);

    // 至少有一次命中，确保场景有效
    expect(
      dmgNoPierce,
      greaterThan(0),
      reason: '对照组应至少有一次命中造成伤害（场景有效性检查）',
    );

    // 主断言：破甲后累计伤害严格高于无破甲
    expect(
      dmgPierce,
      greaterThan(dmgNoPierce),
      reason: '破甲 20% 使有效防御 0.30→0.10，累计伤害应明显提升；'
          '无破甲=$dmgNoPierce，破甲=$dmgPierce；'
          '若相等说明 attackerPiercePct 传参未接通（Task 4 未实装）',
    );
  });
}
