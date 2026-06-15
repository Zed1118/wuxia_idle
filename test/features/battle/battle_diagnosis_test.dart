import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/battle_diagnosis.dart';

const _cfg = BattleReportConfig(
  internalWoundPct: 0.30,
  minionDamagePct: 0.35,
  frontlineDeathPhasePct: 0.5,
  survivorHpPct: 0.5,
);

// 玩家方角色（teamSide 0）。
BattleCharacter _player({
  int id = 1,
  int slot = 0,
  int maxHp = 1000,
  int currentHp = 0,
  bool alive = false,
  int curForce = 200,
  int maxForce = 500,
  InternalInjurySlot? injury,
}) => BattleCharacter(
      characterId: id, name: '玩家$id', realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.yuanShu, school: TechniqueSchool.gangMeng,
      maxHp: maxHp, currentHp: currentHp, maxInternalForce: maxForce,
      currentInternalForce: curForce, speed: 100, criticalRate: 0,
      evasionRate: 0, defenseRate: 0.1, totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [], skillCooldowns: const {},
      activeBuffs: const [], actionPoint: 0, isAlive: alive,
      teamSide: 0, slotIndex: slot, internalInjury: injury,
    );

// 敌方角色（teamSide 1）。
BattleCharacter _enemy({
  int id = 100,
  int slot = 0,
  bool boss = false,
  String? chargeSkillId,
  int currentHp = 1000,
  int maxHp = 1000,
  bool alive = true,
}) => BattleCharacter(
      characterId: id, name: '敌$id', realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.yuanShu, school: TechniqueSchool.gangMeng,
      maxHp: maxHp, currentHp: currentHp, maxInternalForce: 500,
      currentInternalForce: 500, speed: 100, criticalRate: 0,
      evasionRate: 0, defenseRate: 0.1, totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [], skillCooldowns: const {},
      activeBuffs: const [], actionPoint: 0, isAlive: alive,
      teamSide: 1, slotIndex: slot, isBoss: boss, chargeSkillId: chargeSkillId,
    );

AttackResult _hit({
  required int damage,
  List<String> effects = const [],
}) => AttackResult(
      finalDamage: damage, mainDamage: damage, quakeDamage: 0,
      isCritical: false, isDodged: false, schoolCounterMultiplier: 1.0,
      realmDiffAttackerMod: 1.0, realmDiffDefenderMod: 1.0,
      cultivationMultiplier: 1.0, criticalMultiplier: 1.0,
      defenseRate: 0.1, evasionRate: 0, appliedEffects: effects,
      formulaBreakdown: 'stub',
    );

const _chargeSkill = SkillDef(
  id: 'skill_boss_charge', name: 'Boss蓄力技', description: 'stub',
  type: SkillType.ultimate, powerMultiplier: 5000, internalForceCost: 0,
  cooldownTurns: 0, requiresManualTrigger: false, visualEffect: 'stub',
);
const _normalSkill = SkillDef(
  id: 'skill_normal', name: '普攻', description: 'stub',
  type: SkillType.normalAttack, powerMultiplier: 500, internalForceCost: 0,
  cooldownTurns: 0, requiresManualTrigger: false, visualEffect: 'stub',
);

BattleState _lost({
  required List<BattleCharacter> left,
  required List<BattleCharacter> right,
  required List<BattleAction> log,
  BattleResult result = BattleResult.rightWin,
  int tick = 100,
}) => BattleState(
      leftTeam: left, rightTeam: right, tick: tick, result: result,
      actionLog: log, pendingUltimates: const {}, pendingTargets: const {},
    );

void main() {
  test('胜利返回 null', () {
    final s = _lost(
      left: [_player(alive: true, currentHp: 500)],
      right: [_enemy(alive: false, currentHp: 0)],
      log: const [],
      result: BattleResult.leftWin,
    );
    expect(BattleDiagnosis.from(s, _cfg), isNull);
  });

  test('killed_by_charge: 致命一击是 Boss 蓄力技', () {
    final boss = _enemy(boss: true, chargeSkillId: 'skill_boss_charge');
    final s = _lost(
      left: [_player()],
      right: [boss],
      log: [
        BattleAction(tick: 90, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 300), description: ''),
        BattleAction(tick: 95, actorId: 100, targetId: 1, skill: _chargeSkill,
            attackResult: _hit(damage: 700), description: ''),
      ],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    expect(d.ruleId, 'killed_by_charge');
    expect(d.dataLines.length, 2);
    expect(d.suggestions.first.jump, DiagnosisJumpTarget.skills);
  });

  test('mob_overrun: 小怪伤害占比 ≥ 0.35 且敌 >1', () {
    final boss = _enemy(id: 100, boss: true, chargeSkillId: 'skill_x');
    final mob = _enemy(id: 101, boss: false);
    final s = _lost(
      left: [_player()],
      right: [boss, mob],
      log: [
        BattleAction(tick: 10, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 600), description: ''),
        BattleAction(tick: 20, actorId: 101, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 400), description: ''),
      ],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    expect(d.ruleId, 'mob_overrun'); // 400/1000 = 0.40 ≥ 0.35
  });

  test('mob_overrun 边界: 0.34 不命中 → 落 generic', () {
    // 隔离 mob 边界：玩家存活(跳过前排规则) + 敌方残血(跳过 dps 规则)，
    // 仅验 0.34 < 0.35 不触发 mob_overrun → 兜底 generic。
    final boss = _enemy(id: 100, boss: true, chargeSkillId: 'skill_x',
        currentHp: 100, maxHp: 1000);
    final mob = _enemy(id: 101, boss: false, currentHp: 100, maxHp: 1000);
    final s = _lost(
      left: [_player(alive: true, currentHp: 100)],
      right: [boss, mob],
      log: [
        BattleAction(tick: 10, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 660), description: ''),
        BattleAction(tick: 20, actorId: 101, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 340), description: ''),
      ],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    // 340/1000=0.34 < 0.35；非 charge/内伤/前排/超时 → generic
    expect(d.ruleId, 'generic');
  });

  test('killed_by_internal_wound: 内伤占比 ≥ 0.30', () {
    final s = _lost(
      left: [_player()],
      right: [_enemy(id: 100, boss: false)],
      log: [
        BattleAction(tick: 10, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 600), description: ''),
        BattleAction(tick: 20, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 400, effects: ['internal_injury']),
            description: ''),
      ],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    expect(d.ruleId, 'killed_by_internal_wound'); // 400/1000=0.40
    expect(d.suggestions.first.jump, DiagnosisJumpTarget.cultivation);
  });

  test('优先级: charge 高于 mob_overrun', () {
    // 同时满足 charge(致命=蓄力) 与 mob(小怪占比高)，断言取 charge。
    final boss = _enemy(id: 100, boss: true, chargeSkillId: 'skill_boss_charge');
    final mob = _enemy(id: 101, boss: false);
    final s = _lost(
      left: [_player()],
      right: [boss, mob],
      log: [
        BattleAction(tick: 10, actorId: 101, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 500), description: ''),
        BattleAction(tick: 95, actorId: 100, targetId: 1, skill: _chargeSkill,
            attackResult: _hit(damage: 500), description: ''),
      ],
    );
    expect(BattleDiagnosis.from(s, _cfg)!.ruleId, 'killed_by_charge');
  });

  test('frontline_fragile: 前排(slot0)死在前半程', () {
    // slot0 玩家 maxHp 1000，前 40 tick 内累计伤害 ≥ 1000；总 tick 200。
    final s = _lost(
      left: [
        _player(id: 1, slot: 0, maxHp: 1000),
        _player(id: 2, slot: 1, alive: true, currentHp: 800, maxHp: 1000),
      ],
      right: [_enemy(id: 100, boss: false)],
      tick: 200,
      log: [
        BattleAction(tick: 20, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 600), description: ''),
        BattleAction(tick: 40, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 500), description: ''), // 累计 1100 ≥ 1000 @tick40, 40/200=0.2 ≤ 0.5
      ],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    expect(d.ruleId, 'frontline_fragile');
    expect(d.suggestions.first.jump, DiagnosisJumpTarget.equipment);
  });

  test('dps_too_low: draw(超时)', () {
    final s = _lost(
      left: [_player(alive: true, currentHp: 100)],
      right: [_enemy(id: 100, boss: true, currentHp: 900, maxHp: 1000)],
      result: BattleResult.draw,
      tick: 1000,
      log: const [],
    );
    final d = BattleDiagnosis.from(s, _cfg)!;
    expect(d.ruleId, 'dps_too_low');
    expect(d.suggestions.first.jump, DiagnosisJumpTarget.skills);
  });

  test('generic: 无规则命中', () {
    // rightWin，敌方残血低(打得动)、无蓄力致命、无内伤、无小怪、前排没早死。
    final s = _lost(
      left: [_player(id: 1, slot: 0, maxHp: 1000)],
      right: [_enemy(id: 100, boss: true, chargeSkillId: 'skill_x', currentHp: 50, maxHp: 1000)],
      tick: 100,
      log: [
        BattleAction(tick: 90, actorId: 100, targetId: 1, skill: _normalSkill,
            attackResult: _hit(damage: 1000), description: ''), // 死在 90/100=0.9 > 0.5
      ],
    );
    expect(BattleDiagnosis.from(s, _cfg)!.ruleId, 'generic');
  });
}
