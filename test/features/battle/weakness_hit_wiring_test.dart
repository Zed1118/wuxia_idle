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

/// 第七阶段批二② Task 7-A：弱点/抗性结算接线（strategy → DamageCalculator）。
///
/// 覆盖语义：
/// 1. 攻方流派 = 守方弱点（mult>1.0）→ 命中 BattleAction.weaknessHit==true 且伤害高于基线；
/// 2. 攻方流派 = 守方抗性（mult<1.0）→ weaknessHit==false 且伤害低于基线；
/// 3. 中性（守方 schoolDamageTakenMult 无该流派条目）→ weaknessHit==false、基线伤害。
///
/// 用 BattleEngine.tick 走完整 strategy 路径（与 cycle_trait_fanzhen_test 同模式）。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  /// 玩家(刚猛)打敌人一回合，返回那条命中 BattleAction。
  /// [defMult] 传给敌人 schoolDamageTakenMult[gangMeng]；null = 无条目（中性）。
  BattleAction firstHit({double? defMult}) {
    final n = GameRepository.instance.numbers;
    final player = _mkBC(charId: 1, teamSide: 0).copyWith(actionPoint: 1000);
    var enemy = _mkBC(charId: 11, teamSide: 1).copyWith(evasionRate: 0.0);
    if (defMult != null) {
      enemy = enemy.copyWith(
        schoolDamageTakenMult: {TechniqueSchool.gangMeng: defMult},
      );
    }
    var s = BattleState.initial(leftTeam: [player], rightTeam: [enemy]);
    s = BattleEngine.tick(s, n, rng: Random(0));
    return s.actionLog.firstWhere(
      (a) => a.actorId == 1 && a.attackResult != null,
      orElse: () => throw StateError('未找到玩家命中动作'),
    );
  }

  test('中性(无 schoolDamageTakenMult 条目)→ weaknessHit==false', () {
    final a = firstHit(defMult: null);
    expect(a.weaknessHit, isFalse);
  });

  test('弱点(mult>1.0)→ weaknessHit==true 且伤害高于中性基线', () {
    final base = firstHit(defMult: null).attackResult!.finalDamage;
    final weak = firstHit(defMult: 1.5);
    expect(weak.weaknessHit, isTrue);
    expect(weak.attackResult!.finalDamage, greaterThan(base));
  });

  test('抗性(mult<1.0)→ weaknessHit==false 且伤害低于中性基线', () {
    final base = firstHit(defMult: null).attackResult!.finalDamage;
    final resisted = firstHit(defMult: 0.5);
    expect(resisted.weaknessHit, isFalse);
    expect(resisted.attackResult!.finalDamage, lessThan(base));
  });

  test('mult==1.0(显式中性)→ weaknessHit==false 且与基线相等', () {
    final base = firstHit(defMult: null).attackResult!.finalDamage;
    final neutral = firstHit(defMult: 1.0);
    expect(neutral.weaknessHit, isFalse);
    expect(neutral.attackResult!.finalDamage, base);
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// fixture（与 cycle_trait_fanzhen_test 同口径）
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
