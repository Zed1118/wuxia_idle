import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/combat/battle_state.dart';
import 'package:wuxia_idle/combat/damage_calculator.dart';
import 'package:wuxia_idle/combat/derived_stats.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/attributes.dart';
import 'package:wuxia_idle/data/models/character.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/data/models/technique.dart';

/// BattleState / BattleCharacter / BattleAction 单元测试（phase1_tasks.md T11 §649）。
///
/// 覆盖：
/// 1. fromCharacter 单一入口与 CharacterDerivedStats 派生口径一致
///    （maxHp / speed / criticalRate / evasionRate / 内力 / 招式列表）。
/// 2. fromCharacter 边界（school 必填 / mainTechnique 必须 role=main /
///    teamSide ∈ {0,1} / slotIndex ∈ [0,2]）。
/// 3. BattleCharacter.copyWith：HP 变化只影响 currentHp，其他字段不变。
/// 4. BattleState.copyWith：能正确构造下一个 tick 的状态；result 用 sentinel
///    区分"不传"与"传 null"。
/// 5. 死亡判定字段齐全（currentHp=0 / isAlive=false 可显式构造）。
/// 6. BattleAction 字段齐全 + nullable 可选（targetId/skill/attackResult）。
/// 7. BattleState.initial：tick=0 / result=null / actionLog=[]。
/// 8. immutable：fromCharacter 返回的 List 不可外部 mutate。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  setUp(() async {
    await GameRepository.loadAllDefs(loader: fileLoader);
  });

  tearDown(GameRepository.resetForTest);

  // ────────────────────────────────────────────────────────────────────────
  // BattleCharacter.fromCharacter 派生属性单一入口
  // ────────────────────────────────────────────────────────────────────────

  group('BattleCharacter.fromCharacter 派生属性', () {
    test('与 CharacterDerivedStats 直接调用结果一致（maxHp/speed/critRate/evRate）',
        () {
      final c = _mkChar(
        tier: RealmTier.erLiu,
        layer: RealmLayer.yuanShu,
        internalForce: 3000,
        school: TechniqueSchool.gangMeng,
        constitution: 8,
        agility: 6,
      );
      final eq = _mkEquip(baseAttack: 580, baseHealth: 200, baseSpeed: 5);
      final tech = _mkTech(
        defId: 'tech_gangmeng_mingjia',
        tier: TechniqueTier.mingJiaGong,
        school: TechniqueSchool.gangMeng,
      );
      final n = GameRepository.instance.numbers;

      final bc = BattleCharacter.fromCharacter(
        character: c,
        equipped: [eq],
        mainTechnique: tech,
        numbers: n,
        teamSide: 0,
        slotIndex: 0,
      );

      expect(bc.maxHp, CharacterDerivedStats.maxHp(c, [eq], n));
      expect(bc.speed, CharacterDerivedStats.speed(c, [eq], tech, n));
      expect(bc.criticalRate, CharacterDerivedStats.criticalRate(c, n));
      expect(bc.evasionRate, CharacterDerivedStats.evasionRate(c, n));
    });

    test('currentHp 初始 = maxHp，currentInternalForce 初始 = character.internalForce',
        () {
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.ruMen,
        internalForce: 600,
        school: TechniqueSchool.gangMeng,
      );
      final tech = _mkTech(
        defId: 'tech_gangmeng_jichu',
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
      );
      final bc = BattleCharacter.fromCharacter(
        character: c,
        equipped: const [],
        mainTechnique: tech,
        numbers: GameRepository.instance.numbers,
        teamSide: 0,
        slotIndex: 0,
      );
      expect(bc.currentHp, bc.maxHp);
      expect(bc.currentInternalForce, 600);
      expect(bc.maxInternalForce, c.internalForceMax);
    });

    test('actionPoint=0 / isAlive=true / 空 cooldowns / 空 buffs 初始',
        () {
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.ruMen,
        internalForce: 100,
        school: TechniqueSchool.gangMeng,
      );
      final tech = _mkTech(
        defId: 'tech_gangmeng_jichu',
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
      );
      final bc = BattleCharacter.fromCharacter(
        character: c,
        equipped: const [],
        mainTechnique: tech,
        numbers: GameRepository.instance.numbers,
        teamSide: 1,
        slotIndex: 2,
      );
      expect(bc.actionPoint, 0);
      expect(bc.isAlive, true);
      expect(bc.skillCooldowns, isEmpty);
      expect(bc.activeBuffs, isEmpty);
      expect(bc.teamSide, 1);
      expect(bc.slotIndex, 2);
    });

    test('availableSkills 从 TechniqueDef.skillIds 解析（tech_gangmeng_jichu → 3 招）',
        () {
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.ruMen,
        internalForce: 100,
        school: TechniqueSchool.gangMeng,
      );
      final tech = _mkTech(
        defId: 'tech_gangmeng_jichu',
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
      );
      final bc = BattleCharacter.fromCharacter(
        character: c,
        equipped: const [],
        mainTechnique: tech,
        numbers: GameRepository.instance.numbers,
        teamSide: 0,
        slotIndex: 0,
      );
      expect(bc.availableSkills.length, 3);
      expect(
        bc.availableSkills.map((s) => s.id).toList(),
        containsAll([
          'skill_gangmeng_jichu_basic',
          'skill_gangmeng_jichu_skill',
          'skill_gangmeng_jichu_ult',
        ]),
      );
      // 确认 SkillDef 实例就是 GameRepository.getSkill 返回的
      expect(
        bc.availableSkills.first,
        same(GameRepository.instance
            .getSkill('skill_gangmeng_jichu_basic')),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // fromCharacter 边界
  // ────────────────────────────────────────────────────────────────────────

  group('BattleCharacter.fromCharacter 边界', () {
    test('school 为空 → 抛 StateError', () {
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.ruMen,
        internalForce: 100,
        school: null, // 关键：无主修
      );
      final tech = _mkTech(
        defId: 'tech_gangmeng_jichu',
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
      );
      expect(
        () => BattleCharacter.fromCharacter(
          character: c,
          equipped: const [],
          mainTechnique: tech,
          numbers: GameRepository.instance.numbers,
          teamSide: 0,
          slotIndex: 0,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('mainTechnique.role != main → 抛 StateError', () {
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.ruMen,
        internalForce: 100,
        school: TechniqueSchool.gangMeng,
      );
      final tech = _mkTech(
        defId: 'tech_gangmeng_jichu',
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.assist, // 关键：非主修
      );
      expect(
        () => BattleCharacter.fromCharacter(
          character: c,
          equipped: const [],
          mainTechnique: tech,
          numbers: GameRepository.instance.numbers,
          teamSide: 0,
          slotIndex: 0,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('teamSide ∉ {0,1} → 抛 RangeError', () {
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.ruMen,
        internalForce: 100,
        school: TechniqueSchool.gangMeng,
      );
      final tech = _mkTech(
        defId: 'tech_gangmeng_jichu',
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
      );
      expect(
        () => BattleCharacter.fromCharacter(
          character: c,
          equipped: const [],
          mainTechnique: tech,
          numbers: GameRepository.instance.numbers,
          teamSide: 2,
          slotIndex: 0,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('slotIndex ∉ [0,2] → 抛 RangeError', () {
      final c = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.ruMen,
        internalForce: 100,
        school: TechniqueSchool.gangMeng,
      );
      final tech = _mkTech(
        defId: 'tech_gangmeng_jichu',
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
      );
      expect(
        () => BattleCharacter.fromCharacter(
          character: c,
          equipped: const [],
          mainTechnique: tech,
          numbers: GameRepository.instance.numbers,
          teamSide: 0,
          slotIndex: 3,
        ),
        throwsA(isA<RangeError>()),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BattleCharacter.copyWith（phase1_tasks T11 §649）
  // ────────────────────────────────────────────────────────────────────────

  group('BattleCharacter.copyWith', () {
    test('HP 变化只影响 currentHp，其他字段不变', () {
      final bc = _mkBattleChar();
      final after = bc.copyWith(currentHp: bc.currentHp - 1234);

      expect(after.currentHp, bc.currentHp - 1234);
      // 其他字段全部不变
      expect(after.characterId, bc.characterId);
      expect(after.name, bc.name);
      expect(after.realmTier, bc.realmTier);
      expect(after.realmLayer, bc.realmLayer);
      expect(after.school, bc.school);
      expect(after.maxHp, bc.maxHp);
      expect(after.maxInternalForce, bc.maxInternalForce);
      expect(after.currentInternalForce, bc.currentInternalForce);
      expect(after.speed, bc.speed);
      expect(after.criticalRate, bc.criticalRate);
      expect(after.evasionRate, bc.evasionRate);
      expect(after.availableSkills, same(bc.availableSkills));
      expect(after.skillCooldowns, same(bc.skillCooldowns));
      expect(after.activeBuffs, same(bc.activeBuffs));
      expect(after.actionPoint, bc.actionPoint);
      expect(after.isAlive, bc.isAlive);
      expect(after.teamSide, bc.teamSide);
      expect(after.slotIndex, bc.slotIndex);
      // 引用必须不同
      expect(identical(after, bc), false);
    });

    test('多字段同时变化（actionPoint / cooldowns / buffs）独立工作', () {
      final bc = _mkBattleChar();
      final after = bc.copyWith(
        actionPoint: 800,
        skillCooldowns: const {'skill_a': 3},
        activeBuffs: const ['internal_injury'],
      );
      expect(after.actionPoint, 800);
      expect(after.skillCooldowns, {'skill_a': 3});
      expect(after.activeBuffs, ['internal_injury']);
      // 未传字段保持引用相同
      expect(after.availableSkills, same(bc.availableSkills));
    });

    test('显式 isAlive=false + currentHp=0 死亡快照可构造（T12 用）', () {
      final bc = _mkBattleChar();
      final dead = bc.copyWith(currentHp: 0, isAlive: false);
      expect(dead.currentHp, 0);
      expect(dead.isAlive, false);
      // 其他字段不动
      expect(dead.maxHp, bc.maxHp);
      expect(dead.name, bc.name);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BattleState.copyWith（phase1_tasks T11 §650）
  // ────────────────────────────────────────────────────────────────────────

  group('BattleState.copyWith', () {
    test('能正确构造下一个 tick 的状态', () {
      final left = _mkBattleChar(name: '左', teamSide: 0, slotIndex: 0);
      final right = _mkBattleChar(name: '右', teamSide: 1, slotIndex: 0);
      final s0 = BattleState.initial(leftTeam: [left], rightTeam: [right]);

      final action = BattleAction(
        tick: 0,
        actorId: left.characterId,
        targetId: right.characterId,
        description: '左队 0 号攻击右队 0 号',
      );
      final s1 = s0.copyWith(
        tick: 1,
        leftTeam: [left.copyWith(actionPoint: 100)],
        rightTeam: [right.copyWith(currentHp: right.currentHp - 500)],
        actionLog: [...s0.actionLog, action],
      );

      expect(s1.tick, 1);
      expect(s1.leftTeam.first.actionPoint, 100);
      expect(s1.rightTeam.first.currentHp, right.currentHp - 500);
      expect(s1.actionLog.length, 1);
      expect(s1.actionLog.first, same(action));
      // result 没传 → 维持原值（null，战斗中）
      expect(s1.result, null);
      expect(s1.isFinished, false);
    });

    test('result 用 sentinel：不传保留原值；显式传 null 也保留 null；传值则切换',
        () {
      final left = _mkBattleChar(name: '左', teamSide: 0, slotIndex: 0);
      final right = _mkBattleChar(name: '右', teamSide: 1, slotIndex: 0);
      final running = BattleState.initial(
        leftTeam: [left],
        rightTeam: [right],
      );
      // 1) 不传 result，应当保留 null
      final t1 = running.copyWith(tick: 1);
      expect(t1.result, null);

      // 2) 切换到 leftWin
      final won = t1.copyWith(result: BattleResult.leftWin);
      expect(won.result, BattleResult.leftWin);
      expect(won.isFinished, true);

      // 3) 显式传 null（理论上"撤销结局"，T12 不会用，但 sentinel 语义要保证可表达）
      final unset = won.copyWith(result: null);
      expect(unset.result, null);
      expect(unset.isFinished, false);
    });

    test('initial：tick=0 / result=null / actionLog=空 / 队伍不可变', () {
      final left = _mkBattleChar(name: '左', teamSide: 0, slotIndex: 0);
      final right = _mkBattleChar(name: '右', teamSide: 1, slotIndex: 0);
      final s = BattleState.initial(
        leftTeam: [left],
        rightTeam: [right],
      );
      expect(s.tick, 0);
      expect(s.result, null);
      expect(s.actionLog, isEmpty);
      expect(s.isFinished, false);
      // List.unmodifiable 保护
      expect(() => s.leftTeam.add(left), throwsUnsupportedError);
      expect(() => s.rightTeam.add(right), throwsUnsupportedError);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BattleAction
  // ────────────────────────────────────────────────────────────────────────

  group('BattleAction', () {
    test('全字段构造（含 attackResult 与 skill）', () {
      final skill = GameRepository.instance
          .getSkill('skill_gangmeng_jichu_basic');
      final attackResult =
          AttackResult.dodged(evasionRate: 0.0, breakdown: 'dodged');
      final a = BattleAction(
        tick: 5,
        actorId: 1,
        targetId: 2,
        skill: skill,
        attackResult: attackResult,
        description: '测试动作',
      );
      expect(a.tick, 5);
      expect(a.actorId, 1);
      expect(a.targetId, 2);
      expect(a.skill, same(skill));
      expect(a.attackResult, same(attackResult));
      expect(a.description, '测试动作');
    });

    test('nullable 字段可省略（targetId/skill/attackResult）', () {
      const a = BattleAction(
        tick: 0,
        actorId: 1,
        description: '战斗开始',
      );
      expect(a.targetId, null);
      expect(a.skill, null);
      expect(a.attackResult, null);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// fixture
// ─────────────────────────────────────────────────────────────────────────────

BattleCharacter _mkBattleChar({
  String name = '测试角色',
  int teamSide = 0,
  int slotIndex = 0,
}) {
  final c = _mkChar(
    tier: RealmTier.erLiu,
    layer: RealmLayer.yuanShu,
    internalForce: 3000,
    school: TechniqueSchool.gangMeng,
    name: name,
  );
  final eq = _mkEquip(baseAttack: 580, baseHealth: 200);
  final tech = _mkTech(
    defId: 'tech_gangmeng_mingjia',
    tier: TechniqueTier.mingJiaGong,
    school: TechniqueSchool.gangMeng,
  );
  return BattleCharacter.fromCharacter(
    character: c,
    equipped: [eq],
    mainTechnique: tech,
    numbers: GameRepository.instance.numbers,
    teamSide: teamSide,
    slotIndex: slotIndex,
  );
}

Character _mkChar({
  required RealmTier tier,
  required RealmLayer layer,
  required int internalForce,
  int constitution = 5,
  int enlightenment = 5,
  int agility = 5,
  int fortune = 5,
  TechniqueSchool? school,
  String name = '测试',
}) {
  final attrs = Attributes()
    ..constitution = constitution
    ..enlightenment = enlightenment
    ..agility = agility
    ..fortune = fortune;
  return Character.create(
    name: name,
    realmTier: tier,
    realmLayer: layer,
    attributes: attrs,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: internalForce,
    school: school,
  );
}

Equipment _mkEquip({
  int baseAttack = 0,
  int baseHealth = 0,
  int baseSpeed = 0,
}) {
  return Equipment.create(
    defId: 'test',
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    obtainedAt: DateTime(2026, 1, 1),
    obtainedFrom: 'test',
    baseAttack: baseAttack,
    baseHealth: baseHealth,
    baseSpeed: baseSpeed,
  );
}

Technique _mkTech({
  required String defId,
  required TechniqueTier tier,
  required TechniqueSchool school,
  CultivationLayer layer = CultivationLayer.chuKui,
  TechniqueRole role = TechniqueRole.main,
}) {
  return Technique.create(
    defId: defId,
    ownerCharacterId: 1,
    tier: tier,
    school: school,
    role: role,
    learnedAt: DateTime(2026, 1, 1),
    cultivationLayer: layer,
  );
}
