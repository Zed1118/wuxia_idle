import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_ceremony.dart';

// ── Fixture builders (沿 top_damage_contributor_test.dart 体例) ──────────────

BattleCharacter _player({required int id, int slot = 0}) => BattleCharacter(
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

BattleCharacter _enemy({required int id}) => BattleCharacter(
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
      slotIndex: 0,
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

/// 构造最小化 Character 供测试用（不写 Isar，id 手动设）。
Character _character({
  required int id,
  required String name,
  RealmTier realmTier = RealmTier.sanLiu,
  String? portraitPath,
}) {
  final c = Character.create(
    name: name,
    realmTier: realmTier,
    realmLayer: RealmLayer.yuanShu,
    attributes: Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 5,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026),
    portraitPath: portraitPath,
  );
  // Isar autoIncrement id 未入库时为 sentinel；手动注入以匹配 BattleCharacter.characterId
  c.id = id;
  return c;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('deriveHeroCameraData', () {
    test('(a) 正常路径 → 返回 top-damage 角色的 HeroCameraData', () {
      final p1 = _player(id: 1, slot: 0);
      final p2 = _player(id: 2, slot: 1);
      final e = _enemy(id: 10);
      final state = _state(
        left: [p1, p2],
        right: [e],
        log: [
          BattleAction(
              tick: 10,
              actorId: 1,
              targetId: 10,
              skill: _skill,
              attackResult: _hit(200),
              description: ''),
          BattleAction(
              tick: 20,
              actorId: 2,
              targetId: 10,
              skill: _skill,
              attackResult: _hit(900),
              description: ''),
        ],
      );
      final ch1 = _character(id: 1, name: '剑客甲');
      final ch2 = _character(
          id: 2, name: '刀客乙', realmTier: RealmTier.yiLiu, portraitPath: 'assets/a.png');
      final characters = [ch1, ch2];

      final result = deriveHeroCameraData(
        finalState: state,
        characters: characters,
        bossName: '山贼头子',
      );

      expect(result, isNotNull);
      expect(result!.heroName, '刀客乙');
      expect(result.bossName, '山贼头子');
      expect(result.topDamage, 900);
      expect(result.portraitPath, 'assets/a.png');
      // realmLabel 非空（EnumL10n.realmTier 返回中文字符串）
      expect(result.realmLabel, isNotEmpty);
    });

    test('(b) 无玩家伤害记录 → 返回 null', () {
      final p = _player(id: 1, slot: 0);
      final e = _enemy(id: 10);
      // 只有敌方 action
      final state = _state(
        left: [p],
        right: [e],
        log: [
          BattleAction(
              tick: 10,
              actorId: 10,
              targetId: 1,
              skill: _skill,
              attackResult: _hit(500),
              description: ''),
        ],
      );
      final ch = _character(id: 1, name: '剑客甲');

      final result = deriveHeroCameraData(
        finalState: state,
        characters: [ch],
        bossName: '山贼头子',
      );

      expect(result, isNull);
    });

    test('(c) top actor 不在 characters 列表中 → 返回 null', () {
      final p = _player(id: 1, slot: 0);
      final e = _enemy(id: 10);
      final state = _state(
        left: [p],
        right: [e],
        log: [
          BattleAction(
              tick: 10,
              actorId: 1,
              targetId: 10,
              skill: _skill,
              attackResult: _hit(500),
              description: ''),
        ],
      );
      // characters 列表中只有 id=99，不含 top actor(id=1)
      final ch = _character(id: 99, name: '路人甲');

      final result = deriveHeroCameraData(
        finalState: state,
        characters: [ch],
        bossName: '山贼头子',
      );

      expect(result, isNull);
    });
  });
}
