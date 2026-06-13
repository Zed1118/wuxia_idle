import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// C2 反震词条单元测试。
///
/// 覆盖语义：
/// 1. 玩家命中带 'cycle_fanzhen' buff 的敌人 → 攻击者(玩家)加 InternalInjurySlot；
/// 2. 闪避时不反震；
/// 3. 无 'cycle_fanzhen' buff 时不反震；
/// 4. 反震 slot 施加到 ATTACKER（玩家），不是 DEFENDER（敌人）；
/// 5. 同源刷新：再次命中时覆盖旧 slot 不叠层；
/// 6. 敌人攻击玩家时不触发（反震只在玩家打敌人时）。

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  test('反震:玩家命中有 cycle_fanzhen 的敌人 → 攻击者收到 InternalInjurySlot', () {
    final n = GameRepository.instance.numbers;
    // 玩家 actionPoint=1000 立即出手；敌人有反震词条。
    final player = _mkBC(charId: 1, teamSide: 0).copyWith(
      actionPoint: 1000,
      // 必中：evasionRate=0 保证 result.isDodged=false
    );
    final enemy = _mkBC(charId: 11, teamSide: 1).copyWith(
      activeBuffs: ['cycle_fanzhen'],
      evasionRate: 0.0,
    );
    var s = BattleState.initial(leftTeam: [player], rightTeam: [enemy]);
    s = BattleEngine.tick(s, n, rng: Random(0));
    final playerAfter = s.leftTeam.first;
    expect(playerAfter.internalInjury, isNotNull,
        reason: '玩家命中反震敌人 → 攻击者应加内伤 slot');
    expect(playerAfter.internalInjury!.remainingTurns,
        n.cycleEvolution.traits.fanzhen.ticks,
        reason: 'remainingTurns 应等于 fanzhen.ticks');
    expect(playerAfter.internalInjury!.damagePerTick,
        n.cycleEvolution.traits.fanzhen.damagePerTick,
        reason: 'damagePerTick 应等于 fanzhen.damagePerTick');
  });

  test('反震:攻击被闪避 → 不反震(攻击者无内伤)', () {
    final n = GameRepository.instance.numbers;
    final player = _mkBC(charId: 1, teamSide: 0).copyWith(actionPoint: 1000);
    final enemy = _mkBC(charId: 11, teamSide: 1).copyWith(
      activeBuffs: ['cycle_fanzhen'],
      evasionRate: 1.0, // 100% 闪避，强制 isDodged=true
    );
    var s = BattleState.initial(leftTeam: [player], rightTeam: [enemy]);
    s = BattleEngine.tick(s, n, rng: Random(0));
    expect(s.leftTeam.first.internalInjury, isNull,
        reason: '闪避时不触发反震');
  });

  test('反震:敌人无 cycle_fanzhen buff → 攻击者无内伤', () {
    final n = GameRepository.instance.numbers;
    final player = _mkBC(charId: 1, teamSide: 0).copyWith(
      actionPoint: 1000,
    );
    final enemy = _mkBC(charId: 11, teamSide: 1).copyWith(
      activeBuffs: const [], // 无反震词条
      evasionRate: 0.0,
    );
    var s = BattleState.initial(leftTeam: [player], rightTeam: [enemy]);
    s = BattleEngine.tick(s, n, rng: Random(0));
    expect(s.leftTeam.first.internalInjury, isNull,
        reason: '无 cycle_fanzhen buff 不应触发反震');
  });

  test('反震:slot 在 ATTACKER(玩家)上，DEFENDER(敌人)无内伤', () {
    final n = GameRepository.instance.numbers;
    final player = _mkBC(charId: 1, teamSide: 0).copyWith(
      actionPoint: 1000,
    );
    final enemy = _mkBC(charId: 11, teamSide: 1).copyWith(
      activeBuffs: ['cycle_fanzhen'],
      evasionRate: 0.0,
    );
    var s = BattleState.initial(leftTeam: [player], rightTeam: [enemy]);
    s = BattleEngine.tick(s, n, rng: Random(0));
    expect(s.leftTeam.first.internalInjury, isNotNull,
        reason: '攻击者(玩家)应有反震 slot');
    expect(s.rightTeam.first.internalInjury, isNull,
        reason: '反震不应施加到 DEFENDER(敌人)');
  });

  test('反震:同源刷新 — 再次命中 → remainingTurns 重置不叠层', () {
    final n = GameRepository.instance.numbers;
    // 玩家已有 turns=1 的内伤，再次命中反震敌人 → 应覆盖为 fanzhen.ticks
    final player = _mkBC(charId: 1, teamSide: 0).copyWith(
      actionPoint: 1000,
      internalInjury: const InternalInjurySlot(remainingTurns: 1, damagePerTick: 99),
    );
    final enemy = _mkBC(charId: 11, teamSide: 1).copyWith(
      activeBuffs: ['cycle_fanzhen'],
      evasionRate: 0.0,
    );
    var s = BattleState.initial(leftTeam: [player], rightTeam: [enemy]);
    s = BattleEngine.tick(s, n, rng: Random(0));
    final playerAfter = s.leftTeam.first;
    expect(playerAfter.internalInjury, isNotNull);
    expect(playerAfter.internalInjury!.remainingTurns,
        n.cycleEvolution.traits.fanzhen.ticks,
        reason: '刷新覆盖：turns 重置到 fanzhen.ticks，不叠加');
    expect(playerAfter.internalInjury!.damagePerTick,
        n.cycleEvolution.traits.fanzhen.damagePerTick);
  });

  test('反震:敌人攻击玩家 → 不触发（反震只对来袭的玩家生效）', () {
    final n = GameRepository.instance.numbers;
    // 敌人 actionPoint=1000 先出手，玩家有 cycle_fanzhen（测试反向不触发）
    final enemy = _mkBC(charId: 11, teamSide: 1).copyWith(
      actionPoint: 1000,
    );
    // 为玩家加 fanzhen buff（测当 enemy 打 player 时不反震）
    final player = _mkBC(charId: 1, teamSide: 0).copyWith(
      activeBuffs: ['cycle_fanzhen'],
      evasionRate: 0.0,
    );
    var s = BattleState.initial(leftTeam: [player], rightTeam: [enemy]);
    s = BattleEngine.tick(s, n, rng: Random(0));
    // 敌人打玩家：敌人(teamSide=1)是攻击者，不应收到内伤
    expect(s.rightTeam.first.internalInjury, isNull,
        reason: '敌人打玩家时，敌人不应收到反震内伤');
  });

  test('反震:从 numbers.cycleEvolution.traits.fanzhen 读取参数值', () {
    final n = GameRepository.instance.numbers;
    expect(n.cycleEvolution.traits.fanzhen.damagePerTick, 200,
        reason: 'numbers.yaml cycle_evolution.traits.fanzhen.damage_per_tick 应为 200');
    expect(n.cycleEvolution.traits.fanzhen.ticks, 3,
        reason: 'numbers.yaml cycle_evolution.traits.fanzhen.ticks 应为 3');
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// fixture
// ─────────────────────────────────────────────────────────────────────────────

BattleCharacter _mkBC({
  required int charId,
  required int teamSide,
  int slotIndex = 0,
}) {
  final n = GameRepository.instance.numbers;
  final c = Character.create(
    name: '${teamSide == 0 ? "左" : "右"}$slotIndex',
    realmTier: RealmTier.erLiu,
    realmLayer: RealmLayer.yuanShu,
    attributes: Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 5,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: 3000,
    school: TechniqueSchool.gangMeng,
  )
    ..id = charId
    ..internalForceMax = 3000
    ..mainSkillId1 = 'skill_gangmeng_mingjia_basic'
    ..assistSkillId = 'skill_gangmeng_mingjia_skill'
    ..ultimateSkillId = 'skill_gangmeng_mingjia_ult';
  final eq = Equipment.create(
    defId: 'test',
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    obtainedAt: DateTime(2026, 1, 1),
    obtainedFrom: 'test',
    baseAttack: 580,
  );
  final tech = Technique.create(
    defId: 'tech_gangmeng_mingjia',
    ownerCharacterId: charId,
    tier: TechniqueTier.mingJiaGong,
    school: TechniqueSchool.gangMeng,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 1, 1),
    cultivationLayer: CultivationLayer.zhongCheng,
  );
  return BattleCharacter.fromCharacter(
    character: c,
    equipped: [eq],
    mainTechnique: tech,
    numbers: n,
    teamSide: teamSide,
    slotIndex: slotIndex,
  );
}
