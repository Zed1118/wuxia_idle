import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_log.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';

/// Task 5 验收：开锋破甲/吸血战报标记（战报展示层）。
///
/// 覆盖：
/// 1. EnumL10n.attackEffect('armor_pierce') → '破甲'。
/// 2. formatAction 含吸血标记「吸血 +N」（lifestealHeal > 0 时）。
/// 3. 无吸血时（lifestealHeal == 0）不含「吸血」字样。
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

  // ─────────────────────────────────────────────────────────────────────
  // EnumL10n.attackEffect 破甲映射
  // ─────────────────────────────────────────────────────────────────────

  test('EnumL10n.attackEffect armor_pierce → 破甲', () {
    expect(EnumL10n.attackEffect('armor_pierce'), '破甲');
  });

  test('EnumL10n.attackEffect 原有值无回归', () {
    expect(EnumL10n.attackEffect('extra_quake_dmg'), '附带震伤');
    expect(EnumL10n.attackEffect('crit_rate_+0.20'), '暴击率 +20%');
    expect(EnumL10n.attackEffect('internal_injury'), '施加内伤');
    expect(EnumL10n.attackEffect('unknown_xyz'), 'unknown_xyz');
  });

  // ─────────────────────────────────────────────────────────────────────
  // BattleLog.formatAction 吸血标记
  // ─────────────────────────────────────────────────────────────────────

  group('BattleLog.formatAction 吸血标记', () {
    test('lifestealHeal > 0 → 战报含「吸血 +N」且含具体回血量', () {
      final s = _twoCharState();
      final action = BattleAction(
        tick: 7,
        actorId: 1,
        targetId: 11,
        skill: GameRepository.instance.getSkill('skill_gangmeng_jichu_basic'),
        attackResult: _hitWithLifesteal(damage: 1200, lifestealHeal: 96),
        description: '',
      );
      final str = BattleLog.formatAction(action, s);
      expect(str, contains('吸血 +'), reason: '吸血标记前缀必须出现');
      expect(str, contains('96'), reason: '具体回血量 96 必须出现');
      expect(str, contains('1200'), reason: '主伤害也要在战报里');
    });

    test('lifestealHeal == 0 → 战报不含「吸血」字样', () {
      final s = _twoCharState();
      final action = BattleAction(
        tick: 3,
        actorId: 1,
        targetId: 11,
        skill: GameRepository.instance.getSkill('skill_gangmeng_jichu_basic'),
        attackResult: _hitNoLifesteal(damage: 800),
        description: '',
      );
      final str = BattleLog.formatAction(action, s);
      expect(str, isNot(contains('吸血')), reason: '无吸血时不应出现吸血字样');
    });

    test('lifestealHeal > 0 且 appliedEffects 含 armor_pierce → 二者都在战报里', () {
      final s = _twoCharState();
      final action = BattleAction(
        tick: 15,
        actorId: 1,
        targetId: 11,
        skill: GameRepository.instance.getSkill('skill_gangmeng_jichu_basic'),
        attackResult: _hitWithLifesteal(
          damage: 1500,
          lifestealHeal: 120,
          appliedEffects: const ['armor_pierce'],
        ),
        description: '',
      );
      final str = BattleLog.formatAction(action, s);
      expect(str, contains('吸血 +120'), reason: '吸血标记含量');
      expect(str, contains('破甲'), reason: '破甲效果显示名');
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// fixture helpers — 与 test/combat/battle_log_test.dart 同体例
// ─────────────────────────────────────────────────────────────────────────────

BattleState _twoCharState() {
  final left = _mkBC(charId: 1, teamSide: 0);
  final right = _mkBC(charId: 11, teamSide: 1);
  return BattleState.initial(leftTeam: [left], rightTeam: [right]);
}

/// 构造含吸血量的 AttackResult。
AttackResult _hitWithLifesteal({
  required int damage,
  required int lifestealHeal,
  List<String> appliedEffects = const [],
}) {
  return AttackResult(
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
    defenseRate: 0.0,
    evasionRate: 0.0,
    appliedEffects: appliedEffects,
    formulaBreakdown: 'test = $damage',
    lifestealHeal: lifestealHeal,
  );
}

/// 构造无吸血的 AttackResult。
AttackResult _hitNoLifesteal({required int damage}) {
  return AttackResult(
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
    defenseRate: 0.0,
    evasionRate: 0.0,
    appliedEffects: const [],
    formulaBreakdown: 'test = $damage',
  );
}

BattleCharacter _mkBC({
  required int charId,
  required int teamSide,
  int slotIndex = 0,
}) {
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
  )..id = charId;
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
    numbers: GameRepository.instance.numbers,
    teamSide: teamSide,
    slotIndex: slotIndex,
  );
}
