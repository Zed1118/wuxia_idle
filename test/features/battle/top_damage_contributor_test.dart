import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/top_damage_contributor.dart';

// ── Fixture builders ──────────────────────────────────────────────────────────

BattleCharacter _player({
  required int id,
  int slot = 0,
}) =>
    BattleCharacter(
      characterId: id,
      name: 'player$id',
      realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.yuanShu,
      school: TechniqueSchool.gangMeng,
      maxHp: 1000,
      currentHp: 1000,
      maxInternalForce: 500,
      currentInternalForce: 500,
      speed: 100,
      criticalRate: 0,
      evasionRate: 0,
      defenseRate: 0.1,
      totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: slot,
    );

BattleCharacter _enemy({required int id, int slot = 0}) => BattleCharacter(
      characterId: id,
      name: 'enemy$id',
      realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.yuanShu,
      school: TechniqueSchool.gangMeng,
      maxHp: 1000,
      currentHp: 0,
      maxInternalForce: 500,
      currentInternalForce: 500,
      speed: 100,
      criticalRate: 0,
      evasionRate: 0,
      defenseRate: 0.1,
      totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: false,
      teamSide: 1,
      slotIndex: slot,
    );

const _skill = SkillDef(
  id: 'skill_normal',
  name: '普攻',
  description: 'stub',
  type: SkillType.normalAttack,
  powerMultiplier: 500,
  internalForceCost: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: 'stub',
);

AttackResult _hit(int damage) => AttackResult(
      finalDamage: damage,
      mainDamage: damage,
      quakeDamage: 0,
      isCritical: false,
      isDodged: false,
      schoolCounterMultiplier: 1.0,
      realmDiffAttackerMod: 1.0,
      realmDiffDefenderMod: 1.0,
      cultivationMultiplier: 1.0,
      criticalMultiplier: 1.0,
      defenseRate: 0.1,
      evasionRate: 0,
      appliedEffects: const [],
      formulaBreakdown: 'stub',
    );

BattleState _state({
  required List<BattleCharacter> left,
  required List<BattleCharacter> right,
  required List<BattleAction> log,
}) =>
    BattleState(
      leftTeam: left,
      rightTeam: right,
      tick: 100,
      result: BattleResult.leftWin,
      actionLog: log,
      pendingUltimates: const {},
      pendingTargets: const {},
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  test('单玩家 → 取该玩家，totalDamage 累计所有 finalDamage', () {
    final p = _player(id: 1, slot: 0);
    final e = _enemy(id: 10);
    final s = _state(
      left: [p],
      right: [e],
      log: [
        BattleAction(
            tick: 10, actorId: 1, targetId: 10,
            skill: _skill, attackResult: _hit(300), description: ''),
        BattleAction(
            tick: 20, actorId: 1, targetId: 10,
            skill: _skill, attackResult: _hit(500), description: ''),
      ],
    );
    final result = TopDamageContributor.from(s);
    expect(result, isNotNull);
    expect(result!.actorId, 1);
    expect(result.totalDamage, 800);
  });

  test('多玩家 → 取最高输出者', () {
    final p1 = _player(id: 1, slot: 0);
    final p2 = _player(id: 2, slot: 1);
    final e = _enemy(id: 10);
    final s = _state(
      left: [p1, p2],
      right: [e],
      log: [
        BattleAction(
            tick: 10, actorId: 1, targetId: 10,
            skill: _skill, attackResult: _hit(200), description: ''),
        BattleAction(
            tick: 20, actorId: 2, targetId: 10,
            skill: _skill, attackResult: _hit(700), description: ''),
        BattleAction(
            tick: 30, actorId: 1, targetId: 10,
            skill: _skill, attackResult: _hit(100), description: ''),
      ],
    );
    final result = TopDamageContributor.from(s);
    expect(result, isNotNull);
    expect(result!.actorId, 2);   // p2: 700 > p1: 300
    expect(result.totalDamage, 700);
  });

  test('平局伤害 → 取 slotIndex 小者', () {
    final p1 = _player(id: 1, slot: 1);  // slot 1
    final p2 = _player(id: 2, slot: 0);  // slot 0 — 胜出
    final e = _enemy(id: 10);
    final s = _state(
      left: [p1, p2],
      right: [e],
      log: [
        BattleAction(
            tick: 10, actorId: 1, targetId: 10,
            skill: _skill, attackResult: _hit(500), description: ''),
        BattleAction(
            tick: 20, actorId: 2, targetId: 10,
            skill: _skill, attackResult: _hit(500), description: ''),
      ],
    );
    final result = TopDamageContributor.from(s);
    expect(result, isNotNull);
    expect(result!.actorId, 2);   // p2 slot 0 < p1 slot 1
    expect(result.totalDamage, 500);
  });

  test('敌方(teamSide==1)伤害不计入', () {
    final p = _player(id: 1, slot: 0);
    final e = _enemy(id: 10);
    final s = _state(
      left: [p],
      right: [e],
      log: [
        // 玩家打了 100
        BattleAction(
            tick: 10, actorId: 1, targetId: 10,
            skill: _skill, attackResult: _hit(100), description: ''),
        // 敌方打了 9999 — 不应计入
        BattleAction(
            tick: 20, actorId: 10, targetId: 1,
            skill: _skill, attackResult: _hit(9999), description: ''),
      ],
    );
    final result = TopDamageContributor.from(s);
    expect(result, isNotNull);
    expect(result!.actorId, 1);
    expect(result.totalDamage, 100);  // 敌方的 9999 未被计入
  });

  test('无玩家伤害记录 → 返回 null', () {
    final p = _player(id: 1, slot: 0);
    final e = _enemy(id: 10);
    // 只有敌方 action，且玩家 action 无 attackResult
    final s = _state(
      left: [p],
      right: [e],
      log: [
        BattleAction(
            tick: 10, actorId: 10, targetId: 1,
            skill: _skill, attackResult: _hit(500), description: ''),
        const BattleAction(
            tick: 20, actorId: 1, targetId: 10,
            skill: _skill, attackResult: null, description: ''),
      ],
    );
    final result = TopDamageContributor.from(s);
    expect(result, isNull);
  });
}
